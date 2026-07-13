function Initialize-eMASPhaseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PRE_SALES', 'PRE_MIGRATION', 'POST_MIGRATION')]
        [string] $Phase,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RuntimeConfigurationPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ActiveScript,

        [AllowNull()]
        [string] $ExecutionLogPath,

        [AllowNull()]
        [string] $TemplatePath
    )

    $repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $runtimeConfigurationModule = Join-Path $repositoryRoot 'engine/core/eMAS.RuntimeConfiguration.psm1'
    Import-Module -Name $runtimeConfigurationModule -Force -ErrorAction Stop

    $executionId = 'EXEC-{0}' -f ([guid]::NewGuid().ToString('N').ToUpperInvariant())
    if ([string]::IsNullOrWhiteSpace($ExecutionLogPath)) {
        $logName = 'eMAS_{0}_{1}_{2}.log' -f $Phase, [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), $executionId
        $ExecutionLogPath = Join-Path (Join-Path $repositoryRoot 'logs') $logName
    }

    $configuration = Import-eMASRuntimeConfiguration `
        -Path $RuntimeConfigurationPath `
        -ExecutionLogPath $ExecutionLogPath `
        -ExecutionId $executionId `
        -Phase $Phase `
        -ActiveScript $ActiveScript `
        -TemplatePath $TemplatePath

    if ($configuration.Validation.BlockingIssueCount -gt 0) {
        throw ('CFG-VALIDATION-002 Phase initialization stopped before assessment processing because configuration validation reported {0} blocking issue(s).' -f $configuration.Validation.BlockingIssueCount)
    }

    return [pscustomobject]@{
        ExecutionId = $executionId
        Phase = $Phase
        ActiveScript = $ActiveScript
        ExecutionLogPath = [System.IO.Path]::GetFullPath($ExecutionLogPath)
        RuntimeConfiguration = $configuration
        InitializationStatus = 'ConfigurationValidated'
        AssessmentProcessingStarted = $false
    }
}
