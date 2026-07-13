Set-StrictMode -Version 2.0

$contractModulePath = Join-Path $PSScriptRoot 'eMAS.Configuration.Contract.psm1'
Import-Module -Name $contractModulePath -Force -ErrorAction Stop
. (Join-Path $PSScriptRoot 'private/eMAS.RuntimeConfiguration.Helpers.ps1')
. (Join-Path $PSScriptRoot 'private/eMAS.RuntimeConfiguration.Validation.ps1')

function Resolve-eMASConfigurationPath {
    <#
    .SYNOPSIS
    Resolves a Runtime JSON path without requiring the target to exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path.Trim())
    if ([string]::IsNullOrWhiteSpace($expandedPath)) {
        throw 'CFG-FILE-001 Runtime configuration path is empty.'
    }

    try {
        if ([System.IO.Path]::IsPathRooted($expandedPath)) {
            return [System.IO.Path]::GetFullPath($expandedPath)
        }
        return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $expandedPath))
    }
    catch {
        throw ('CFG-FILE-002 Runtime configuration path is invalid: {0}' -f $_.Exception.Message)
    }
}

function Get-eMASConfigurationSection {
    <#
    .SYNOPSIS
    Returns a logical configuration section through the compatibility contract.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $raw = Get-eMASRawConfigurationObject -Configuration $Configuration
    if ($null -eq $raw) {
        return $null
    }

    $contract = Get-eMASConfigurationLoaderContract
    $candidates = Get-eMASContractSectionCandidates -Contract $contract -Name $Name
    $result = Get-eMASCandidateValue -InputObject $raw -Candidates $candidates
    if ($result.Found) {
        if (Test-eMASCollectionValue -Container (,$result.Value)) {
            Write-Output -NoEnumerate $result.Value
            return
        }
        return $result.Value
    }

    return $null
}

function Get-eMASConfigurationMetadata {
    <#
    .SYNOPSIS
    Returns the mapped configuration metadata section or null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration
    )

    return (Get-eMASConfigurationSection -Configuration $Configuration -Name 'Metadata')
}

function Get-eMASConfigurationValue {
    <#
    .SYNOPSIS
    Safely reads a dotted configuration path and returns a caller-defined default when absent.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [AllowNull()]
        [object] $DefaultValue = $null
    )

    $segments = @($Path -split '\.')
    if ($segments.Count -eq 0) {
        return $DefaultValue
    }

    $contract = Get-eMASConfigurationLoaderContract
    $current = Get-eMASRawConfigurationObject -Configuration $Configuration
    $metadata = $null

    for ($index = 0; $index -lt $segments.Count; $index++) {
        if ($null -eq $current) {
            return $DefaultValue
        }

        $segment = $segments[$index]
        if ($index -eq 0 -and ($segment -ieq 'metadata' -or $segment -ieq 'configuration' -or $segment -ieq 'configurationMetadata')) {
            $current = Get-eMASConfigurationMetadata -Configuration $Configuration
            $metadata = $current
            continue
        }

        if ($null -ne $metadata -and $current -eq $metadata) {
            $metadataCandidates = $null
            foreach ($logicalName in $contract.MetadataPropertyCandidates.Keys) {
                if ([string]$logicalName -ieq $segment) {
                    $metadataCandidates = @($contract.MetadataPropertyCandidates[$logicalName])
                    break
                }
            }
            if ($null -ne $metadataCandidates) {
                $metadataResult = Get-eMASCandidateValue -InputObject $current -Candidates $metadataCandidates
                if (-not $metadataResult.Found) {
                    return $DefaultValue
                }
                $current = $metadataResult.Value
                continue
            }
        }

        if (Test-eMASCollectionValue -Container (,$current)) {
            $array = @($current)
            $arrayIndex = 0
            if (-not [int]::TryParse($segment, [ref]$arrayIndex) -or $arrayIndex -lt 0 -or $arrayIndex -ge $array.Count) {
                return $DefaultValue
            }
            $current = $array[$arrayIndex]
            continue
        }

        $result = Get-eMASPropertyResult -InputObject $current -Name $segment
        if (-not $result.Found) {
            if ($index -eq 0) {
                $sectionCandidates = Get-eMASContractSectionCandidates -Contract $contract -Name $segment
                $result = Get-eMASCandidateValue -InputObject $current -Candidates $sectionCandidates
            }
            if (-not $result.Found) {
                return $DefaultValue
            }
        }
        $current = $result.Value
    }

    if ($null -eq $current) {
        return $DefaultValue
    }
    return $current
}

