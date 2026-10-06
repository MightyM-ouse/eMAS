Set-StrictMode -Version 2.0

function ConvertTo-eMASDiscoveryRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $normalized = ($Path -replace '\\', '/').Trim('/')
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ''
    }

    foreach ($segment in @($normalized -split '/')) {
        if ($segment -eq '.' -or $segment -eq '..' -or [string]::IsNullOrWhiteSpace($segment)) {
            throw ('DISC-PATH-001 Unsafe relative path was encountered: {0}' -f $Path)
        }
    }
    if ($normalized.StartsWith('/') -or $normalized -match '^[A-Za-z]:') {
        throw ('DISC-PATH-001 Unsafe relative path was encountered: {0}' -f $Path)
    }
    return $normalized
}

function Get-eMASDiscoveryParentPath {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath) -or -not $RelativePath.Contains('/')) {
        return ''
    }
    return $RelativePath.Substring(0, $RelativePath.LastIndexOf('/'))
}

function Get-eMASDiscoveryLeafName {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath) -or -not $RelativePath.Contains('/')) {
        return $RelativePath
    }
    return $RelativePath.Substring($RelativePath.LastIndexOf('/') + 1)
}

function Join-eMASDiscoveryRelativePath {
    param(
        [AllowEmptyString()][string] $Parent,
        [Parameter(Mandatory = $true)][string] $Child
    )

    if ([string]::IsNullOrEmpty($Parent)) {
        return $Child
    }
    return ('{0}/{1}' -f $Parent, $Child)
}

function Get-eMASDiscoveryPathDepth {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath)) {
        return 0
    }
    return @($RelativePath -split '/').Count
}

function Get-eMASOrdinalSortedStrings {
    param([AllowEmptyCollection()][string[]] $Values)

    $sorted = [string[]]@($Values)
    [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return $sorted
}

function Get-eMASFileSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Add-eMASDiscoveryInventoryEntry {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][hashtable] $Entries,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'File')][string] $EntryKind,
        [AllowNull()][Nullable[long]] $SizeBytes,
        [bool] $IsExplicit = $true,
        [AllowNull()][string] $ContainerPath
    )

    $normalized = ConvertTo-eMASDiscoveryRelativePath -Path $RelativePath
    if ([string]::IsNullOrEmpty($normalized)) {
        return
    }

    if ($Entries.ContainsKey($normalized)) {
        $existing = $Entries[$normalized]
        if ($existing.EntryKind -ne $EntryKind) {
            throw ('DISC-INVENTORY-001 Conflicting entry kinds were observed for relative path: {0}' -f $normalized)
        }
        if ($IsExplicit) {
            $existing.IsExplicit = $true
        }
        return
    }

    $Entries[$normalized] = [pscustomobject][ordered]@{
        RelativePath = $normalized
        EntryKind = $EntryKind
        SizeBytes = $SizeBytes
        IsExplicit = $IsExplicit
        IsArchive = ($EntryKind -eq 'File' -and ([System.IO.Path]::GetExtension($normalized) -ieq '.zip'))
        ContainerPath = $ContainerPath
    }
}

function Add-eMASDiscoveryParentDirectories {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][hashtable] $Entries,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [bool] $IncludeLeaf = $false,
        [AllowNull()][string] $ContainerPath
    )

    $normalized = ConvertTo-eMASDiscoveryRelativePath -Path $RelativePath
    $segments = @($normalized -split '/')
    $limit = $segments.Count - 1
    if ($IncludeLeaf) {
        $limit = $segments.Count
    }
    for ($index = 0; $index -lt $limit; $index++) {
        $directoryPath = ($segments[0..$index] -join '/')
        Add-eMASDiscoveryInventoryEntry -Entries $Entries -RelativePath $directoryPath -EntryKind 'Directory' -SizeBytes $null -IsExplicit:$false -ContainerPath $ContainerPath
    }
}

function Get-eMASDirectoryInventory {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList] $Diagnostics
    )

    $entries = @{}
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue([pscustomobject]@{ FullPath = $ResolvedSourcePath; RelativePath = '' })

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        try {
            $directoryPaths = [System.IO.Directory]::GetDirectories($current.FullPath)
            $filePaths = [System.IO.Directory]::GetFiles($current.FullPath)
        }
        catch [System.UnauthorizedAccessException] {
            [void]$Diagnostics.Add([pscustomobject][ordered]@{
                Code = 'DISC-ACCESS-001'
                RelativePath = $current.RelativePath
                CaptureStatus = 'AccessDenied'
            })
            continue
        }
        catch {
            [void]$Diagnostics.Add([pscustomobject][ordered]@{
                Code = 'DISC-ENUM-001'
                RelativePath = $current.RelativePath
                CaptureStatus = 'InputUnavailable'
            })
            continue
        }

        foreach ($directoryPath in @(Get-eMASOrdinalSortedStrings -Values $directoryPaths)) {
            $name = [System.IO.Path]::GetFileName($directoryPath)
            $relativePath = Join-eMASDiscoveryRelativePath -Parent $current.RelativePath -Child $name
            Add-eMASDiscoveryInventoryEntry -Entries $entries -RelativePath $relativePath -EntryKind 'Directory' -SizeBytes $null -IsExplicit:$true -ContainerPath $null
            $directoryInfo = New-Object System.IO.DirectoryInfo($directoryPath)
            if (($directoryInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                [void]$Diagnostics.Add([pscustomobject][ordered]@{
                    Code = 'DISC-REPARSE-001'
                    RelativePath = $relativePath
                    CaptureStatus = 'NotCollected'
                })
            }
            else {
                $queue.Enqueue([pscustomobject]@{ FullPath = $directoryPath; RelativePath = $relativePath })
            }
        }

        foreach ($filePath in @(Get-eMASOrdinalSortedStrings -Values $filePaths)) {
            $name = [System.IO.Path]::GetFileName($filePath)
            $relativePath = Join-eMASDiscoveryRelativePath -Parent $current.RelativePath -Child $name
            $fileInfo = New-Object System.IO.FileInfo($filePath)
            Add-eMASDiscoveryInventoryEntry -Entries $entries -RelativePath $relativePath -EntryKind 'File' -SizeBytes ([long]$fileInfo.Length) -IsExplicit:$true -ContainerPath $null
        }
    }

    return $entries
}

