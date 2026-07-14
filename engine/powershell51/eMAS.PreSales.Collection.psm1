Set-StrictMode -Version 2.0

function Write-eMASLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level = 'INFO',
        [switch]$NoConsole
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8

    if (-not $NoConsole) {
        switch ($Level) {
            'WARN'  { Write-Host $Message -ForegroundColor Yellow }
            'ERROR' { Write-Host $Message -ForegroundColor Red }
            'DEBUG' { Write-Verbose $Message }
            default { Write-Host $Message }
        }
    }
}

function ConvertTo-eMASSizeObject {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][Int64]$Bytes)

    [pscustomobject][ordered]@{
        sizeBytes     = $Bytes
        displaySizeGB = [math]::Round(($Bytes / 1GB), 3)
        displaySizeTB = [math]::Round(($Bytes / 1TB), 3)
    }
}

function Get-eMASRuntimeConfigIdentity {
    [CmdletBinding()]
    param([string]$RuntimeConfigPath)

    if ([string]::IsNullOrWhiteSpace($RuntimeConfigPath)) {
        return [pscustomobject][ordered]@{
            loaded          = $false
            path            = $null
            mappingId       = $null
            mappingVersion  = $null
            schemaVersion   = $null
            sha256          = $null
            loadStatus      = 'NotProvided'
            loadMessage     = 'No runtime configuration was supplied. Collection continues with conservative technical defaults.'
        }
    }

    if (-not (Test-Path -LiteralPath $RuntimeConfigPath -PathType Leaf)) {
        throw "Runtime configuration file was not found: $RuntimeConfigPath"
    }

    try {
        $raw = Get-Content -LiteralPath $RuntimeConfigPath -Raw -Encoding UTF8
        $config = $raw | ConvertFrom-Json
        $hash = (Get-FileHash -LiteralPath $RuntimeConfigPath -Algorithm SHA256).Hash

        return [pscustomobject][ordered]@{
            loaded          = $true
            path            = (Resolve-Path -LiteralPath $RuntimeConfigPath).Path
            mappingId       = Get-eMASObjectPropertyValue -InputObject $config -Name 'mappingId' -DefaultValue $null
            mappingVersion  = Get-eMASObjectPropertyValue -InputObject $config -Name 'mappingVersion' -DefaultValue $null
            schemaVersion   = Get-eMASObjectPropertyValue -InputObject $config -Name 'runtimeJsonSchemaVersion' -DefaultValue $null
            sha256          = $hash
            loadStatus      = 'Loaded'
            loadMessage     = 'Runtime configuration loaded successfully.'
            configObject    = $config
        }
    }
    catch {
        throw "Runtime configuration could not be loaded as JSON. $($_.Exception.Message)"
    }
}

function Get-eMASConfigValue {
    [CmdletBinding()]
    param(
        [object]$RuntimeConfig,
        [Parameter(Mandatory = $true)][string]$Name,
        [object]$DefaultValue
    )

    if ($null -eq $RuntimeConfig) {
        return $DefaultValue
    }

    try {
        if ($null -ne $RuntimeConfig.config -and $null -ne $RuntimeConfig.config.$Name) {
            return $RuntimeConfig.config.$Name
        }
    }
    catch {
        return $DefaultValue
    }

    return $DefaultValue
}

function Get-eMASObjectPropertyValue {
    [CmdletBinding()]
    param(
        [object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name,
        [object]$DefaultValue
    )

    if ($null -eq $InputObject) { return $DefaultValue }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $DefaultValue }
    if ($null -eq $property.Value) { return $DefaultValue }
    return $property.Value
}

function Get-eMASModeRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ExternalExport','ECTDManagerExport','ECTDManagerDatabaseArchive','ECTDManagerHybrid','ArchiveOnly')]
        [string]$Mode
    )

    switch ($Mode) {
        'ExternalExport' {
            return [pscustomobject][ordered]@{
                mode                     = $Mode
                displayName              = 'External-system export assessment'
                requiresExport           = $true
                requiresArchive          = $false
                requiresIndex            = $false
                requiresDatabase         = $false
                defaultApplication       = $null
                detailedExportDiscovery  = $true
            }
        }
        'ECTDManagerExport' {
            return [pscustomobject][ordered]@{
                mode                     = $Mode
                displayName              = 'eCTDmanager export assessment'
                requiresExport           = $true
                requiresArchive          = $false
                requiresIndex            = $false
                requiresDatabase         = $false
                defaultApplication       = 'eCTDmanager'
                detailedExportDiscovery  = $true
            }
        }
        'ECTDManagerDatabaseArchive' {
            return [pscustomobject][ordered]@{
                mode                     = $Mode
                displayName              = 'eCTDmanager database and archive move'
                requiresExport           = $false
                requiresArchive          = $true
                requiresIndex            = $true
                requiresDatabase         = $true
                defaultApplication       = 'eCTDmanager'
                detailedExportDiscovery  = $false
            }
        }
        'ECTDManagerHybrid' {
            return [pscustomobject][ordered]@{
                mode                     = $Mode
                displayName              = 'eCTDmanager hybrid assessment'
                requiresExport           = $true
                requiresArchive          = $true
                requiresIndex            = $true
                requiresDatabase         = $true
                defaultApplication       = 'eCTDmanager'
                detailedExportDiscovery  = $true
            }
        }
        'ArchiveOnly' {
            return [pscustomobject][ordered]@{
                mode                     = $Mode
                displayName              = 'Archive and index move'
                requiresExport           = $false
                requiresArchive          = $true
                requiresIndex            = $true
                requiresDatabase         = $false
                defaultApplication       = $null
                detailedExportDiscovery  = $false
            }
        }
    }
}