function Get-eMASRuleCollection {
    <#
    .SYNOPSIS
    Returns rules, optionally filtered by configured rule type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration,

        [AllowNull()]
        [string] $RuleType
    )

    $rules = Get-eMASConfigurationSection -Configuration $Configuration -Name 'Rules'
    if (-not (Test-eMASCollectionValue -Container (,$rules))) {
        return @()
    }

    $result = New-Object System.Collections.ArrayList
    foreach ($rule in $rules) {
        if ([string]::IsNullOrWhiteSpace($RuleType)) {
            [void]$result.Add($rule)
            continue
        }
        $type = Get-eMASCandidateValue -InputObject $rule -Candidates @('ruleType', 'type')
        if ($type.Found -and [string]$type.Value -ieq $RuleType) {
            [void]$result.Add($rule)
        }
    }
    return @($result)
}

function Get-eMASCodeList {
    <#
    .SYNOPSIS
    Returns a named configured code list or an empty collection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $codeLists = Get-eMASConfigurationSection -Configuration $Configuration -Name 'CodeLists'
    if ($null -eq $codeLists) {
        return @()
    }

    $result = Get-eMASPropertyResult -InputObject $codeLists -Name $Name
    if (-not $result.Found -or $null -eq $result.Value -or -not (Test-eMASCollectionValue -Container (,$result.Value))) {
        return @()
    }
    return @($result.Value)
}

function Test-eMASRuntimeConfiguration {
    <#
    .SYNOPSIS
    Runs structural validation and phase-neutral semantic validation hooks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Configuration
    )

    $contract = Get-eMASConfigurationLoaderContract
    return (Test-eMASRuntimeConfigurationInternal -Configuration $Configuration -Contract $contract)
}

