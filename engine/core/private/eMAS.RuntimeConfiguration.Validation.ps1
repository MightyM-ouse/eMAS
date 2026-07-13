function New-eMASConfigurationFinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Code,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string] $Severity,

        [Parameter(Mandatory = $true)]
        [string] $Section,

        [AllowNull()]
        [string] $Property,

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [AllowNull()]
        [object] $Evidence,

        [Parameter(Mandatory = $true)]
        [bool] $IsBlocking
    )

    return [pscustomobject]@{
        Code = $Code
        Severity = $Severity
        Section = $Section
        Property = $Property
        Message = $Message
        Evidence = $Evidence
        IsBlocking = $IsBlocking
    }
}

function Add-eMASConfigurationFinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $Findings,

        [Parameter(Mandatory = $true)]
        [string] $Code,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string] $Severity,

        [Parameter(Mandatory = $true)]
        [string] $Section,

        [AllowNull()]
        [string] $Property,

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [AllowNull()]
        [object] $Evidence = $null,

        [bool] $IsBlocking = $false
    )

    $finding = New-eMASConfigurationFinding -Code $Code -Severity $Severity -Section $Section -Property $Property -Message $Message -Evidence $Evidence -IsBlocking $IsBlocking
    [void]$Findings.Add($finding)
}

function New-eMASConfigurationValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $Findings
    )

    $errorCount = @($Findings | Where-Object { $_.Severity -eq 'Error' }).Count
    $warningCount = @($Findings | Where-Object { $_.Severity -eq 'Warning' }).Count
    $informationCount = @($Findings | Where-Object { $_.Severity -eq 'Info' }).Count
    $blockingCount = @($Findings | Where-Object { $_.IsBlocking }).Count

    if ($blockingCount -gt 0) {
        $overallStatus = 'Invalid'
    }
    elseif ($warningCount -gt 0) {
        $overallStatus = 'ValidWithWarnings'
    }
    else {
        $overallStatus = 'Valid'
    }

    return [pscustomobject]@{
        OverallStatus = $overallStatus
        ErrorCount = $errorCount
        WarningCount = $warningCount
        InformationalCount = $informationCount
        BlockingIssueCount = $blockingCount
        Findings = @($Findings)
    }
}

function Get-eMASConfiguredCodeListByCandidates {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $RawConfiguration,

        [Parameter(Mandatory = $true)]
        [object] $Contract,

        [Parameter(Mandatory = $true)]
        [string[]] $Candidates
    )

    $sectionCandidates = Get-eMASContractSectionCandidates -Contract $Contract -Name 'CodeLists'
    $codeListSectionResult = Get-eMASCandidateValue -InputObject $RawConfiguration -Candidates $sectionCandidates
    if (-not $codeListSectionResult.Found -or $null -eq $codeListSectionResult.Value) {
        return [pscustomobject]@{ Found = $false; Name = $Candidates[0]; Values = @() }
    }

    $listResult = Get-eMASCandidateValue -InputObject $codeListSectionResult.Value -Candidates $Candidates
    if (-not $listResult.Found -or $null -eq $listResult.Value) {
        return [pscustomobject]@{ Found = $false; Name = $Candidates[0]; Values = @() }
    }

    return [pscustomobject]@{ Found = $true; Name = $listResult.Name; Values = @($listResult.Value) }
}

function Test-eMASValueAgainstCodeList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable] $AcceptedTokens
    )

    if ($null -eq $Value) {
        return $true
    }

    if (Test-eMASCollectionValue -Container (,$Value)) {
        foreach ($item in $Value) {
            if (-not (Test-eMASValueAgainstCodeList -Value $item -AcceptedTokens $AcceptedTokens)) {
                return $false
            }
        }
        return $true
    }

    return $AcceptedTokens.ContainsKey([string]$Value)
}

