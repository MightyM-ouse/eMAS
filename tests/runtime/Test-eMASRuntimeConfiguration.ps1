[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixtureRoot = Join-Path $repositoryRoot 'tests/fixtures/runtime-config'
$modulePath = Join-Path $repositoryRoot 'engine/core/eMAS.RuntimeConfiguration.psm1'
Import-Module -Name $modulePath -Force -ErrorAction Stop

$script:TestCount = 0
$script:FailureCount = 0
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-runtime-tests-{0}' -f [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($temporaryRoot)

function Assert-eMASTrue {
    param(
        [bool] $Condition,
        [string] $Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-eMASEqual {
    param(
        [AllowNull()]
        [object] $Expected,
        [AllowNull()]
        [object] $Actual,
        [string] $Message
    )
    if ($Expected -ne $Actual) {
        throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual)
    }
}

function Assert-eMASThrowsLike {
    param(
        [scriptblock] $Action,
        [string] $Pattern
    )
    $didThrow = $false
    try {
        & $Action
    }
    catch {
        $didThrow = $true
        if ($_.Exception.Message -notlike $Pattern) {
            throw ('Expected error matching {0}, received: {1}' -f $Pattern, $_.Exception.Message)
        }
    }
    if (-not $didThrow) {
        throw ('Expected an error matching {0}, but no error was thrown.' -f $Pattern)
    }
}

function Assert-eMASFinding {
    param(
        [object] $Validation,
        [string] $Code
    )
    $matches = @($Validation.Findings | Where-Object { $_.Code -eq $Code })
    Assert-eMASTrue -Condition ($matches.Count -gt 0) -Message ('Expected validation finding {0}.' -f $Code)
}

function Invoke-eMASTest {
    param(
        [string] $Name,
        [scriptblock] $Action
    )
    $script:TestCount++
    try {
        & $Action
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        $script:FailureCount++
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

function Get-eMASTestSha256 {
    param([string] $Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($algorithm.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function Write-eMASTemporaryConfiguration {
    param(
        [object] $Configuration,
        [string] $Name
    )
    $path = Join-Path $temporaryRoot $Name
    $json = $Configuration | ConvertTo-Json -Depth 32
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $json, $encoding)
    return $path
}

$validPath = Join-Path $fixtureRoot 'valid-minimal.json'

Invoke-eMASTest -Name 'valid minimal JSON returns stable wrapper' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    Assert-eMASEqual -Expected 'Valid' -Actual $configuration.Validation.OverallStatus -Message 'Validation status differs.'
    Assert-eMASEqual -Expected 0 -Actual $configuration.Validation.BlockingIssueCount -Message 'Valid fixture has blocking findings.'
    Assert-eMASEqual -Expected 'CFG-SYNTHETIC-001' -Actual $configuration.ConfigurationId -Message 'Configuration ID differs.'
    Assert-eMASEqual -Expected '1.0.0' -Actual $configuration.SchemaVersion -Message 'Schema version differs.'
    Assert-eMASTrue -Condition ($configuration.PSObject.TypeNames -contains 'eMAS.RuntimeConfiguration') -Message 'Stable wrapper type name is missing.'
}

Invoke-eMASTest -Name 'malformed JSON is rejected' -Action {
    $path = Join-Path $fixtureRoot 'invalid-malformed.json'
    Assert-eMASThrowsLike -Action { Import-eMASRuntimeConfiguration -Path $path } -Pattern '*CFG-FILE-009*'
}

Invoke-eMASTest -Name 'empty JSON is rejected' -Action {
    $path = Join-Path $fixtureRoot 'invalid-empty.json'
    Assert-eMASThrowsLike -Action { Import-eMASRuntimeConfiguration -Path $path } -Pattern '*CFG-FILE-006*'
}

Invoke-eMASTest -Name 'missing file is rejected' -Action {
    $path = Join-Path $temporaryRoot 'does-not-exist.json'
    Assert-eMASThrowsLike -Action { Import-eMASRuntimeConfiguration -Path $path } -Pattern '*CFG-FILE-003*'
}

Invoke-eMASTest -Name 'missing metadata is blocking' -Action {
    $path = Join-Path $fixtureRoot 'invalid-missing-metadata.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-STRUCT-001'
    Assert-eMASTrue -Condition ($configuration.Validation.BlockingIssueCount -gt 0) -Message 'Missing metadata was not blocking.'
}

Invoke-eMASTest -Name 'missing schema version is blocking' -Action {
    $path = Join-Path $fixtureRoot 'invalid-missing-schema.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-STRUCT-META-SCHEMAVERSION'
}

Invoke-eMASTest -Name 'unsupported schema version is blocking' -Action {
    $path = Join-Path $fixtureRoot 'invalid-unsupported-schema.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-COMPAT-003'
    Assert-eMASThrowsLike -Action { Import-eMASRuntimeConfiguration -Path $path } -Pattern '*CFG-VALIDATION-001*'
}

Invoke-eMASTest -Name 'duplicate rule identifiers are rejected' -Action {
    $path = Join-Path $fixtureRoot 'invalid-duplicate-rule-id.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-SEM-DUPLICATE-ID'
}

Invoke-eMASTest -Name 'missing rule identifier is rejected' -Action {
    $raw = [System.IO.File]::ReadAllText($validPath) | ConvertFrom-Json
    $raw.rules = @([pscustomobject]@{ ruleType = 'SYNTHETIC_TEST'; priority = 0 })
    $path = Write-eMASTemporaryConfiguration -Configuration $raw -Name 'invalid-missing-rule-id.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-STRUCT-ID'
}

Invoke-eMASTest -Name 'malformed collection type is rejected' -Action {
    $raw = [System.IO.File]::ReadAllText($validPath) | ConvertFrom-Json
    $raw.rules = [pscustomobject]@{ ruleId = 'RULE-NOT-IN-ARRAY' }
    $path = Write-eMASTemporaryConfiguration -Configuration $raw -Name 'invalid-rule-collection-type.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-STRUCT-COLLECTION'
}

Invoke-eMASTest -Name 'missing recommendation reference is rejected' -Action {
    $path = Join-Path $fixtureRoot 'invalid-missing-recommendation-reference.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-SEM-REFERENCE'
}

Invoke-eMASTest -Name 'invalid RAG value is rejected from configured code list' -Action {
    $path = Join-Path $fixtureRoot 'invalid-rag-value.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-SEM-CONTROLLED-VALUE'
}

Invoke-eMASTest -Name 'invalid threshold boundary is rejected' -Action {
    $raw = [System.IO.File]::ReadAllText($validPath) | ConvertFrom-Json
    $raw.policies.effortThresholds = @([pscustomobject]@{ lowerBound = 10; upperBound = 5 })
    $path = Write-eMASTemporaryConfiguration -Configuration $raw -Name 'invalid-threshold-boundary.json'
    $configuration = Import-eMASRuntimeConfiguration -Path $path -AllowInvalid
    Assert-eMASFinding -Validation $configuration.Validation -Code 'CFG-SEM-THRESHOLD'
}

Invoke-eMASTest -Name 'configured code list is returned safely' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    $ragValues = @(Get-eMASCodeList -Configuration $configuration -Name 'RAG')
    Assert-eMASEqual -Expected 4 -Actual $ragValues.Count -Message 'RAG code-list count differs.'
}

Invoke-eMASTest -Name 'missing optional code list returns empty collection' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    $missing = @(Get-eMASCodeList -Configuration $configuration -Name 'OPTIONAL_NOT_PRESENT')
    Assert-eMASEqual -Expected 0 -Actual $missing.Count -Message 'Missing optional code list was not empty.'
}

Invoke-eMASTest -Name 'path containing spaces is resolved and loaded' -Action {
    $spaceDirectory = Join-Path $temporaryRoot 'path containing spaces'
    [void][System.IO.Directory]::CreateDirectory($spaceDirectory)
    $spacePath = Join-Path $spaceDirectory 'runtime configuration.json'
    [System.IO.File]::Copy($validPath, $spacePath)
    $configuration = Import-eMASRuntimeConfiguration -Path $spacePath
    Assert-eMASEqual -Expected ([System.IO.Path]::GetFullPath($spacePath)) -Actual $configuration.Path -Message 'Resolved path differs.'
}

Invoke-eMASTest -Name 'UTF-8 metadata is preserved' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    # Keep the test script ASCII-only so Windows PowerShell 5.1 does not interpret
    # a UTF-8-without-BOM source file through the active ANSI code page.
    $expectedName = 'Synthetic UTF-8 {0} Pr{1}fung' -f [char]0x2013, [char]0x00FC
    Assert-eMASEqual -Expected $expectedName -Actual $configuration.ConfigurationName -Message 'UTF-8 metadata differs.'
}

Invoke-eMASTest -Name 'SHA-256 identity is stable' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    Assert-eMASEqual -Expected (Get-eMASTestSha256 -Path $validPath) -Actual $configuration.FileHashSha256 -Message 'SHA-256 differs.'
}

Invoke-eMASTest -Name 'configuration accessors isolate raw schema traversal' -Action {
    $configuration = Import-eMASRuntimeConfiguration -Path $validPath
    $version = Get-eMASConfigurationValue -Configuration $configuration -Path 'metadata.configurationVersion' -DefaultValue $null
    $rules = @(Get-eMASRuleCollection -Configuration $configuration -RuleType 'SYNTHETIC_TEST')
    Assert-eMASEqual -Expected '1.0.0' -Actual $version -Message 'Mapped configuration version differs.'
    Assert-eMASEqual -Expected 1 -Actual $rules.Count -Message 'Rule collection filter differs.'
    Assert-eMASEqual -Expected 'RULE-SYNTHETIC-001' -Actual $rules[0].ruleId -Message 'Source rule identifier was not preserved.'
}

Invoke-eMASTest -Name 'source Runtime JSON remains read-only' -Action {
    $beforeHash = Get-eMASTestSha256 -Path $validPath
    $beforeWriteTime = (New-Object System.IO.FileInfo($validPath)).LastWriteTimeUtc
    $logPath = Join-Path $temporaryRoot 'read-only-test.log'
    $null = Import-eMASRuntimeConfiguration -Path $validPath -ExecutionLogPath $logPath -ExecutionId 'EXEC-READONLY' -Phase 'PRE_SALES' -ActiveScript 'SyntheticTest.ps1'
    $afterHash = Get-eMASTestSha256 -Path $validPath
    $afterWriteTime = (New-Object System.IO.FileInfo($validPath)).LastWriteTimeUtc
    Assert-eMASEqual -Expected $beforeHash -Actual $afterHash -Message 'Source hash changed.'
    Assert-eMASEqual -Expected $beforeWriteTime -Actual $afterWriteTime -Message 'Source timestamp changed.'
    $log = [System.IO.File]::ReadAllText($logPath)
    Assert-eMASTrue -Condition ($log -like '*FileHashSha256=*') -Message 'Execution log omitted JSON hash.'
    Assert-eMASTrue -Condition ($log -like '*ValidationStatus=Valid*') -Message 'Execution log omitted validation result.'
}

Invoke-eMASTest -Name 'all phase entry scripts accept one valid Runtime JSON path' -Action {
    $expectedPhases = [ordered]@{
        'eMAS-PreSalesAssessment.ps1' = 'PRE_SALES'
        'eMAS-PreMigrationReadiness.ps1' = 'PRE_MIGRATION'
        'eMAS-PostMigrationVerification.ps1' = 'POST_MIGRATION'
    }
    foreach ($scriptName in $expectedPhases.Keys) {
        $scriptPath = Join-Path (Join-Path $repositoryRoot 'scripts') $scriptName
        $logPath = Join-Path $temporaryRoot ('valid-' + $scriptName + '.log')
        $result = & $scriptPath -RuntimeConfigurationPath $validPath -ExecutionLogPath $logPath
        Assert-eMASEqual -Expected $expectedPhases[$scriptName] -Actual $result.Phase -Message ('Phase differs for {0}.' -f $scriptName)
        Assert-eMASEqual -Expected 'ConfigurationValidated' -Actual $result.InitializationStatus -Message ('Initialization status differs for {0}.' -f $scriptName)
        Assert-eMASTrue -Condition (-not $result.AssessmentProcessingStarted) -Message ('Assessment processing unexpectedly started for {0}.' -f $scriptName)
        Assert-eMASTrue -Condition ([System.IO.File]::Exists($logPath)) -Message ('Execution log was not created for {0}.' -f $scriptName)
    }
}

Invoke-eMASTest -Name 'all phase entry scripts stop on blocking configuration errors' -Action {
    $invalidPath = Join-Path $fixtureRoot 'invalid-unsupported-schema.json'
    foreach ($scriptName in @('eMAS-PreSalesAssessment.ps1', 'eMAS-PreMigrationReadiness.ps1', 'eMAS-PostMigrationVerification.ps1')) {
        $scriptPath = Join-Path (Join-Path $repositoryRoot 'scripts') $scriptName
        $logPath = Join-Path $temporaryRoot ($scriptName + '.log')
        Assert-eMASThrowsLike -Action { & $scriptPath -RuntimeConfigurationPath $invalidPath -ExecutionLogPath $logPath } -Pattern '*CFG-VALIDATION-001*'
        Assert-eMASTrue -Condition ([System.IO.File]::Exists($logPath)) -Message ('Phase log was not created for {0}.' -f $scriptName)
        $log = [System.IO.File]::ReadAllText($logPath)
        Assert-eMASTrue -Condition ($log -notlike '*AssessmentProcessingStarted=True*') -Message ('Assessment processing started for invalid configuration in {0}.' -f $scriptName)
    }
}

Write-Output ('Runtime configuration tests completed: {0} total, {1} failed.' -f $script:TestCount, $script:FailureCount)
if ($script:FailureCount -gt 0) {
    exit 1
}
exit 0
