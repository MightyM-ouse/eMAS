#requires -Version 5.1

[CmdletBinding(DefaultParameterSetName = 'Initialization')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Initialization')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [Alias('RuntimeJsonPath', 'ConfigurationPath')]
    [ValidateNotNullOrEmpty()]
    [string] $RuntimeConfigurationPath,

    [string] $ExecutionLogPath,

    [string] $TemplatePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'RepositoryDiscovery')]
    [ValidateNotNullOrEmpty()]
    [string] $SourcePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'RepositoryDiscovery')]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'RepositoryDiscovery')]
    [ValidateNotNullOrEmpty()]
    [string] $ExecutionId,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [ValidateSet('MS-04')]
    [string] $ScenarioId = 'MS-04',

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [ValidateSet('PreSales')]
    [string] $Phase = 'PreSales',

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeBackboneXmlInventory,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeReferenceInventory,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeReferenceResolution,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeMissingReferenceInterpretation,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeDeclaredChecksumComparison,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeChecksumMismatchInterpretation,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeClassificationEvidenceCollection,

    [Parameter(Mandatory = $false, ParameterSetName = 'RepositoryDiscovery')]
    [switch] $IncludeIdentificationInterpretation
)

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/Initialize-eMASPhaseRuntime.ps1')

if ($PSCmdlet.ParameterSetName -eq 'Initialization') {
    Initialize-eMASPhaseRuntime `
        -Phase 'PRE_SALES' `
        -RuntimeConfigurationPath $RuntimeConfigurationPath `
        -ActiveScript $MyInvocation.MyCommand.Name `
        -ExecutionLogPath $ExecutionLogPath `
        -TemplatePath $TemplatePath
    return
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$configurationIdentity = $null
$configuration = $null
if ($IncludeIdentificationInterpretation -and [string]::IsNullOrWhiteSpace($RuntimeConfigurationPath)) {
    throw 'ID-SCRIPT-001 IncludeIdentificationInterpretation requires RuntimeConfigurationPath.'
}
if (-not [string]::IsNullOrWhiteSpace($RuntimeConfigurationPath)) {
    $runtimeConfigurationModule = Join-Path $repositoryRoot 'engine/core/eMAS.RuntimeConfiguration.psm1'
    Import-Module -Name $runtimeConfigurationModule -Force -ErrorAction Stop
    $configuration = Import-eMASRuntimeConfiguration `
        -Path $RuntimeConfigurationPath `
        -ExecutionLogPath $ExecutionLogPath `
        -ExecutionId $ExecutionId `
        -Phase 'PRE_SALES' `
        -ActiveScript $MyInvocation.MyCommand.Name `
        -TemplatePath $TemplatePath
    $configurationIdentity = [pscustomobject][ordered]@{
        ConfigurationId = $configuration.ConfigurationId
        Version = $configuration.ConfigurationVersion
        Sha256 = $configuration.FileHashSha256
    }
}

$repositoryDiscoveryModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
Import-Module -Name $repositoryDiscoveryModule -Force -ErrorAction Stop
$repositoryDiscoveryParameters = @{
    SourcePath = $SourcePath
    ExecutionId = $ExecutionId
    ScenarioId = $ScenarioId
    Phase = $Phase
    ConfigurationIdentity = $configurationIdentity
}
if (-not $IncludeBackboneXmlInventory -and -not $IncludeReferenceInventory -and -not $IncludeReferenceResolution -and -not $IncludeMissingReferenceInterpretation -and -not $IncludeDeclaredChecksumComparison -and -not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $repositoryDiscoveryParameters.OutputPath = $OutputPath
    Invoke-eMASRepositoryDiscovery @repositoryDiscoveryParameters
    return
}

$repositoryDiscoveryResult = Invoke-eMASRepositoryDiscovery `
    -SourcePath $SourcePath `
    -ExecutionId $ExecutionId `
    -ScenarioId $ScenarioId `
    -Phase $Phase `
    -ConfigurationIdentity $configurationIdentity

$backboneXmlInventoryModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
Import-Module -Name $backboneXmlInventoryModule -Force -ErrorAction Stop
$backboneXmlInventoryResult = Invoke-eMASBackboneXmlInventory `
    -SourcePath $SourcePath `
    -RepositoryDiscoveryResult $repositoryDiscoveryResult `
    -OutputPath $(if ($IncludeReferenceInventory -or $IncludeReferenceResolution -or $IncludeMissingReferenceInterpretation -or $IncludeDeclaredChecksumComparison -or $IncludeChecksumMismatchInterpretation -or $IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeReferenceInventory -and -not $IncludeReferenceResolution -and -not $IncludeMissingReferenceInterpretation -and -not $IncludeDeclaredChecksumComparison -and -not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $backboneXmlInventoryResult
    return
}

$referenceInventoryModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1'
Import-Module -Name $referenceInventoryModule -Force -ErrorAction Stop
$referenceInventoryResult = Invoke-eMASReferenceInventory `
    -SourcePath $SourcePath `
    -RepositoryDiscoveryResult $repositoryDiscoveryResult `
    -BackboneXmlInventoryResult $backboneXmlInventoryResult `
    -OutputPath $(if ($IncludeReferenceResolution -or $IncludeMissingReferenceInterpretation -or $IncludeDeclaredChecksumComparison -or $IncludeChecksumMismatchInterpretation -or $IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeReferenceResolution -and -not $IncludeMissingReferenceInterpretation -and -not $IncludeDeclaredChecksumComparison -and -not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $referenceInventoryResult
    return
}

$referenceResolutionModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceResolution.psm1'
Import-Module -Name $referenceResolutionModule -Force -ErrorAction Stop
$referenceResolutionResult = Invoke-eMASReferenceResolution `
    -SourcePath $SourcePath `
    -RepositoryDiscoveryResult $repositoryDiscoveryResult `
    -ReferenceInventoryResult $referenceInventoryResult `
    -OutputPath $(if ($IncludeMissingReferenceInterpretation -or $IncludeDeclaredChecksumComparison -or $IncludeChecksumMismatchInterpretation -or $IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeMissingReferenceInterpretation -and -not $IncludeDeclaredChecksumComparison -and -not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $referenceResolutionResult
    return
}

$missingReferenceInterpretationModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.MissingReferenceInterpretation.psm1'
Import-Module -Name $missingReferenceInterpretationModule -Force -ErrorAction Stop
$missingReferenceInterpretationResult = Invoke-eMASMissingReferenceInterpretation `
    -ReferenceResolutionResult $referenceResolutionResult `
    -OutputPath $(if ($IncludeDeclaredChecksumComparison -or $IncludeChecksumMismatchInterpretation -or $IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeDeclaredChecksumComparison -and -not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $missingReferenceInterpretationResult
    return
}

$declaredChecksumComparisonModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.DeclaredChecksumComparison.psm1'
Import-Module -Name $declaredChecksumComparisonModule -Force -ErrorAction Stop
$declaredChecksumComparisonResult = Invoke-eMASDeclaredChecksumComparison `
    -SourcePath $SourcePath `
    -MissingReferenceInterpretationResult $missingReferenceInterpretationResult `
    -OutputPath $(if ($IncludeChecksumMismatchInterpretation -or $IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeChecksumMismatchInterpretation -and -not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $declaredChecksumComparisonResult
    return
}

$checksumMismatchInterpretationModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ChecksumMismatchInterpretation.psm1'
Import-Module -Name $checksumMismatchInterpretationModule -Force -ErrorAction Stop
$checksumMismatchInterpretationResult = Invoke-eMASChecksumMismatchInterpretation `
    -DeclaredChecksumComparisonResult $declaredChecksumComparisonResult `
    -OutputPath $(if ($IncludeClassificationEvidenceCollection -or $IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeClassificationEvidenceCollection -and -not $IncludeIdentificationInterpretation) {
    $checksumMismatchInterpretationResult
    return
}

$classificationEvidenceCollectionModule = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1'
Import-Module -Name $classificationEvidenceCollectionModule -Force -ErrorAction Stop
$classificationEvidenceCollectionResult = Invoke-eMASClassificationEvidenceCollection `
    -InputResult $checksumMismatchInterpretationResult `
    -OutputPath $(if ($IncludeIdentificationInterpretation) { $null } else { $OutputPath })

if (-not $IncludeIdentificationInterpretation) {
    $classificationEvidenceCollectionResult
    return
}

$identificationInterpretationModule = Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1'
Import-Module -Name $identificationInterpretationModule -Force -ErrorAction Stop
Invoke-eMASIdentificationInterpretation `
    -InputResult $classificationEvidenceCollectionResult `
    -RuntimeConfiguration $configuration `
    -OutputPath $OutputPath