function Get-eMASPathAggregate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$LogPath
    )

    $result = [ordered]@{
        sourceReference = $Path
        resolvedPath    = $null
        accessible      = 'No'
        sizeBytes       = $null
        displaySizeGB   = $null
        displaySizeTB   = $null
        errorCount      = 0
        errors          = @()
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        $result.errors = @("Path not found: $Path")
        $result.errorCount = 1
        return [pscustomobject]$result
    }

    try {
        $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $result.resolvedPath = $resolved
        $result.accessible = 'Yes'

        $item = Get-Item -LiteralPath $resolved -Force -ErrorAction Stop
        if (-not $item.PSIsContainer) {
            $size = ConvertTo-eMASSizeObject -Bytes ([Int64]$item.Length)
            $result.sizeBytes = $size.sizeBytes
            $result.displaySizeGB = $size.displaySizeGB
            $result.displaySizeTB = $size.displaySizeTB
            return [pscustomobject]$result
        }

        $enumerationErrors = @()
        $sum = Get-ChildItem -LiteralPath $resolved -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors |
            Measure-Object -Property Length -Sum

        $bytes = [Int64]0
        if ($null -ne $sum.Sum) {
            $bytes = [Int64]$sum.Sum
        }

        $size = ConvertTo-eMASSizeObject -Bytes $bytes
        $result.sizeBytes = $size.sizeBytes
        $result.displaySizeGB = $size.displaySizeGB
        $result.displaySizeTB = $size.displaySizeTB
        $result.errorCount = @($enumerationErrors).Count
        $result.errors = @($enumerationErrors | ForEach-Object { $_.Exception.Message } | Select-Object -Unique)

        if ($result.errorCount -gt 0) {
            Write-eMASLog -LogPath $LogPath -Level WARN -Message ("Aggregate size completed with {0} access warning(s): {1}" -f $result.errorCount, $resolved)
        }

        return [pscustomobject]$result
    }
    catch {
        $result.accessible = 'No'
        $result.errorCount = 1
        $result.errors = @($_.Exception.Message)
        return [pscustomobject]$result
    }
}

function New-eMASDirectCopyEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SourceType,
        [string[]]$Paths,
        [Nullable[Double]]$CustomerProvidedSizeGB,
        [Parameter(Mandatory = $true)][string]$LogPath
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $sequence = 1

    foreach ($path in @($Paths)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $aggregate = Get-eMASPathAggregate -Path $path -LogPath $LogPath
        $rows.Add([pscustomobject][ordered]@{
            evidenceId      = ('DC-{0}-{1:D3}' -f ($SourceType -replace '[^A-Za-z0-9]','').ToUpperInvariant(), $sequence)
            sourceType      = $SourceType
            sourceReference = $aggregate.sourceReference
            resolvedPath    = $aggregate.resolvedPath
            accessible      = $aggregate.accessible
            sizeBytes       = $aggregate.sizeBytes
            displaySizeGB   = $aggregate.displaySizeGB
            displaySizeTB   = $aggregate.displaySizeTB
            valueSource     = 'Observed'
            includedInScope = 'Yes'
            reviewRequired  = $(if ($aggregate.errorCount -gt 0 -or $aggregate.accessible -ne 'Yes') { 'Yes' } else { 'No' })
            evaluationStatus = $(if ($aggregate.accessible -eq 'Yes') { 'Evaluated' } else { 'Failed' })
            rag             = $(if ($aggregate.accessible -eq 'Yes' -and $aggregate.errorCount -eq 0) { 'Green' } elseif ($aggregate.accessible -eq 'Yes') { 'Amber' } else { 'Red' })
            comments        = $(if ($aggregate.errorCount -gt 0) { ($aggregate.errors -join ' | ') } else { '' })
        })
        $sequence++
    }

    if ($null -ne $CustomerProvidedSizeGB) {
        $gb = [double]$CustomerProvidedSizeGB
        $bytes = [Int64][math]::Round($gb * 1GB)
        $size = ConvertTo-eMASSizeObject -Bytes $bytes
        $rows.Add([pscustomobject][ordered]@{
            evidenceId      = ('DC-{0}-{1:D3}' -f ($SourceType -replace '[^A-Za-z0-9]','').ToUpperInvariant(), $sequence)
            sourceType      = $SourceType
            sourceReference = 'Customer-provided aggregate size'
            resolvedPath    = $null
            accessible      = 'NotAssessed'
            sizeBytes       = $size.sizeBytes
            displaySizeGB   = $size.displaySizeGB
            displaySizeTB   = $size.displaySizeTB
            valueSource     = 'CustomerProvided'
            includedInScope = 'Yes'
            reviewRequired  = 'Yes'
            evaluationStatus = 'Evaluated'
            rag             = 'Amber'
            comments        = 'Aggregate size was supplied manually and was not independently measured by the collection script.'
        })
    }

    return @($rows)
}