function Add-eMASTemporalValidationFindings {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Node,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $Findings,

        [string] $Path = '$',

        [int] $Depth = 0
    )

    if ($null -eq $Node -or $Depth -gt 64) {
        return
    }

    if (Test-eMASCollectionValue -Container (,$Node)) {
        $index = 0
        foreach ($item in $Node) {
            Add-eMASTemporalValidationFindings -Node $item -Findings $Findings -Path ("{0}[{1}]" -f $Path, $index) -Depth ($Depth + 1)
            $index++
        }
        return
    }

    if ($Node -is [string] -or $Node.GetType().IsPrimitive -or $Node -is [decimal] -or $Node -is [datetime]) {
        return
    }

    $start = Get-eMASCandidateValue -InputObject $Node -Candidates @('effectiveFrom', 'effectiveDate')
    $end = Get-eMASCandidateValue -InputObject $Node -Candidates @('effectiveTo', 'retiredAt', 'retirementDate')
    if ($start.Found -and $end.Found -and $null -ne $start.Value -and $null -ne $end.Value -and -not [string]::IsNullOrWhiteSpace([string]$end.Value)) {
        $startDate = [datetime]::MinValue
        $endDate = [datetime]::MinValue
        $startValid = [datetime]::TryParse([string]$start.Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$startDate)
        $endValid = [datetime]::TryParse([string]$end.Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$endDate)
        if (-not $startValid -or -not $endValid -or $endDate -le $startDate) {
            Add-eMASConfigurationFinding -Findings $Findings -Code 'CFG-SEM-007' -Severity 'Error' -Section $Path -Property $end.Name -Message 'The effective/retired date range is invalid.' -Evidence $null -IsBlocking $true
        }
    }

    foreach ($entry in Get-eMASObjectPropertyEntries -InputObject $Node) {
        Add-eMASTemporalValidationFindings -Node $entry.Value -Findings $Findings -Path ('{0}.{1}' -f $Path, $entry.Name) -Depth ($Depth + 1)
    }
}