function Get-eMASZipInventory {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList] $Diagnostics
    )

    try { Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue } catch { }
    try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }

    $entries = @{}
    $stream = New-Object System.IO.FileStream($ResolvedSourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $archive = $null
    try {
        $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        foreach ($archiveEntry in $archive.Entries) {
            $rawPath = $archiveEntry.FullName
            $isDirectory = $rawPath.EndsWith('/') -or $rawPath.EndsWith('\')
            try {
                $relativePath = ConvertTo-eMASDiscoveryRelativePath -Path $rawPath
            }
            catch {
                [void]$Diagnostics.Add([pscustomobject][ordered]@{
                    Code = 'DISC-ZIP-PATH-001'
                    RelativePath = $null
                    CaptureStatus = 'InputUnavailable'
                })
                continue
            }

            if ([string]::IsNullOrEmpty($relativePath)) {
                continue
            }

            Add-eMASDiscoveryParentDirectories -Entries $entries -RelativePath $relativePath -IncludeLeaf:$isDirectory -ContainerPath $rawPath
            if ($isDirectory) {
                Add-eMASDiscoveryInventoryEntry -Entries $entries -RelativePath $relativePath -EntryKind 'Directory' -SizeBytes $null -IsExplicit:$true -ContainerPath $rawPath
            }
            else {
                Add-eMASDiscoveryInventoryEntry -Entries $entries -RelativePath $relativePath -EntryKind 'File' -SizeBytes ([long]$archiveEntry.Length) -IsExplicit:$true -ContainerPath $rawPath
            }
        }
    }
    catch {
        throw ('DISC-ZIP-001 ZIP source could not be opened read-only: {0}' -f $_.Exception.Message)
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
        $stream.Dispose()
    }
    return $entries
}

function Get-eMASInventoryObjects {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][hashtable] $Entries)

    $keys = Get-eMASOrdinalSortedStrings -Values @($Entries.Keys)
    $result = New-Object System.Collections.ArrayList
    foreach ($key in $keys) {
        [void]$result.Add($Entries[$key])
    }
    return @($result)
}

function Get-eMASDiscoveryChildrenMap {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Entries)

    $children = @{}
    foreach ($entry in $Entries) {
        $parentPath = Get-eMASDiscoveryParentPath -RelativePath $entry.RelativePath
        if (-not $children.ContainsKey($parentPath)) {
            $children[$parentPath] = New-Object System.Collections.ArrayList
        }
        [void]$children[$parentPath].Add($entry)
    }
    return $children
}

function Get-eMASOrdinalSortedObjectsByPath {
    param(
        [AllowEmptyCollection()][object[]] $Objects,
        [string] $PropertyName = 'RelativePath'
    )

    $indexed = @{}
    $keys = New-Object System.Collections.ArrayList
    $position = 0
    foreach ($item in @($Objects)) {
        $value = [string]$item.$PropertyName
        $key = '{0}{1}{2:D8}' -f $value, [char]0, $position
        $indexed[$key] = $item
        [void]$keys.Add($key)
        $position++
    }
    $sortedKeys = Get-eMASOrdinalSortedStrings -Values @($keys)
    $result = New-Object System.Collections.ArrayList
    foreach ($key in $sortedKeys) {
        [void]$result.Add($indexed[$key])
    }
    return @($result)
}

function Test-eMASPathIsDescendantOf {
    param(
        [AllowEmptyString()][string] $Path,
        [AllowEmptyString()][string] $Ancestor
    )

    if ([string]::IsNullOrEmpty($Ancestor)) {
        return -not [string]::IsNullOrEmpty($Path)
    }
    return $Path.StartsWith(($Ancestor + '/'), [System.StringComparison]::Ordinal)
}

function Get-eMASDescendantCount {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Entries,
        [Parameter(Mandatory = $true)][string] $ParentPath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'File')][string] $EntryKind
    )

    $count = 0
    foreach ($entry in $Entries) {
        if ($entry.EntryKind -eq $EntryKind -and (Test-eMASPathIsDescendantOf -Path $entry.RelativePath -Ancestor $ParentPath)) {
            $count++
        }
    }
    return $count
}