function Get-eMASConfiguredRegion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$EvidenceText,
        [object]$RuntimeConfig
    )

    $fallback = [pscustomobject][ordered]@{
        region                 = 'Unknown'
        authority              = 'Unknown'
        regionalImplementation = 'Unknown'
        confidence             = 'Low'
        ruleId                 = $null
        valueSource            = 'NotAssessed'
    }

    if ($null -eq $RuntimeConfig) { return $fallback }

    try {
        $rulesContainer = Get-eMASObjectPropertyValue -InputObject $RuntimeConfig -Name 'rules' -DefaultValue $null
        $regionRules = Get-eMASObjectPropertyValue -InputObject $rulesContainer -Name 'regions' -DefaultValue @()
        $rules = @($regionRules | Where-Object { (Get-eMASObjectPropertyValue -InputObject $_ -Name 'Active' -DefaultValue 'Yes') -ne 'No' } | Sort-Object { [int](Get-eMASObjectPropertyValue -InputObject $_ -Name 'Priority' -DefaultValue 9999) })

        foreach ($rule in $rules) {
            $tokens = @()
            $tokens += @(Get-eMASObjectPropertyValue -InputObject $rule -Name 'matchTokens' -DefaultValue @())
            $tokens += @(Get-eMASObjectPropertyValue -InputObject $rule -Name 'pathTokens' -DefaultValue @())
            $tokens += @(Get-eMASObjectPropertyValue -InputObject $rule -Name 'tokens' -DefaultValue @())

            foreach ($token in $tokens) {
                if ([string]::IsNullOrWhiteSpace([string]$token)) { continue }
                if ($EvidenceText.IndexOf([string]$token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    return [pscustomobject][ordered]@{
                        region                 = Get-eMASObjectPropertyValue -InputObject $rule -Name 'ResultRegion' -DefaultValue 'Unknown'
                        authority              = Get-eMASObjectPropertyValue -InputObject $rule -Name 'Authority' -DefaultValue 'Unknown'
                        regionalImplementation = Get-eMASObjectPropertyValue -InputObject $rule -Name 'RegionalImplementation' -DefaultValue 'Unknown'
                        confidence             = Get-eMASObjectPropertyValue -InputObject $rule -Name 'Confidence' -DefaultValue 'Medium'
                        ruleId                 = Get-eMASObjectPropertyValue -InputObject $rule -Name 'RuleId' -DefaultValue $null
                        valueSource            = 'Derived'
                    }
                }
            }
        }
    }
    catch {
        return $fallback
    }

    return $fallback
}

function Resolve-eMASTechnicalFormat {
    [CmdletBinding()]
    param(
        [hashtable]$FileNameSet,
        [hashtable]$FolderNameSet,
        [object]$RuntimeConfig
    )

    if ($FileNameSet.ContainsKey('submissionunit.xml')) {
        return [pscustomobject][ordered]@{
            format = 'eCTD 4.0'; technicalStandard = 'ICH eCTD 4.0'; confidence = 'High'; ruleId = 'TECH-BACKBONE-ECTD4'; valueSource = 'Observed'
        }
    }

    if ($FileNameSet.ContainsKey('index.xml')) {
        return [pscustomobject][ordered]@{
            format = 'eCTD 3.x'; technicalStandard = 'ICH eCTD 3.2.2'; confidence = 'High'; ruleId = 'TECH-BACKBONE-ECTD3'; valueSource = 'Observed'
        }
    }

    $moduleCount = 0
    foreach ($module in @('m1','m2','m3','m4','m5')) {
        if ($FolderNameSet.ContainsKey($module)) { $moduleCount++ }
    }

    if ($moduleCount -ge 2) {
        return [pscustomobject][ordered]@{
            format = 'NeeS'; technicalStandard = 'Non-eCTD electronic submission'; confidence = 'Medium'; ruleId = 'TECH-STRUCTURE-NEES'; valueSource = 'Derived'
        }
    }

    return [pscustomobject][ordered]@{
        format = 'Unknown'; technicalStandard = 'Unknown'; confidence = 'Low'; ruleId = $null; valueSource = 'NotAssessed'
    }
}