function Import-eMASRuntimeConfiguration {
    <#
    .SYNOPSIS
    Loads one immutable Runtime JSON file into a stable validated wrapper.

    .DESCRIPTION
    Reads UTF-8 JSON only. The function never reads an XLSM, generates or repairs JSON,
    or modifies the source file. Use AllowInvalid only for diagnostics and tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('RuntimeConfigurationPath', 'RuntimeJsonPath', 'ConfigurationPath')]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [AllowNull()]
        [string] $ExecutionLogPath,

        [AllowNull()]
        [string] $ExecutionId,

        [AllowNull()]
        [string] $Phase,

        [AllowNull()]
        [string] $ActiveScript,

        [AllowNull()]
        [string] $TemplatePath,

        [switch] $AllowInvalid
    )

    $loadStartedAtUtc = [DateTime]::UtcNow
    $resolvedPath = $null
    Write-eMASRuntimeLogEvent -LogPath $ExecutionLogPath -Level 'Info' -Event 'RuntimeConfigurationLoadStarted' -Fields @{
        ActiveScript = $ActiveScript
        ExecutionId = $ExecutionId
        Phase = $Phase
        RuntimeConfigurationPath = $Path
        TemplatePath = $TemplatePath
    }

    try {
        $resolvedPath = Resolve-eMASConfigurationPath -Path $Path
        if (-not [System.IO.File]::Exists($resolvedPath)) {
            throw ('CFG-FILE-003 Runtime configuration file does not exist: {0}' -f $resolvedPath)
        }

        $fileInfo = New-Object System.IO.FileInfo($resolvedPath)
        if (($fileInfo.Attributes -band [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory) {
            throw ('CFG-FILE-004 Runtime configuration path is not a file: {0}' -f $resolvedPath)
        }

        try {
            $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
        }
        catch {
            throw ('CFG-FILE-005 Runtime configuration file is not readable: {0}' -f $_.Exception.Message)
        }

        if ($bytes.Length -eq 0) {
            throw 'CFG-FILE-006 Runtime configuration file is empty.'
        }
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw 'CFG-FILE-007 Runtime configuration must be UTF-8 without BOM.'
        }

        try {
            $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
            $jsonText = $utf8.GetString($bytes)
        }
        catch {
            throw ('CFG-FILE-008 Runtime configuration is not valid UTF-8: {0}' -f $_.Exception.Message)
        }
        if ([string]::IsNullOrWhiteSpace($jsonText)) {
            throw 'CFG-FILE-006 Runtime configuration file is empty.'
        }

        try {
            $parsedJson = $jsonText | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw ('CFG-FILE-009 Runtime configuration contains malformed JSON: {0}' -f $_.Exception.Message)
        }

        $contract = Get-eMASConfigurationLoaderContract
        $metadataResult = Get-eMASCandidateValue -InputObject $parsedJson -Candidates $contract.MetadataSectionCandidates
        if ($metadataResult.Found) {
            $metadata = $metadataResult.Value
        }
        else {
            $metadata = $null
        }

        $metadataValues = @{}
        foreach ($logicalName in $contract.MetadataPropertyCandidates.Keys) {
            $valueResult = Get-eMASCandidateValue -InputObject $metadata -Candidates @($contract.MetadataPropertyCandidates[$logicalName])
            if ($valueResult.Found) {
                $metadataValues[[string]$logicalName] = $valueResult.Value
            }
            else {
                $metadataValues[[string]$logicalName] = $null
            }
        }

        $wrapper = [pscustomobject]@{
            Path = $resolvedPath
            FileName = $fileInfo.Name
            FileHashSha256 = Get-eMASSha256FromBytes -Bytes $bytes
            FileSizeBytes = [int64]$bytes.Length
            LoadedAtUtc = [DateTime]::UtcNow
            LoadStartedAtUtc = $loadStartedAtUtc
            ConfigurationId = $metadataValues['ConfigurationId']
            ConfigurationName = $metadataValues['ConfigurationName']
            SchemaVersion = $metadataValues['SchemaVersion']
            ConfigurationVersion = $metadataValues['ConfigurationVersion']
            EffectiveDate = $metadataValues['EffectiveDate']
            Status = $metadataValues['Status']
            Raw = $parsedJson
            Validation = $null
            ExecutionLogPath = $ExecutionLogPath
        }
        $wrapper.PSObject.TypeNames.Insert(0, 'eMAS.RuntimeConfiguration')
        $wrapper.Validation = Test-eMASRuntimeConfiguration -Configuration $wrapper

        foreach ($finding in $wrapper.Validation.Findings) {
            Write-eMASRuntimeLogEvent -LogPath $ExecutionLogPath -Level $finding.Severity -Event 'RuntimeConfigurationValidationFinding' -Fields @{
                Code = $finding.Code
                IsBlocking = $finding.IsBlocking
                Message = $finding.Message
                Property = $finding.Property
                Section = $finding.Section
            }
        }

        Write-eMASRuntimeLogEvent -LogPath $ExecutionLogPath -Level 'Info' -Event 'RuntimeConfigurationLoadFinished' -Fields @{
            ActiveScript = $ActiveScript
            BlockingIssueCount = $wrapper.Validation.BlockingIssueCount
            ConfigurationId = $wrapper.ConfigurationId
            ConfigurationStatus = $wrapper.Status
            ConfigurationVersion = $wrapper.ConfigurationVersion
            EffectiveDate = $wrapper.EffectiveDate
            ErrorCount = $wrapper.Validation.ErrorCount
            ExecutionId = $ExecutionId
            FileHashSha256 = $wrapper.FileHashSha256
            FileName = $wrapper.FileName
            FileSizeBytes = $wrapper.FileSizeBytes
            InformationalCount = $wrapper.Validation.InformationalCount
            LoadFinishedAtUtc = $wrapper.LoadedAtUtc.ToString('o')
            LoadStartedAtUtc = $loadStartedAtUtc.ToString('o')
            Phase = $Phase
            RuntimeConfigurationPath = $wrapper.Path
            SchemaVersion = $wrapper.SchemaVersion
            TemplatePath = $TemplatePath
            ValidationStatus = $wrapper.Validation.OverallStatus
            WarningCount = $wrapper.Validation.WarningCount
        }

        if ($wrapper.Validation.BlockingIssueCount -gt 0 -and -not $AllowInvalid) {
            $blockingCodes = @($wrapper.Validation.Findings | Where-Object { $_.IsBlocking } | ForEach-Object { $_.Code } | Select-Object -Unique)
            throw ('CFG-VALIDATION-001 Runtime configuration validation failed with {0} blocking issue(s): {1}' -f $wrapper.Validation.BlockingIssueCount, ($blockingCodes -join ', '))
        }

        return $wrapper
    }
    catch {
        Write-eMASRuntimeLogEvent -LogPath $ExecutionLogPath -Level 'Error' -Event 'RuntimeConfigurationLoadFailed' -Fields @{
            ActiveScript = $ActiveScript
            Error = $_.Exception.Message
            ExecutionId = $ExecutionId
            Phase = $Phase
            RuntimeConfigurationPath = $resolvedPath
        }
        throw
    }
}

Export-ModuleMember -Function @(
    'Import-eMASRuntimeConfiguration',
    'Test-eMASRuntimeConfiguration',
    'Get-eMASConfigurationMetadata',
    'Get-eMASConfigurationSection',
    'Get-eMASConfigurationValue',
    'Get-eMASRuleCollection',
    'Get-eMASCodeList',
    'Resolve-eMASConfigurationPath'
)