function Test-eMASRuntimeConfigurationInternal {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Configuration,

        [Parameter(Mandatory = $true)]
        [object] $Contract
    )

    $findings = New-Object System.Collections.ArrayList
    $raw = Get-eMASRawConfigurationObject -Configuration $Configuration

    if ($null -eq $raw -or $raw -is [string] -or $raw.GetType().IsPrimitive -or (Test-eMASCollectionValue -Container (,$raw))) {
        Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-000' -Severity 'Error' -Section '$' -Property $null -Message 'The Runtime JSON root must be an object.' -Evidence $null -IsBlocking $true
        return (New-eMASConfigurationValidationResult -Findings $findings)
    }

    $metadataResult = Get-eMASCandidateValue -InputObject $raw -Candidates $Contract.MetadataSectionCandidates
    if (-not $metadataResult.Found -or $null -eq $metadataResult.Value) {
        Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-001' -Severity 'Error' -Section '$' -Property 'configuration' -Message 'A configuration metadata section is required.' -Evidence $null -IsBlocking $true
        $metadata = $null
    }
    else {
        $metadata = $metadataResult.Value
    }

    foreach ($metadataField in @('ConfigurationId', 'SchemaVersion', 'ConfigurationVersion', 'Status')) {
        $candidates = @($Contract.MetadataPropertyCandidates[$metadataField])
        $fieldResult = Get-eMASCandidateValue -InputObject $metadata -Candidates $candidates
        if (-not $fieldResult.Found -or $null -eq $fieldResult.Value -or [string]::IsNullOrWhiteSpace([string]$fieldResult.Value)) {
            Add-eMASConfigurationFinding -Findings $findings -Code ('CFG-STRUCT-META-{0}' -f $metadataField.ToUpperInvariant()) -Severity 'Error' -Section 'metadata' -Property $candidates[0] -Message ('Required metadata value {0} is missing.' -f $candidates[0]) -Evidence $null -IsBlocking $true
        }
    }

    $schemaVersionResult = Get-eMASCandidateValue -InputObject $metadata -Candidates @($Contract.MetadataPropertyCandidates['SchemaVersion'])
    if ($schemaVersionResult.Found -and -not [string]::IsNullOrWhiteSpace([string]$schemaVersionResult.Value)) {
        $schemaVersion = [string]$schemaVersionResult.Value
        if ($Contract.SupportedSchemaVersions -contains $schemaVersion) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-COMPAT-001' -Severity 'Info' -Section 'metadata' -Property $schemaVersionResult.Name -Message ('Schema version {0} is supported.' -f $schemaVersion) -Evidence $schemaVersion -IsBlocking $false
        }
        elseif ($Contract.SchemaVersionAdapters.ContainsKey($schemaVersion)) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-COMPAT-002' -Severity 'Warning' -Section 'metadata' -Property $schemaVersionResult.Name -Message ('Schema version {0} requires the explicitly configured compatibility adapter.' -f $schemaVersion) -Evidence $schemaVersion -IsBlocking $false
        }
        else {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-COMPAT-003' -Severity 'Error' -Section 'metadata' -Property $schemaVersionResult.Name -Message ('Schema version {0} is unsupported. Supported versions: {1}.' -f $schemaVersion, ($Contract.SupportedSchemaVersions -join ', ')) -Evidence $schemaVersion -IsBlocking $true
        }
    }

    foreach ($requiredSection in $Contract.RequiredTopLevelSections) {
        $sectionCandidates = @($requiredSection)
        foreach ($logicalName in $Contract.SectionCandidates.Keys) {
            if (@($Contract.SectionCandidates[$logicalName]) -contains $requiredSection) {
                $sectionCandidates = @($Contract.SectionCandidates[$logicalName])
                break
            }
        }
        $sectionResult = Get-eMASCandidateValue -InputObject $raw -Candidates $sectionCandidates
        if (-not $sectionResult.Found -or $null -eq $sectionResult.Value) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-SECTION' -Severity 'Error' -Section '$' -Property $requiredSection -Message ('Required top-level section {0} is missing.' -f $requiredSection) -Evidence $null -IsBlocking $true
        }
    }

    foreach ($objectSectionName in $Contract.ObjectSectionNames) {
        $sectionResult = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name $objectSectionName)
        if ($sectionResult.Found -and $null -ne $sectionResult.Value -and -not (Test-eMASObjectValue -Container (,$sectionResult.Value))) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-OBJECT' -Severity 'Error' -Section $sectionResult.Name -Property $null -Message ('Section {0} must be an object.' -f $sectionResult.Name) -Evidence $null -IsBlocking $true
        }
    }

    foreach ($collectionSectionName in $Contract.CollectionSectionNames) {
        $sectionResult = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name $collectionSectionName)
        if ($sectionResult.Found -and $null -ne $sectionResult.Value -and -not (Test-eMASCollectionValue -Container (,$sectionResult.Value))) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-COLLECTION' -Severity 'Error' -Section $sectionResult.Name -Property $null -Message ('Section {0} must be an array or enumerable collection.' -f $sectionResult.Name) -Evidence $null -IsBlocking $true
        }
    }

    foreach ($collectionContract in $Contract.CollectionContracts) {
        $sectionCandidates = Get-eMASContractSectionCandidates -Contract $Contract -Name $collectionContract.Name
        $sectionResult = Get-eMASCandidateValue -InputObject $raw -Candidates $sectionCandidates
        if (-not $sectionResult.Found -or $null -eq $sectionResult.Value) {
            continue
        }
        if (-not (Test-eMASCollectionValue -Container (,$sectionResult.Value))) {
            continue
        }

        $seenIds = @{}
        $index = 0
        foreach ($row in $sectionResult.Value) {
            $identity = Get-eMASCandidateValue -InputObject $row -Candidates @($collectionContract.IdCandidates)
            if (-not $identity.Found -or $null -eq $identity.Value -or [string]::IsNullOrWhiteSpace([string]$identity.Value)) {
                Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-STRUCT-ID' -Severity 'Error' -Section $sectionResult.Name -Property $collectionContract.IdCandidates[0] -Message ('Item {0} in {1} is missing its required identifier.' -f $index, $sectionResult.Name) -Evidence $index -IsBlocking $true
            }
            elseif ($seenIds.ContainsKey([string]$identity.Value)) {
                Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-DUPLICATE-ID' -Severity 'Error' -Section $sectionResult.Name -Property $identity.Name -Message ('Duplicate identifier {0} was found.' -f $identity.Value) -Evidence $identity.Value -IsBlocking $true
            }
            else {
                $seenIds[[string]$identity.Value] = $true
            }
            $index++
        }
    }

    foreach ($valueContract in $Contract.ControlledValueContracts) {
        $codeList = Get-eMASConfiguredCodeListByCandidates -RawConfiguration $raw -Contract $Contract -Candidates @($valueContract.CodeListCandidates)
        if (-not $codeList.Found) {
            if ($valueContract.RequiredCodeList) {
                Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-CODELIST-MISSING' -Severity 'Error' -Section 'CodeLists' -Property $valueContract.CodeListCandidates[0] -Message ('Required controlled code list {0} is missing.' -f $valueContract.CodeListCandidates[0]) -Evidence $null -IsBlocking $true
            }
            continue
        }

        $acceptedTokens = Get-eMASAcceptedCodeTokens -CodeList $codeList.Values
        $codeListSectionCandidates = Get-eMASContractSectionCandidates -Contract $Contract -Name 'CodeLists'
        foreach ($occurrence in Get-eMASPropertyOccurrences -Node $raw -PropertyNames @($valueContract.PropertyCandidates)) {
            $isCodeListDefinition = $false
            foreach ($codeListSectionCandidate in $codeListSectionCandidates) {
                $codeListPrefix = '$.{0}.' -f $codeListSectionCandidate
                if ($occurrence.Path.StartsWith($codeListPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $isCodeListDefinition = $true
                    break
                }
            }
            if ($isCodeListDefinition) {
                continue
            }
            if (-not (Test-eMASValueAgainstCodeList -Value $occurrence.Value -AcceptedTokens $acceptedTokens)) {
                Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-CONTROLLED-VALUE' -Severity 'Error' -Section $occurrence.Path -Property $occurrence.Property -Message ('Value is not present in controlled code list {0}.' -f $codeList.Name) -Evidence $occurrence.Value -IsBlocking $true
            }
        }
    }

    $ruleLifecycleList = Get-eMASConfiguredCodeListByCandidates -RawConfiguration $raw -Contract $Contract -Candidates @($Contract.LifecycleStatusCodeListCandidates)
    if ($ruleLifecycleList.Found) {
        $acceptedLifecycle = Get-eMASAcceptedCodeTokens -CodeList $ruleLifecycleList.Values
        $rulesResult = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name 'Rules')
        if ($rulesResult.Found -and (Test-eMASCollectionValue -Container (,$rulesResult.Value))) {
            foreach ($rule in $rulesResult.Value) {
                $status = Get-eMASCandidateValue -InputObject $rule -Candidates @($Contract.LifecycleStatusPropertyCandidates)
                if ($status.Found -and -not (Test-eMASValueAgainstCodeList -Value $status.Value -AcceptedTokens $acceptedLifecycle)) {
                    Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-LIFECYCLE' -Severity 'Error' -Section 'Rules' -Property $status.Name -Message 'Rule lifecycle status is not present in the configured lifecycle code list.' -Evidence $status.Value -IsBlocking $true
                }
            }
        }
    }

    foreach ($referenceContract in $Contract.ReferenceContracts) {
        $source = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name $referenceContract.Source)
        $target = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name $referenceContract.Target)
        if (-not $source.Found -or -not $target.Found -or -not (Test-eMASCollectionValue -Container (,$source.Value)) -or -not (Test-eMASCollectionValue -Container (,$target.Value))) {
            continue
        }

        $targetIds = @{}
        foreach ($targetRow in $target.Value) {
            $targetId = Get-eMASCandidateValue -InputObject $targetRow -Candidates @($referenceContract.TargetIdCandidates)
            if ($targetId.Found -and $null -ne $targetId.Value) {
                $targetIds[[string]$targetId.Value] = $true
            }
        }

        foreach ($sourceRow in $source.Value) {
            $reference = Get-eMASCandidateValue -InputObject $sourceRow -Candidates @($referenceContract.PropertyCandidates)
            if ($reference.Found -and $null -ne $reference.Value -and -not $targetIds.ContainsKey([string]$reference.Value)) {
                Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-REFERENCE' -Severity 'Error' -Section $source.Name -Property $reference.Name -Message ('Reference {0} does not resolve in {1}.' -f $reference.Value, $target.Name) -Evidence $reference.Value -IsBlocking $true
            }
        }
    }

    foreach ($occurrence in Get-eMASPropertyOccurrences -Node $raw -PropertyNames @($Contract.PriorityPropertyCandidates)) {
        $numericValue = 0.0
        $parsed = [double]::TryParse([string]$occurrence.Value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$numericValue)
        if (-not $parsed -or $numericValue -lt 0 -or [math]::Floor($numericValue) -ne $numericValue) {
            Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-PRIORITY' -Severity 'Error' -Section $occurrence.Path -Property $occurrence.Property -Message 'Priority and sequence values must be non-negative integers.' -Evidence $occurrence.Value -IsBlocking $true
        }
    }

    $policiesResult = Get-eMASCandidateValue -InputObject $raw -Candidates (Get-eMASContractSectionCandidates -Contract $Contract -Name 'Policies')
    if ($policiesResult.Found -and $null -ne $policiesResult.Value) {
        $thresholds = Get-eMASCandidateValue -InputObject $policiesResult.Value -Candidates @($Contract.ThresholdCollectionCandidates)
        if ($thresholds.Found -and (Test-eMASCollectionValue -Container (,$thresholds.Value))) {
            foreach ($threshold in $thresholds.Value) {
                $lower = Get-eMASCandidateValue -InputObject $threshold -Candidates @($Contract.ThresholdLowerBoundCandidates)
                $upper = Get-eMASCandidateValue -InputObject $threshold -Candidates @($Contract.ThresholdUpperBoundCandidates)
                if ($lower.Found -and $upper.Found -and $null -ne $lower.Value -and $null -ne $upper.Value) {
                    $lowerNumber = 0.0
                    $upperNumber = 0.0
                    $lowerValid = [double]::TryParse([string]$lower.Value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$lowerNumber)
                    $upperValid = [double]::TryParse([string]$upper.Value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$upperNumber)
                    if (-not $lowerValid -or -not $upperValid -or $lowerNumber -ge $upperNumber) {
                        Add-eMASConfigurationFinding -Findings $findings -Code 'CFG-SEM-THRESHOLD' -Severity 'Error' -Section 'Policies' -Property $upper.Name -Message 'Threshold lower bound must be less than upper bound.' -Evidence $null -IsBlocking $true
                    }
                }
            }
        }
    }

    Add-eMASTemporalValidationFindings -Node $raw -Findings $findings
    return (New-eMASConfigurationValidationResult -Findings $findings)
}