function Resolve-eMASDossierType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$EvidenceText,
        [object]$RuntimeConfig
    )

    $fallback = [pscustomobject][ordered]@{
        primaryDossierType = 'Unknown'
        productDomain      = 'Unknown'
        confidence         = 'Low'
        ruleId             = $null
        valueSource        = 'NotAssessed'
    }

    if ($null -eq $RuntimeConfig) { return $fallback }

    try {
        $rulesContainer = Get-eMASObjectPropertyValue -InputObject $RuntimeConfig -Name 'rules' -DefaultValue $null
        $typeRules = Get-eMASObjectPropertyValue -InputObject $rulesContainer -Name 'dossierTypes' -DefaultValue @()
        $rules = @($typeRules | Where-Object { (Get-eMASObjectPropertyValue -InputObject $_ -Name 'Active' -DefaultValue 'Yes') -ne 'No' } | Sort-Object { [int](Get-eMASObjectPropertyValue -InputObject $_ -Name 'Priority' -DefaultValue 9999) })

        foreach ($rule in $rules) {
            $tokens = @()
            $tokens += @(Get-eMASObjectPropertyValue -InputObject $rule -Name 'matchTokens' -DefaultValue @())
            $tokens += @(Get-eMASObjectPropertyValue -InputObject $rule -Name 'pathTokens' -DefaultValue @())
            foreach ($token in $tokens) {
                if ([string]::IsNullOrWhiteSpace([string]$token)) { continue }
                if ($EvidenceText.IndexOf([string]$token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    return [pscustomobject][ordered]@{
                        primaryDossierType = Get-eMASObjectPropertyValue -InputObject $rule -Name 'PrimaryDossierType' -DefaultValue 'Unknown'
                        productDomain      = Get-eMASObjectPropertyValue -InputObject $rule -Name 'ProductDomain' -DefaultValue 'Unknown'
                        confidence         = Get-eMASObjectPropertyValue -InputObject $rule -Name 'Confidence' -DefaultValue 'Medium'
                        ruleId             = Get-eMASObjectPropertyValue -InputObject $rule -Name 'RuleId' -DefaultValue $null
                        valueSource        = 'Derived'
                    }
                }
            }
        }
    }
    catch {
        return $fallback
    }

    return $fallback
}

