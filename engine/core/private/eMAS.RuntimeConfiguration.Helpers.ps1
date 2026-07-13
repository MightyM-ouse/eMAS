function Get-eMASPropertyResult {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ($null -eq $InputObject) {
        return [pscustomobject]@{ Found = $false; Name = $Name; Value = $null }
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            if ([string]$key -ieq $Name) {
                return [pscustomobject]@{ Found = $true; Name = [string]$key; Value = $InputObject[$key] }
            }
        }
    }
    else {
        foreach ($property in $InputObject.PSObject.Properties) {
            if ($property.Name -ieq $Name) {
                return [pscustomobject]@{ Found = $true; Name = $property.Name; Value = $property.Value }
            }
        }
    }

    return [pscustomobject]@{ Found = $false; Name = $Name; Value = $null }
}

function Get-eMASCandidateValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory = $true)]
        [string[]] $Candidates
    )

    foreach ($candidate in $Candidates) {
        $result = Get-eMASPropertyResult -InputObject $InputObject -Name $candidate
        if ($result.Found) {
            return $result
        }
    }

    return [pscustomobject]@{ Found = $false; Name = $Candidates[0]; Value = $null }
}

function Get-eMASObjectPropertyEntries {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject) {
        return
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            [pscustomobject]@{ Name = [string]$key; Value = $InputObject[$key] }
        }
        return
    }

    foreach ($property in $InputObject.PSObject.Properties) {
        if ($property.MemberType -eq 'NoteProperty' -or $property.MemberType -eq 'Property') {
            [pscustomobject]@{ Name = $property.Name; Value = $property.Value }
        }
    }
}

function Test-eMASCollectionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]] $Container
    )

    $Value = $Container[0]
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [System.Collections.IDictionary]) {
        return $false
    }

    return ($Value -is [System.Collections.IEnumerable])
}

function Test-eMASObjectValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]] $Container
    )

    $Value = $Container[0]
    if ($null -eq $Value -or $Value -is [string] -or $Value.GetType().IsPrimitive -or (Test-eMASCollectionValue -Container (,$Value))) {
        return $false
    }
    return $true
}

function Get-eMASRawConfigurationObject {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Configuration
    )

    if ($null -eq $Configuration) {
        return $null
    }

    if ($Configuration.PSObject.TypeNames -contains 'eMAS.RuntimeConfiguration') {
        return (Get-eMASPropertyResult -InputObject $Configuration -Name 'Raw').Value
    }

    return $Configuration
}

function Get-eMASContractSectionCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Contract,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    foreach ($key in $Contract.SectionCandidates.Keys) {
        if ([string]$key -ieq $Name) {
            return @($Contract.SectionCandidates[$key])
        }
    }

    return @($Name)
}

function Get-eMASPropertyOccurrences {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Node,

        [Parameter(Mandatory = $true)]
        [string[]] $PropertyNames,

        [string] $Path = '$',

        [int] $Depth = 0
    )

    if ($null -eq $Node -or $Depth -gt 64) {
        return
    }

    if (Test-eMASCollectionValue -Container (,$Node)) {
        $index = 0
        foreach ($item in $Node) {
            Get-eMASPropertyOccurrences -Node $item -PropertyNames $PropertyNames -Path ("{0}[{1}]" -f $Path, $index) -Depth ($Depth + 1)
            $index++
        }
        return
    }

    if ($Node -is [string] -or $Node.GetType().IsPrimitive -or $Node -is [decimal] -or $Node -is [datetime]) {
        return
    }

    foreach ($entry in Get-eMASObjectPropertyEntries -InputObject $Node) {
        $entryPath = '{0}.{1}' -f $Path, $entry.Name
        foreach ($propertyName in $PropertyNames) {
            if ($entry.Name -ieq $propertyName) {
                [pscustomobject]@{
                    Path = $entryPath
                    Property = $entry.Name
                    Value = $entry.Value
                }
                break
            }
        }
        Get-eMASPropertyOccurrences -Node $entry.Value -PropertyNames $PropertyNames -Path $entryPath -Depth ($Depth + 1)
    }
}

function Get-eMASAcceptedCodeTokens {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $CodeList
    )

    $tokens = @{}
    foreach ($row in @($CodeList)) {
        foreach ($candidate in @('code', 'value', 'displayValue', 'name')) {
            $result = Get-eMASPropertyResult -InputObject $row -Name $candidate
            if ($result.Found -and $null -ne $result.Value -and -not [string]::IsNullOrWhiteSpace([string]$result.Value)) {
                $tokens[[string]$result.Value] = $true
            }
        }
    }
    return $tokens
}

function Get-eMASSha256FromBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]] $Bytes
    )

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($Bytes)
        return (($hashBytes | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function ConvertTo-eMASLogValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return ([string]$Value).Replace("`r", ' ').Replace("`n", ' ').Replace("`t", ' ')
}

function Write-eMASRuntimeLogEvent {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $LogPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Event,

        [System.Collections.IDictionary] $Fields = @{}
    )

    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        return
    }

    $resolvedLogPath = [System.IO.Path]::GetFullPath($LogPath)
    $parent = [System.IO.Path]::GetDirectoryName($resolvedLogPath)
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not [System.IO.Directory]::Exists($parent)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add([DateTime]::UtcNow.ToString('o'))
    $parts.Add($Level)
    $parts.Add((ConvertTo-eMASLogValue -Value $Event))
    foreach ($key in ($Fields.Keys | Sort-Object)) {
        $parts.Add(('{0}={1}' -f $key, (ConvertTo-eMASLogValue -Value $Fields[$key])))
    }

    $line = ($parts -join "`t") + [Environment]::NewLine
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllText($resolvedLogPath, $line, $encoding)
}