function Get-eMASRepositoryDiscoveryModel {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Entries,
        [AllowEmptyCollection()][object[]] $Diagnostics = @()
    )

    $childrenMap = Get-eMASDiscoveryChildrenMap -Entries $Entries
    $enumerationGapPaths = @{}
    foreach ($diagnostic in @($Diagnostics)) {
        if ($null -ne $diagnostic.RelativePath -and -not [string]::IsNullOrEmpty([string]$diagnostic.RelativePath) -and
            $diagnostic.Code -in @('DISC-ACCESS-001', 'DISC-ENUM-001')) {
            $enumerationGapPaths[[string]$diagnostic.RelativePath] = $true
        }
    }

    $rawCandidatePaths = New-Object System.Collections.ArrayList
    $classifiedUnitsByParent = @{}
    $classifiedUnitKindByPath = @{}
    foreach ($parentPath in @($childrenMap.Keys)) {
        $numericChildren = @($childrenMap[$parentPath] | Where-Object {
            $_.EntryKind -eq 'Directory' -and (Get-eMASDiscoveryLeafName -RelativePath $_.RelativePath) -match '^\d{1,6}$'
        })
        $classifiedChildren = @{}
        foreach ($numericChild in $numericChildren) {
            $numericPath = [string]$numericChild.RelativePath
            $numericName = Get-eMASDiscoveryLeafName -RelativePath $numericPath
            $unitKind = $null

            if ($enumerationGapPaths.ContainsKey($numericPath)) {
                if ($numericName -match '^\d{4}$') {
                    $unitKind = 'NumericSequenceDirectory'
                }
            }
            else {
                $unitChildren = @()
                if ($childrenMap.ContainsKey($numericPath)) {
                    $unitChildren = @($childrenMap[$numericPath])
                }
                $hasIndex = $false
                $hasSubmissionUnit = $false
                $hasSha256 = $false
                $hasModuleDirectory = $false
                foreach ($unitChild in $unitChildren) {
                    $unitChildName = Get-eMASDiscoveryLeafName -RelativePath $unitChild.RelativePath
                    if ($unitChild.EntryKind -eq 'File') {
                        if ($unitChildName -ieq 'index.xml') { $hasIndex = $true }
                        elseif ($unitChildName -ieq 'submissionunit.xml') { $hasSubmissionUnit = $true }
                        elseif ($unitChildName -ieq 'sha256.txt') { $hasSha256 = $true }
                    }
                    elseif ($unitChild.EntryKind -eq 'Directory' -and $unitChildName -imatch '^m[1-5]$') {
                        $hasModuleDirectory = $true
                    }
                }

                if ($hasIndex -and $hasSubmissionUnit) {
                    $unitKind = 'AmbiguousRegulatoryUnitFolder'
                }
                elseif ($hasSubmissionUnit) {
                    $unitKind = 'SubmissionUnitFolder'
                }
                elseif (-not $hasIndex -and $hasSha256 -and $hasModuleDirectory) {
                    $unitKind = 'DamagedSubmissionUnitCandidate'
                }
                elseif ($numericName -match '^\d{4}$' -and ($hasIndex -or $hasModuleDirectory)) {
                    $unitKind = 'NumericSequenceDirectory'
                }
            }

            if ($null -ne $unitKind) {
                $classifiedChildren[$numericPath] = $unitKind
                $classifiedUnitKindByPath[$numericPath] = $unitKind
            }
        }
        if ($classifiedChildren.Count -gt 0) {
            # B3 records every direct NNNN child once any child establishes the
            # physical container. Treat those retained children as classified
            # units as well so nested suppression follows facts, not name shape.
            foreach ($numericChild in $numericChildren) {
                $numericPath = [string]$numericChild.RelativePath
                $numericName = Get-eMASDiscoveryLeafName -RelativePath $numericPath
                if ($numericName -match '^\d{4}$' -and -not $classifiedChildren.ContainsKey($numericPath)) {
                    $classifiedChildren[$numericPath] = 'NumericSequenceDirectory'
                    $classifiedUnitKindByPath[$numericPath] = 'NumericSequenceDirectory'
                }
            }
            $classifiedUnitsByParent[[string]$parentPath] = $classifiedChildren
            [void]$rawCandidatePaths.Add([string]$parentPath)
        }
    }

    $acceptedCandidatePaths = New-Object System.Collections.ArrayList
    $maximumDepth = 0
    foreach ($path in @($rawCandidatePaths)) {
        $depth = Get-eMASDiscoveryPathDepth -RelativePath $path
        if ($depth -gt $maximumDepth) { $maximumDepth = $depth }
    }
    for ($depth = 0; $depth -le $maximumDepth; $depth++) {
        $pathsAtDepth = @($rawCandidatePaths | Where-Object { (Get-eMASDiscoveryPathDepth -RelativePath $_) -eq $depth })
        foreach ($candidatePath in @(Get-eMASOrdinalSortedStrings -Values $pathsAtDepth)) {
            $isNestedSequenceRoot = $false
            foreach ($acceptedPath in @($acceptedCandidatePaths)) {
                $candidateRemainder = $candidatePath
                if ([string]::IsNullOrEmpty($acceptedPath)) {
                    $firstSegment = @($candidateRemainder -split '/')[0]
                }
                elseif (Test-eMASPathIsDescendantOf -Path $candidatePath -Ancestor $acceptedPath) {
                    $candidateRemainder = $candidatePath.Substring($acceptedPath.Length + 1)
                    $firstSegment = @($candidateRemainder -split '/')[0]
                }
                else {
                    continue
                }
                $classifiedPath = $firstSegment
                if (-not [string]::IsNullOrEmpty($acceptedPath)) {
                    $classifiedPath = '{0}/{1}' -f $acceptedPath, $firstSegment
                }
                if ($classifiedUnitsByParent.ContainsKey([string]$acceptedPath) -and
                    $classifiedUnitsByParent[[string]$acceptedPath].ContainsKey([string]$classifiedPath)) {
                    $isNestedSequenceRoot = $true
                    break
                }
            }
            if (-not $isNestedSequenceRoot) {
                [void]$acceptedCandidatePaths.Add($candidatePath)
            }
        }
    }

    $sortedCandidatePaths = @(Get-eMASOrdinalSortedStrings -Values @($acceptedCandidatePaths))
    $candidateObjects = New-Object System.Collections.ArrayList
    $candidateByPath = @{}
    for ($candidateIndex = 0; $candidateIndex -lt $sortedCandidatePaths.Count; $candidateIndex++) {
        $candidatePath = $sortedCandidatePaths[$candidateIndex]
        $candidateId = 'DOS-{0:D4}' -f ($candidateIndex + 1)
        $directChildren = @()
        if ($childrenMap.ContainsKey($candidatePath)) {
            $directChildren = @(Get-eMASOrdinalSortedObjectsByPath -Objects @($childrenMap[$candidatePath]))
        }
        $directChildItems = @($directChildren | ForEach-Object {
            [pscustomobject][ordered]@{
                Name = Get-eMASDiscoveryLeafName -RelativePath $_.RelativePath
                RelativePath = $_.RelativePath
                EntryKind = $_.EntryKind
            }
        })
        $candidate = [pscustomobject][ordered]@{
            DossierId = $candidateId
            RelativePath = $candidatePath
            DiscoveryEvidenceIds = [object[]]@()
            CandidateStatus = 'Candidate'
            DirectChildItems = [object[]]$directChildItems
            CaptureStatus = 'Available'
        }
        $candidateByPath[$candidatePath] = $candidate
        [void]$candidateObjects.Add($candidate)
    }

    $sequenceDescriptors = New-Object System.Collections.ArrayList
    foreach ($candidatePath in $sortedCandidatePaths) {
        $candidate = $candidateByPath[$candidatePath]
        $directChildren = @()
        if ($childrenMap.ContainsKey($candidatePath)) {
            $directChildren = @(Get-eMASOrdinalSortedObjectsByPath -Objects @($childrenMap[$candidatePath]))
        }

        foreach ($entry in $directChildren) {
            $name = Get-eMASDiscoveryLeafName -RelativePath $entry.RelativePath
            $kind = $null
            $isExact = $false
            $sequenceNumber = $null
            $isSequenceLike = $false
            $entryKind = 'Directory'

            if ($entry.EntryKind -eq 'Directory' -and $classifiedUnitKindByPath.ContainsKey([string]$entry.RelativePath)) {
                $kind = [string]$classifiedUnitKindByPath[[string]$entry.RelativePath]
                $isExact = ($kind -eq 'NumericSequenceDirectory')
                if ($isExact -or $name -match '^[1-9]\d{0,5}$') {
                    $sequenceNumber = [int]$name
                }
                $isSequenceLike = $true
            }
            elseif ($entry.EntryKind -eq 'Directory' -and $name -match '^\d{4}$') {
                # Preserve the accepted B3 inventory rule: once a physical container is
                # promoted, every direct NNNN child is recorded as an exact sequence.
                $kind = 'NumericSequenceDirectory'
                $isExact = $true
                $sequenceNumber = [int]$name
                $isSequenceLike = $true
            }
            elseif ($entry.EntryKind -eq 'File' -and $name -match '^\d{4}\.zip$') {
                $kind = 'SequenceLikeArchive'
                $isSequenceLike = $true
                $entryKind = 'ZipEntry'
            }
            elseif ($entry.EntryKind -eq 'Directory' -and $name -match '^\d{4}\s+-\s+.+$') {
                if ($name -match '^\d{4}\s+-\s+copy(?:\b.*)?$') {
                    $kind = 'DuplicateCopyCandidate'
                }
                else {
                    $kind = 'InvalidSequenceLikeDirectory'
                }
                $isSequenceLike = $true
            }

            if ($null -ne $kind) {
                $fileCount = 0
                $directoryCount = 0
                if ($entry.EntryKind -eq 'Directory') {
                    $fileCount = Get-eMASDescendantCount -Entries $Entries -ParentPath $entry.RelativePath -EntryKind 'File'
                    $directoryCount = Get-eMASDescendantCount -Entries $Entries -ParentPath $entry.RelativePath -EntryKind 'Directory'
                }
                [void]$sequenceDescriptors.Add([pscustomobject][ordered]@{
                    DossierId = $candidate.DossierId
                    RelativePath = $entry.RelativePath
                    FolderName = $name
                    EntryKind = $entryKind
                    IsExactSequenceFolder = $isExact
                    SequenceNumber = $sequenceNumber
                    IsSequenceLike = $isSequenceLike
                    SequenceLikeKind = $kind
                    ParentSequenceId = $null
                    FileCount = $fileCount
                    DirectoryCount = $directoryCount
                    CaptureStatus = 'Available'
                })
            }
        }

        $rootExactDescriptors = @($sequenceDescriptors | Where-Object {
            $_.DossierId -eq $candidate.DossierId -and $_.IsExactSequenceFolder
        })
        foreach ($rootDescriptor in $rootExactDescriptors) {
            foreach ($entry in $Entries) {
                if ($entry.EntryKind -ne 'Directory' -or -not (Test-eMASPathIsDescendantOf -Path $entry.RelativePath -Ancestor $rootDescriptor.RelativePath)) {
                    continue
                }
                $name = Get-eMASDiscoveryLeafName -RelativePath $entry.RelativePath
                if ($name -match '^\d{4}$') {
                    [void]$sequenceDescriptors.Add([pscustomobject][ordered]@{
                        DossierId = $candidate.DossierId
                        RelativePath = $entry.RelativePath
                        FolderName = $name
                        EntryKind = 'Directory'
                        IsExactSequenceFolder = $false
                        SequenceNumber = $null
                        IsSequenceLike = $true
                        SequenceLikeKind = 'NestedSequenceLikeDirectory'
                        ParentSequencePath = $rootDescriptor.RelativePath
                        ParentSequenceId = $null
                        FileCount = Get-eMASDescendantCount -Entries $Entries -ParentPath $entry.RelativePath -EntryKind 'File'
                        DirectoryCount = Get-eMASDescendantCount -Entries $Entries -ParentPath $entry.RelativePath -EntryKind 'Directory'
                        CaptureStatus = 'Available'
                    })
                }
            }
        }
    }

    $sortedDescriptors = @(Get-eMASOrdinalSortedObjectsByPath -Objects @($sequenceDescriptors))
    $sequenceObjects = New-Object System.Collections.ArrayList
    $sequenceByPath = @{}
    for ($sequenceIndex = 0; $sequenceIndex -lt $sortedDescriptors.Count; $sequenceIndex++) {
        $descriptor = $sortedDescriptors[$sequenceIndex]
        $sequenceId = 'SEQ-{0:D4}' -f ($sequenceIndex + 1)
        $sequence = [pscustomobject][ordered]@{
            SequenceId = $sequenceId
            DossierId = $descriptor.DossierId
            RelativePath = $descriptor.RelativePath
            FolderName = $descriptor.FolderName
            EntryKind = $descriptor.EntryKind
            IsExactSequenceFolder = $descriptor.IsExactSequenceFolder
            SequenceNumber = $descriptor.SequenceNumber
            IsSequenceLike = $descriptor.IsSequenceLike
            SequenceLikeKind = $descriptor.SequenceLikeKind
            ParentSequenceId = $null
            FileCount = $descriptor.FileCount
            DirectoryCount = $descriptor.DirectoryCount
            CaptureStatus = $descriptor.CaptureStatus
        }
        $sequenceByPath[$sequence.RelativePath] = $sequence
        [void]$sequenceObjects.Add($sequence)
    }
    foreach ($descriptor in $sortedDescriptors) {
        if ($descriptor.PSObject.Properties.Name -contains 'ParentSequencePath' -and $null -ne $descriptor.ParentSequencePath) {
            $sequenceByPath[$descriptor.RelativePath].ParentSequenceId = $sequenceByPath[$descriptor.ParentSequencePath].SequenceId
        }
    }

    $wrapperPaths = New-Object System.Collections.ArrayList
    foreach ($candidatePath in $sortedCandidatePaths) {
        $parentPath = Get-eMASDiscoveryParentPath -RelativePath $candidatePath
        while (-not [string]::IsNullOrEmpty($parentPath)) {
            if (-not ($wrapperPaths -contains $parentPath)) {
                [void]$wrapperPaths.Add($parentPath)
            }
            $parentPath = Get-eMASDiscoveryParentPath -RelativePath $parentPath
        }
    }
    $sortedWrapperPaths = @(Get-eMASOrdinalSortedStrings -Values @($wrapperPaths))
    $wrapperObjects = New-Object System.Collections.ArrayList
    for ($wrapperIndex = 0; $wrapperIndex -lt $sortedWrapperPaths.Count; $wrapperIndex++) {
        $wrapperPath = $sortedWrapperPaths[$wrapperIndex]
        $relatedDossiers = @($candidateObjects | Where-Object {
            Test-eMASPathIsDescendantOf -Path $_.RelativePath -Ancestor $wrapperPath
        } | ForEach-Object { $_.DossierId })
        [void]$wrapperObjects.Add([pscustomobject][ordered]@{
            WrapperId = 'WRP-{0:D4}' -f ($wrapperIndex + 1)
            RelativePath = $wrapperPath
            CandidateDossierIds = [object[]]$relatedDossiers
            CaptureStatus = 'Available'
        })
    }

    $observationDescriptors = New-Object System.Collections.ArrayList
    foreach ($candidate in $candidateObjects) {
        $exactNames = @($sequenceObjects | Where-Object {
            $_.DossierId -eq $candidate.DossierId -and $_.IsExactSequenceFolder
        } | ForEach-Object { $_.FolderName })
        [void]$observationDescriptors.Add([pscustomobject][ordered]@{
            SortPath = $candidate.RelativePath
            Code = 'ExactSequenceChildrenObserved'
            Category = 'Inventory'
            SubjectType = 'Dossier'
            SubjectId = $candidate.DossierId
            ObservedValue = [object[]]$exactNames
        })

        $submissionUnitNames = @($sequenceObjects | Where-Object {
            $_.DossierId -eq $candidate.DossierId -and $_.SequenceLikeKind -eq 'SubmissionUnitFolder'
        } | ForEach-Object { $_.FolderName })
        if ($submissionUnitNames.Count -gt 0) {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $candidate.RelativePath
                Code = 'SubmissionUnitFoldersObserved'
                Category = 'Inventory'
                SubjectType = 'Dossier'
                SubjectId = $candidate.DossierId
                ObservedValue = [object[]]$submissionUnitNames
            })
        }

        $candidateWrappers = @($wrapperObjects | Where-Object { $_.CandidateDossierIds -contains $candidate.DossierId })
        if ($candidateWrappers.Count -gt 0) {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $candidate.RelativePath
                Code = 'WrapperDepth'
                Category = 'Structure'
                SubjectType = 'Dossier'
                SubjectId = $candidate.DossierId
                ObservedValue = [pscustomobject][ordered]@{
                    Depth = $candidateWrappers.Count
                    WrapperPaths = [object[]]@($candidateWrappers | ForEach-Object { $_.RelativePath })
                }
            })
        }
    }

    foreach ($sequence in $sequenceObjects) {
        $code = $null
        switch ($sequence.SequenceLikeKind) {
            'SequenceLikeArchive' { $code = 'SequenceLikeArchivePresent' }
            'InvalidSequenceLikeDirectory' { $code = 'InvalidSequenceLikeFolderName' }
            'DuplicateCopyCandidate' { $code = 'DuplicateOrCopyCandidate' }
            'NestedSequenceLikeDirectory' { $code = 'NestedSequenceLikePath' }
            'DamagedSubmissionUnitCandidate' { $code = 'DamagedSubmissionUnitMarkerSet' }
            'AmbiguousRegulatoryUnitFolder' { $code = 'ConflictingBackboneMarkers' }
        }
        if ($null -ne $code) {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $sequence.RelativePath
                Code = $code
                Category = 'Structure'
                SubjectType = 'Sequence'
                SubjectId = $sequence.SequenceId
                ObservedValue = $sequence.RelativePath
            })
        }
        if ($sequence.SequenceLikeKind -in @('SubmissionUnitFolder', 'DamagedSubmissionUnitCandidate', 'AmbiguousRegulatoryUnitFolder') -and
            $sequence.FolderName -notmatch '^[1-9]\d{0,5}$') {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $sequence.RelativePath
                Code = 'NonCanonicalSequenceNumberFolderName'
                Category = 'Structure'
                SubjectType = 'Sequence'
                SubjectId = $sequence.SequenceId
                ObservedValue = $sequence.RelativePath
            })
        }
        if ($sequence.IsExactSequenceFolder -and
            -not $enumerationGapPaths.ContainsKey([string]$sequence.RelativePath) -and
            $sequence.FileCount -eq 0 -and $sequence.DirectoryCount -eq 0) {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $sequence.RelativePath
                Code = 'EmptyExactSequenceFolder'
                Category = 'Structure'
                SubjectType = 'Sequence'
                SubjectId = $sequence.SequenceId
                ObservedValue = $true
            })
        }
    }

    foreach ($entry in @($Entries | Where-Object {
        $_.EntryKind -eq 'File' -and (Get-eMASDiscoveryLeafName -RelativePath $_.RelativePath) -ieq 'submissionunit.xml'
    })) {
        $markerParent = Get-eMASDiscoveryParentPath -RelativePath $entry.RelativePath
        $markerParentName = Get-eMASDiscoveryLeafName -RelativePath $markerParent
        if ([string]::IsNullOrEmpty($markerParent) -or $markerParentName -notmatch '^\d{1,6}$') {
            [void]$observationDescriptors.Add([pscustomobject][ordered]@{
                SortPath = $entry.RelativePath
                Code = 'UnplacedSubmissionUnitMarker'
                Category = 'Structure'
                SubjectType = 'Repository'
                SubjectId = 'REP-0001'
                ObservedValue = $entry.RelativePath
            })
        }
    }

    $observationKeys = New-Object System.Collections.ArrayList
    $observationByKey = @{}
    $descriptorIndex = 0
    foreach ($descriptor in $observationDescriptors) {
        $key = '{0}{1}{2}{1}{3:D8}' -f $descriptor.SortPath, [char]0, $descriptor.Code, $descriptorIndex
        $observationByKey[$key] = $descriptor
        [void]$observationKeys.Add($key)
        $descriptorIndex++
    }
    $sortedObservationKeys = @(Get-eMASOrdinalSortedStrings -Values @($observationKeys))
    $observationObjects = New-Object System.Collections.ArrayList
    for ($observationIndex = 0; $observationIndex -lt $sortedObservationKeys.Count; $observationIndex++) {
        $descriptor = $observationByKey[$sortedObservationKeys[$observationIndex]]
        $observation = [pscustomobject][ordered]@{
            ObservationId = 'OBS-{0:D4}' -f ($observationIndex + 1)
            Category = $descriptor.Category
            Code = $descriptor.Code
            SubjectType = $descriptor.SubjectType
            SubjectId = $descriptor.SubjectId
            ObservedValue = $descriptor.ObservedValue
            CaptureStatus = 'Available'
            EvidenceIds = [object[]]@()
        }
        [void]$observationObjects.Add($observation)
        if ($descriptor.Code -in @('ExactSequenceChildrenObserved', 'SubmissionUnitFoldersObserved')) {
            $candidate = @($candidateObjects | Where-Object { $_.DossierId -eq $descriptor.SubjectId })[0]
            $candidate.DiscoveryEvidenceIds = [object[]]@($candidate.DiscoveryEvidenceIds) + [object[]]@($observation.ObservationId)
        }
    }

    $fileEntries = @($Entries | Where-Object { $_.EntryKind -eq 'File' })
    $fileEntries = @(Get-eMASOrdinalSortedObjectsByPath -Objects $fileEntries)
    $fileObjects = New-Object System.Collections.ArrayList
    for ($fileIndex = 0; $fileIndex -lt $fileEntries.Count; $fileIndex++) {
        $entry = $fileEntries[$fileIndex]
        $dossierId = $null
        foreach ($candidate in $candidateObjects) {
            if ($entry.RelativePath -eq $candidate.RelativePath -or (Test-eMASPathIsDescendantOf -Path $entry.RelativePath -Ancestor $candidate.RelativePath)) {
                $dossierId = $candidate.DossierId
            }
        }
        $sequenceId = $null
        foreach ($sequence in $sequenceObjects) {
            if ($entry.RelativePath -eq $sequence.RelativePath -or (Test-eMASPathIsDescendantOf -Path $entry.RelativePath -Ancestor $sequence.RelativePath)) {
                $sequenceId = $sequence.SequenceId
            }
        }
        [void]$fileObjects.Add([pscustomobject][ordered]@{
            FileId = 'FIL-{0:D4}' -f ($fileIndex + 1)
            DossierId = $dossierId
            SequenceId = $sequenceId
            RelativePath = $entry.RelativePath
            ContainerPath = $entry.ContainerPath
            SizeBytes = $entry.SizeBytes
            ZeroByte = ($entry.SizeBytes -eq 0)
            Sha256 = $null
            Sha256CaptureStatus = 'NotCollected'
            IsArchive = $entry.IsArchive
            ArchiveInspectionStatus = $(if ($entry.IsArchive) { 'NotCollected' } else { 'NotApplicable' })
            IsReferenced = $null
            ReferencingIds = [object[]]@()
            ReferenceCaptureStatus = 'NotCollected'
            CaptureStatus = 'Available'
        })
    }

    return [pscustomobject][ordered]@{
        DossierCandidates = [object[]]@($candidateObjects)
        Sequences = [object[]]@($sequenceObjects)
        WrapperPaths = [object[]]@($wrapperObjects)
        Files = [object[]]@($fileObjects)
        Observations = [object[]]@($observationObjects)
    }
}