function Get-eMASNearestAncestorPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$StartDirectory,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$Candidates,
        [Parameter(Mandatory = $true)][string]$StopPath
    )

    $current = $StartDirectory
    while (-not [string]::IsNullOrWhiteSpace($current)) {
        if ($Candidates.Contains($current)) { return $current }
        if ([string]::Equals($current.TrimEnd('\'), $StopPath.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)) { break }
        $parent = [System.IO.Directory]::GetParent($current)
        if ($null -eq $parent) { break }
        $current = $parent.FullName
    }
    return $null
}

function New-eMASSequenceAccumulator {
    param([string]$SequencePath)

    return [ordered]@{
        sequencePath = $SequencePath
        fileCount    = 0
        folderCount  = 0
        sizeBytes    = [Int64]0
        longestPath  = 0
        zeroByteFileCount = 0
        fileNames    = @{}
        folderNames  = @{}
    }
}

function New-eMASDossierAccumulator {
    param([string]$DossierPath)

    return [ordered]@{
        dossierPath = $DossierPath
        fileCount   = 0
        folderCount = 0
        sizeBytes   = [Int64]0
        sequencePaths = New-Object System.Collections.Generic.List[string]
    }
}

function Get-eMASExportInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string[]]$Roots,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [object]$RuntimeConfig
    )

    $exportEvidence = New-Object System.Collections.Generic.List[object]
    $dossierRows = New-Object System.Collections.Generic.List[object]
    $sequenceRows = New-Object System.Collections.Generic.List[object]

    $sequenceRegex = [string](Get-eMASConfigValue -RuntimeConfig $RuntimeConfig -Name 'SequenceFolderRegex' -DefaultValue '^\d{4}$')
    $maxPathLength = [int](Get-eMASConfigValue -RuntimeConfig $RuntimeConfig -Name 'MaxPathLength' -DefaultValue 240)
    $rootSequence = 1
    $dossierSequence = 1
    $sequenceSequence = 1

    foreach ($rootInput in @($Roots)) {
        if ([string]::IsNullOrWhiteSpace($rootInput)) { continue }
        Write-eMASLog -LogPath $LogPath -Message ("Scanning export root: {0}" -f $rootInput)

        if (-not (Test-Path -LiteralPath $rootInput -PathType Container)) {
            throw "Required export root is not accessible: $rootInput"
        }

        $root = (Resolve-Path -LiteralPath $rootInput -ErrorAction Stop).Path
        $enumerationErrors = @()
        $directories = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors)
        $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors)

        $sequenceDirectories = @($directories | Where-Object { $_.Name -match $sequenceRegex })
        $dossierPathSet = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
        $sequencePathSet = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
        $sequenceToDossier = @{}

        foreach ($sequenceDir in $sequenceDirectories) {
            [void]$sequencePathSet.Add($sequenceDir.FullName)
            $dossierPath = $sequenceDir.Parent.FullName
            [void]$dossierPathSet.Add($dossierPath)
            $sequenceToDossier[$sequenceDir.FullName] = $dossierPath
        }

        if ($sequenceDirectories.Count -eq 0) {
            foreach ($child in @($directories | Where-Object { $_.Parent.FullName -eq $root })) {
                [void]$dossierPathSet.Add($child.FullName)
            }
        }

        $sequenceStats = @{}
        foreach ($sequencePath in $sequencePathSet) {
            $sequenceStats[$sequencePath] = New-eMASSequenceAccumulator -SequencePath $sequencePath
        }

        $dossierStats = @{}
        foreach ($dossierPath in $dossierPathSet) {
            $dossierStats[$dossierPath] = New-eMASDossierAccumulator -DossierPath $dossierPath
        }
        foreach ($sequencePath in $sequencePathSet) {
            $dossierPath = $sequenceToDossier[$sequencePath]
            if ($dossierStats.ContainsKey($dossierPath)) {
                $dossierStats[$dossierPath].sequencePaths.Add($sequencePath)
            }
        }

        foreach ($directory in $directories) {
            $sequenceAncestor = Get-eMASNearestAncestorPath -StartDirectory $directory.FullName -Candidates $sequencePathSet -StopPath $root
            if ($null -ne $sequenceAncestor) {
                $sequenceStats[$sequenceAncestor].folderCount++
                $sequenceStats[$sequenceAncestor].folderNames[$directory.Name.ToLowerInvariant()] = $true
            }

            $dossierAncestor = Get-eMASNearestAncestorPath -StartDirectory $directory.FullName -Candidates $dossierPathSet -StopPath $root
            if ($null -ne $dossierAncestor) {
                $dossierStats[$dossierAncestor].folderCount++
            }
        }

        $totalBytes = [Int64]0
        $longPathCount = 0
        foreach ($file in $files) {
            $length = [Int64]$file.Length
            $totalBytes += $length
            if ($file.FullName.Length -gt $maxPathLength) { $longPathCount++ }

            $sequenceAncestor = Get-eMASNearestAncestorPath -StartDirectory $file.DirectoryName -Candidates $sequencePathSet -StopPath $root
            if ($null -ne $sequenceAncestor) {
                $stat = $sequenceStats[$sequenceAncestor]
                $stat.fileCount++
                $stat.sizeBytes += $length
                if ($file.FullName.Length -gt $stat.longestPath) { $stat.longestPath = $file.FullName.Length }
                if ($length -eq 0) { $stat.zeroByteFileCount++ }
                $stat.fileNames[$file.Name.ToLowerInvariant()] = $true
            }

            $dossierAncestor = Get-eMASNearestAncestorPath -StartDirectory $file.DirectoryName -Candidates $dossierPathSet -StopPath $root
            if ($null -ne $dossierAncestor) {
                $dossierStats[$dossierAncestor].fileCount++
                $dossierStats[$dossierAncestor].sizeBytes += $length
            }
        }

        $rootSize = ConvertTo-eMASSizeObject -Bytes $totalBytes
        $rootRag = 'Green'
        $rootReason = 'Export root was assessed successfully.'
        if ($enumerationErrors.Count -gt 0) {
            $rootRag = 'Amber'
            $rootReason = 'Export discovery completed with one or more access warnings.'
        }

        $exportEvidence.Add([pscustomobject][ordered]@{
            evidenceId       = ('EXP-{0:D3}' -f $rootSequence)
            exportRoot       = $root
            accessible       = 'Yes'
            sizeBytes        = $rootSize.sizeBytes
            displaySizeGB    = $rootSize.displaySizeGB
            displaySizeTB    = $rootSize.displaySizeTB
            fileCount        = $files.Count
            folderCount      = $directories.Count
            dossierCount     = $dossierPathSet.Count
            sequenceCount    = $sequencePathSet.Count
            longPathCount    = $longPathCount
            valueSource      = 'Observed'
            evaluationStatus = $(if ($enumerationErrors.Count -gt 0) { 'Warning' } else { 'Evaluated' })
            rag              = $rootRag
            primaryRAGReason = $rootReason
            reviewRequired   = $(if ($enumerationErrors.Count -gt 0) { 'Yes' } else { 'No' })
            comments         = $(if ($enumerationErrors.Count -gt 0) { (($enumerationErrors | ForEach-Object { $_.Exception.Message } | Select-Object -Unique) -join ' | ') } else { '' })
        })
        $rootSequence++

        $dossierIdByPath = @{}
        foreach ($dossierPath in @($dossierPathSet | Sort-Object)) {
            $dossierStat = $dossierStats[$dossierPath]
            $dossierName = Split-Path -Path $dossierPath -Leaf
            $parentPath = Split-Path -Path $dossierPath -Parent
            $product = ''
            if (-not [string]::Equals($parentPath.TrimEnd('\'), $root.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)) {
                $product = Split-Path -Path $parentPath -Leaf
            }

            $representativeFormat = [pscustomobject][ordered]@{ format = 'Unknown'; technicalStandard = 'Unknown'; confidence = 'Low'; ruleId = $null; valueSource = 'NotAssessed' }
            foreach ($sequencePath in @($dossierStat.sequencePaths)) {
                $seqFormat = Resolve-eMASTechnicalFormat -FileNameSet $sequenceStats[$sequencePath].fileNames -FolderNameSet $sequenceStats[$sequencePath].folderNames -RuntimeConfig $RuntimeConfig
                if ($representativeFormat.format -eq 'Unknown' -or $seqFormat.confidence -eq 'High') {
                    $representativeFormat = $seqFormat
                }
            }

            $region = Get-eMASConfiguredRegion -EvidenceText $dossierPath -RuntimeConfig $RuntimeConfig
            $type = Resolve-eMASDossierType -EvidenceText $dossierPath -RuntimeConfig $RuntimeConfig
            $reasons = New-Object System.Collections.Generic.List[string]
            if ($representativeFormat.format -eq 'Unknown') { $reasons.Add('Technical format could not be determined from available export evidence.') }
            if ($region.region -eq 'Unknown') { $reasons.Add('Regulatory region could not be determined from executable mapping rules.') }
            if ($dossierStat.sequencePaths.Count -eq 0) { $reasons.Add('No sequence folder matching the configured pattern was detected.') }
            if ($dossierStat.fileCount -eq 0) { $reasons.Add('No files were detected for the dossier.') }

            $rag = 'Green'
            if ($dossierStat.fileCount -eq 0) { $rag = 'Red' }
            elseif ($reasons.Count -gt 0) { $rag = 'Amber' }

            $dossierId = ('DOS-{0:D5}' -f $dossierSequence)
            $dossierIdByPath[$dossierPath] = $dossierId
            $dossierSize = ConvertTo-eMASSizeObject -Bytes $dossierStat.sizeBytes

            $dossierRows.Add([pscustomobject][ordered]@{
                dossierId                = $dossierId
                product                  = $product
                dossierDisplayName       = $dossierName
                dossierPath              = $dossierPath
                sourceApplication        = $null
                sourceApplicationVersion = $null
                region                   = $region.region
                regionEvidence           = $(if ($region.ruleId) { 'Configured token match' } else { 'No executable region mapping matched' })
                regionRuleIds            = $region.ruleId
                authority                = $region.authority
                technicalStandard        = $representativeFormat.technicalStandard
                format                   = $representativeFormat.format
                formatEvidence           = 'Observed folder and backbone-file indicators'
                formatRuleIds            = $representativeFormat.ruleId
                regionalImplementation   = $region.regionalImplementation
                primaryDossierType       = $type.primaryDossierType
                productDomain            = $type.productDomain
                typeEvidence             = $(if ($type.ruleId) { 'Configured token match' } else { 'No executable dossier-type mapping matched' })
                typeRuleIds               = $type.ruleId
                classificationConfidence = $(if ($representativeFormat.confidence -eq 'High' -and $region.confidence -eq 'High') { 'High' } elseif ($representativeFormat.confidence -eq 'Low' -or $region.confidence -eq 'Low') { 'Low' } else { 'Medium' })
                sequenceCount             = $dossierStat.sequencePaths.Count
                sizeBytes                 = $dossierSize.sizeBytes
                displaySizeGB             = $dossierSize.displaySizeGB
                fileCount                 = $dossierStat.fileCount
                folderCount               = $dossierStat.folderCount
                evaluationStatus          = $(if ($rag -eq 'Red') { 'Failed' } elseif ($rag -eq 'Amber') { 'Warning' } else { 'Evaluated' })
                valueSource               = 'Observed'
                dossierRAG                = $rag
                primaryRAGReason          = $(if ($reasons.Count -gt 0) { $reasons -join ' ' } else { 'Sufficient export evidence was collected for Pre-Sales classification.' })
                manualReviewRequired      = $(if ($rag -eq 'Green') { 'No' } else { 'Yes' })
                migrationWorkstream       = 'Pending EXTEDO Review'
                migrationMethod           = 'Migration Method Not Determined'
                batchEligible             = 'Unknown'
                individualImportRequired  = 'Unknown'
                conversionRequired        = $(if ($representativeFormat.format -in @('NeeS','VNeeS','Paper/Scanned')) { 'Yes' } elseif ($representativeFormat.format -eq 'Unknown') { 'Unknown' } else { 'No' })
                upgradeDependency         = 'Pending EXTEDO Review'
                effortImpact              = 'Pending EXTEDO Review'
                recommendedAction         = $(if ($rag -eq 'Green') { 'EXTEDO to complete target planning and migration-method review.' } else { 'Review unresolved classification evidence before final estimation.' })
                comments                  = ''
            })
            $dossierSequence++
        }

        foreach ($sequencePath in @($sequencePathSet | Sort-Object)) {
            $stat = $sequenceStats[$sequencePath]
            $dossierPath = $sequenceToDossier[$sequencePath]
            $dossierId = $dossierIdByPath[$dossierPath]
            $dossierName = Split-Path -Path $dossierPath -Leaf
            $parentPath = Split-Path -Path $dossierPath -Parent
            $product = ''
            if (-not [string]::Equals($parentPath.TrimEnd('\'), $root.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)) {
                $product = Split-Path -Path $parentPath -Leaf
            }

            $format = Resolve-eMASTechnicalFormat -FileNameSet $stat.fileNames -FolderNameSet $stat.folderNames -RuntimeConfig $RuntimeConfig
            $region = Get-eMASConfiguredRegion -EvidenceText $sequencePath -RuntimeConfig $RuntimeConfig
            $reasons = New-Object System.Collections.Generic.List[string]
            if ($format.format -eq 'Unknown') { $reasons.Add('Technical format could not be determined.') }
            if ($region.region -eq 'Unknown') { $reasons.Add('Regulatory region could not be determined from executable mapping rules.') }
            if ($stat.fileCount -eq 0) { $reasons.Add('Sequence contains no files.') }

            $rag = 'Green'
            if ($stat.fileCount -eq 0) { $rag = 'Red' }
            elseif ($reasons.Count -gt 0) { $rag = 'Amber' }

            $seqSize = ConvertTo-eMASSizeObject -Bytes $stat.sizeBytes
            $sequenceRows.Add([pscustomobject][ordered]@{
                sequenceId               = ('SEQ-{0:D7}' -f $sequenceSequence)
                product                  = $product
                dossierId                = $dossierId
                dossierDisplayName       = $dossierName
                sequenceDisplayName      = (Split-Path -Path $sequencePath -Leaf)
                sequencePath             = $sequencePath
                region                   = $region.region
                authority                = $region.authority
                technicalStandard        = $format.technicalStandard
                format                   = $format.format
                regionalImplementation   = $region.regionalImplementation
                classificationConfidence = $(if ($format.confidence -eq 'High' -and $region.confidence -eq 'High') { 'High' } elseif ($format.confidence -eq 'Low' -or $region.confidence -eq 'Low') { 'Low' } else { 'Medium' })
                sizeBytes                = $seqSize.sizeBytes
                displaySizeMB            = [math]::Round(($stat.sizeBytes / 1MB), 3)
                fileCount                = $stat.fileCount
                folderCount              = $stat.folderCount
                backboneXmlPresent       = $(if ($stat.fileNames.ContainsKey('index.xml') -or $stat.fileNames.ContainsKey('submissionunit.xml')) { 'Yes' } else { 'No' })
                checksumIndicatorPresent = $(if ($stat.fileNames.ContainsKey('index-md5.txt') -or $stat.fileNames.ContainsKey('sha256.txt')) { 'Yes' } else { 'No' })
                zeroByteFileCount        = $stat.zeroByteFileCount
                longestPathLength        = $stat.longestPath
                evaluationStatus         = $(if ($rag -eq 'Red') { 'Failed' } elseif ($rag -eq 'Amber') { 'Warning' } else { 'Evaluated' })
                valueSource              = 'Observed'
                sequenceRAG              = $rag
                primaryRAGReason         = $(if ($reasons.Count -gt 0) { $reasons -join ' ' } else { 'Sufficient export evidence was collected for Pre-Sales classification.' })
                reviewRequired           = $(if ($rag -eq 'Green') { 'No' } else { 'Yes' })
                migrationWorkstream      = 'Pending EXTEDO Review'
                migrationMethod          = 'Migration Method Not Determined'
                batchEligible            = 'Unknown'
                individualImportRequired = 'Unknown'
                conversionRequired       = $(if ($format.format -in @('NeeS','VNeeS','Paper/Scanned')) { 'Yes' } elseif ($format.format -eq 'Unknown') { 'Unknown' } else { 'No' })
                effortImpact             = 'Pending EXTEDO Review'
                recommendedAction        = $(if ($rag -eq 'Green') { 'EXTEDO to complete target planning and migration-method review.' } else { 'Review unresolved classification evidence before final estimation.' })
                comments                 = ''
            })
            $sequenceSequence++
        }
    }

    return [pscustomobject][ordered]@{
        exportEvidence    = @($exportEvidence)
        dossierInventory  = @($dossierRows)
        sequenceInventory = @($sequenceRows)
    }
}

function Get-eMASCollectionSummary {
    [CmdletBinding()]
    param(
        [object[]]$ExportEvidence,
        [object[]]$DirectCopyEvidence,
        [object[]]$DossierInventory,
        [object[]]$SequenceInventory
    )

    $exportBytes = [Int64]0
    foreach ($row in @($ExportEvidence)) {
        if ($null -ne $row.sizeBytes) { $exportBytes += [Int64]$row.sizeBytes }
    }

    $directCopyBytes = [Int64]0
    foreach ($row in @($DirectCopyEvidence)) {
        if ($null -ne $row.sizeBytes) { $directCopyBytes += [Int64]$row.sizeBytes }
    }

    $greenDossiers = @($DossierInventory | Where-Object { $_.dossierRAG -eq 'Green' }).Count
    $amberDossiers = @($DossierInventory | Where-Object { $_.dossierRAG -eq 'Amber' }).Count
    $redDossiers = @($DossierInventory | Where-Object { $_.dossierRAG -eq 'Red' }).Count
    $unknownDossiers = @($DossierInventory | Where-Object { $_.dossierRAG -eq 'Unknown' }).Count

    $greenSequences = @($SequenceInventory | Where-Object { $_.sequenceRAG -eq 'Green' }).Count
    $amberSequences = @($SequenceInventory | Where-Object { $_.sequenceRAG -eq 'Amber' }).Count
    $redSequences = @($SequenceInventory | Where-Object { $_.sequenceRAG -eq 'Red' }).Count
    $unknownSequences = @($SequenceInventory | Where-Object { $_.sequenceRAG -eq 'Unknown' }).Count

    [pscustomobject][ordered]@{
        totalExportRoots       = @($ExportEvidence).Count
        totalDirectCopySources = @($DirectCopyEvidence).Count
        totalDossiers          = @($DossierInventory).Count
        totalSequences         = @($SequenceInventory).Count
        exportSizeBytes        = $exportBytes
        exportSizeGB           = [math]::Round(($exportBytes / 1GB), 3)
        directCopySizeBytes    = $directCopyBytes
        directCopySizeGB       = [math]::Round(($directCopyBytes / 1GB), 3)
        greenDossiers          = $greenDossiers
        amberDossiers          = $amberDossiers
        redDossiers            = $redDossiers
        unknownDossiers        = $unknownDossiers
        greenSequences         = $greenSequences
        amberSequences         = $amberSequences
        redSequences           = $redSequences
        unknownSequences       = $unknownSequences
        targetPlanningStatus   = 'Pending EXTEDO Review'
        migrationScenario      = 'Pending EXTEDO Review'
        effortEstimateStatus   = 'Pending EXTEDO Review'
    }
}

function New-eMASPreSalesCollectionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ExecutionId,
        [Parameter(Mandatory = $true)][string]$AssessmentMode,
        [Parameter(Mandatory = $true)][string]$ModeDisplayName,
        [Parameter(Mandatory = $true)][object]$AssessmentContext,
        [Parameter(Mandatory = $true)][object]$CurrentSystem,
        [Parameter(Mandatory = $true)][object[]]$ExportEvidence,
        [Parameter(Mandatory = $true)][object[]]$DirectCopyEvidence,
        [Parameter(Mandatory = $true)][object[]]$DossierInventory,
        [Parameter(Mandatory = $true)][object[]]$SequenceInventory,
        [Parameter(Mandatory = $true)][object]$CollectionSummary,
        [Parameter(Mandatory = $true)][object]$RuntimeConfigIdentity,
        [Parameter(Mandatory = $true)][string]$LogFileName
    )

    $configIdentity = [ordered]@{
        loaded         = $RuntimeConfigIdentity.loaded
        path           = $RuntimeConfigIdentity.path
        mappingId      = $RuntimeConfigIdentity.mappingId
        mappingVersion = $RuntimeConfigIdentity.mappingVersion
        schemaVersion  = $RuntimeConfigIdentity.schemaVersion
        sha256         = $RuntimeConfigIdentity.sha256
        loadStatus     = $RuntimeConfigIdentity.loadStatus
        loadMessage    = $RuntimeConfigIdentity.loadMessage
    }

    [pscustomobject][ordered]@{
        phaseCode            = 'PRE_SALES'
        resultContractVersion = '0.1.0'
        executionProfile     = 'CustomerCollection'
        execution            = [ordered]@{
            executionId       = $ExecutionId
            generatedAtUtc    = (Get-Date).ToUniversalTime().ToString('o')
            computerName      = $env:COMPUTERNAME
            userName          = [Environment]::UserName
            powerShellVersion = $PSVersionTable.PSVersion.ToString()
            logFileName       = $LogFileName
            status            = 'Completed'
        }
        assessmentMode       = [ordered]@{
            code        = $AssessmentMode
            displayName = $ModeDisplayName
        }
        assessmentContext    = $AssessmentContext
        currentSystem        = $CurrentSystem
        targetPlanning       = [ordered]@{
            application     = $null
            version         = $null
            hotfix          = $null
            planningStatus  = 'Pending EXTEDO Review'
            completedBy     = $null
            completedAtUtc  = $null
        }
        exportEvidence       = @($ExportEvidence)
        directCopyEvidence   = @($DirectCopyEvidence)
        dossierInventory     = @($DossierInventory)
        sequenceInventory    = @($SequenceInventory)
        collectionSummary    = $CollectionSummary
        migrationScenarioDecision = [ordered]@{
            recommendedScenario = 'Pending EXTEDO Review'
            confidence          = 'Unknown'
            rationale           = 'Target-system information and approved migration rules are completed during EXTEDO review.'
            workstreams         = @()
        }
        effortEstimate       = [ordered]@{
            status               = 'Pending EXTEDO Review'
            minimumEffortDays    = $null
            mostLikelyEffortDays = $null
            maximumEffortDays    = $null
            confidence           = 'Unknown'
            primaryDrivers       = @()
        }
        extedoReviewRequired = $true
        runtimeConfiguration = $configIdentity
        reportGeneration     = [ordered]@{
            status  = 'PendingUpdatedTemplateMapping'
            message = 'The collection result is ready. Excel report population will be enabled after the updated v3.2 template mapping is approved.'
        }
    }
}

Export-ModuleMember -Function @(
    'Write-eMASLog',
    'Get-eMASRuntimeConfigIdentity',
    'Get-eMASModeRequirements',
    'Get-eMASPathAggregate',
    'New-eMASDirectCopyEvidence',
    'Get-eMASExportInventory',
    'Get-eMASCollectionSummary',
    'New-eMASPreSalesCollectionResult'
)