function Test-eMASDiscoveryOutputPath {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'DISC-OUTPUT-001 OutputPath must not overwrite SourcePath.'
    }
    if ($SourceKind -eq 'Directory') {
        $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'DISC-OUTPUT-002 OutputPath must not be inside SourcePath.'
        }
    }
    return $resolvedOutputPath
}

function Write-eMASRepositoryDiscoveryResult {
    param(
        [Parameter(Mandatory = $true)][object] $Result,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) {
        $parent = [System.IO.Directory]::GetCurrentDirectory()
    }
    if (-not [System.IO.Directory]::Exists($parent)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }
    $json = $Result | ConvertTo-Json -Depth 64
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, $json, $encoding)
}

function Invoke-eMASRepositoryDiscovery {
    <#
    .SYNOPSIS
    Performs read-only RepositoryDiscovery for an MS-04 Pre-Sales directory or top-level ZIP.

    .DESCRIPTION
    Inventories physical entries, discovers candidate dossier roots, and records numeric,
    sequence-like, nested, empty, wrapper, and unknown-structure observations. It does not
    parse XML, follow references, validate checksums, classify regulatory content, or score results.

    .PARAMETER SourcePath
    Existing directory or top-level ZIP to inspect read-only.

    .PARAMETER OutputPath
    Optional JSON destination outside SourcePath. UTF-8 without BOM is used.

    .PARAMETER ExecutionId
    Caller-supplied stable execution identity.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [AllowNull()][string] $OutputPath,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ExecutionId,
        [ValidateSet('MS-04')][string] $ScenarioId = 'MS-04',
        [ValidateSet('PreSales')][string] $Phase = 'PreSales',
        [AllowNull()][object] $ConfigurationIdentity
    )

    $startedAtUtc = [DateTime]::UtcNow
    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    if (-not [System.IO.File]::Exists($resolvedSourcePath) -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw ('DISC-SOURCE-001 SourcePath does not exist: {0}' -f $SourcePath)
    }

    if ([System.IO.Directory]::Exists($resolvedSourcePath)) {
        $sourceKind = 'Directory'
    }
    elseif ([System.IO.Path]::GetExtension($resolvedSourcePath) -ieq '.zip') {
        $sourceKind = 'Zip'
    }
    else {
        throw 'DISC-SOURCE-002 SourcePath must be a directory or a top-level ZIP file.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASDiscoveryOutputPath -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath
    }

    $diagnostics = New-Object System.Collections.ArrayList
    if ($sourceKind -eq 'Directory') {
        $entryTable = Get-eMASDirectoryInventory -ResolvedSourcePath $resolvedSourcePath -Diagnostics $diagnostics
        $sourceHash = $null
        $sourceSizeBytes = $null
    }
    else {
        $entryTable = Get-eMASZipInventory -ResolvedSourcePath $resolvedSourcePath -Diagnostics $diagnostics
        $sourceHash = Get-eMASFileSha256 -Path $resolvedSourcePath
        $sourceSizeBytes = (New-Object System.IO.FileInfo($resolvedSourcePath)).Length
    }

    $entries = @(Get-eMASInventoryObjects -Entries $entryTable)
    $discovery = Get-eMASRepositoryDiscoveryModel -Entries $entries -Diagnostics @($diagnostics)
    $portableEntries = @($entries | ForEach-Object {
        [pscustomobject][ordered]@{
            RelativePath = $_.RelativePath
            EntryKind = $_.EntryKind
            SizeBytes = $_.SizeBytes
            IsArchive = $_.IsArchive
            IsExplicit = $_.IsExplicit
            CaptureStatus = 'Available'
        }
    })

    $coverage = [object[]]@(
        [pscustomobject][ordered]@{ CheckId = 'RepositoryInventory'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = $entries.Count; ReasonCode = $null },
        [pscustomobject][ordered]@{ CheckId = 'DossierCandidateDiscovery'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = $discovery.DossierCandidates.Count; ReasonCode = $null },
        [pscustomobject][ordered]@{ CheckId = 'SequenceInventory'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = $discovery.Sequences.Count; ReasonCode = $null },
        [pscustomobject][ordered]@{ CheckId = 'CommonXmlParse'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' },
        [pscustomobject][ordered]@{ CheckId = 'RegionalXmlParse'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' },
        [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' },
        [pscustomobject][ordered]@{ CheckId = 'DeclaredChecksumComparison'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' },
        [pscustomobject][ordered]@{ CheckId = 'FileInventory'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = $discovery.Files.Count; ReasonCode = $null },
        [pscustomobject][ordered]@{ CheckId = 'LifecycleLinkResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' },
        [pscustomobject][ordered]@{ CheckId = 'StructuralObservationCollection'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = $discovery.Observations.Count; ReasonCode = $null },
        [pscustomobject][ordered]@{ CheckId = 'ClassificationEvidenceCollection'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideRepositoryDiscoveryScope' }
    )

    $completedAtUtc = [DateTime]::UtcNow
    $completionStatus = 'Completed'
    if ($diagnostics.Count -gt 0) {
        $completionStatus = 'CompletedWithCollectionGaps'
    }
    $sourceName = [System.IO.Path]::GetFileName($resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))
    $result = [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{
            ScenarioId = $ScenarioId
            Phase = $Phase
            ExecutionId = $ExecutionId
            ScannerName = 'eMAS.RepositoryDiscovery'
            ScannerVersion = '0.1.0'
            ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
            StartedAtUtc = $startedAtUtc.ToString('o')
            CompletedAtUtc = $completedAtUtc.ToString('o')
            CompletionStatus = $completionStatus
            Configuration = $ConfigurationIdentity
            Runtime = [pscustomobject][ordered]@{
                PSEdition = $PSVersionTable.PSEdition
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            }
        }
        Repository = [pscustomobject][ordered]@{
            RepositoryId = 'REP-0001'
            SourcePath = $sourceName
            ResolvedSourcePath = $null
            PathDisclosure = 'SourceNameOnly'
            SourceKind = $sourceKind
            SourceSha256 = $sourceHash
            SourceSizeBytes = $sourceSizeBytes
            SourceIdentity = [pscustomobject][ordered]@{
                Name = $sourceName
                Kind = $sourceKind
                Sha256 = $sourceHash
                SizeBytes = $sourceSizeBytes
            }
            ReadOnly = $true
            EntryCount = $entries.Count
            InventoryCaptureStatus = 'Available'
            Entries = [object[]]$portableEntries
            WrapperPaths = [object[]]$discovery.WrapperPaths
            Errors = [object[]]@($diagnostics)
        }
        DossierCandidates = [object[]]$discovery.DossierCandidates
        Sequences = [object[]]$discovery.Sequences
        XmlDocuments = [object[]]@()
        References = [object[]]@()
        Files = [object[]]$discovery.Files
        LifecycleRelationships = [object[]]@()
        Observations = [object[]]$discovery.Observations
        ClassificationEvidence = [object[]]@()
        CollectionCoverage = [object[]]$coverage
    }

    if ($null -ne $resolvedOutputPath) {
        Write-eMASRepositoryDiscoveryResult -Result $result -OutputPath $resolvedOutputPath
    }
    return $result
}

Export-ModuleMember -Function Invoke-eMASRepositoryDiscovery
