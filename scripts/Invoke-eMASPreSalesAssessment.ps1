#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('ExternalExport','ECTDManagerExport','ECTDManagerDatabaseArchive','ECTDManagerHybrid','ArchiveOnly')]
    [string]$Mode,

    [string]$CustomerName,
    [string]$ProjectName,
    [string]$AssessmentReference,

    [string]$CurrentApplication,
    [string]$CurrentVersion,
    [string]$CurrentHotfix,
    [string]$CurrentDatabaseType,
    [string]$CurrentDatabaseVersion,

    [string[]]$ExportRoot,
    [string[]]$ArchiveRoot,
    [string[]]$IndexRoot,
    [string[]]$DatabasePath,

    [Nullable[Double]]$ArchiveSizeGB,
    [Nullable[Double]]$IndexSizeGB,
    [Nullable[Double]]$DatabaseSizeGB,

    [string]$RuntimeConfigPath,
    [string]$OutputRoot = (Join-Path -Path (Get-Location) -ChildPath 'output'),
    [switch]$NonInteractive
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Read-RequiredText {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$CurrentValue
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
        return $CurrentValue.Trim()
    }

    if ($NonInteractive) {
        throw "Required value was not supplied: $Prompt"
    }

    do {
        $value = Read-Host $Prompt
    } while ([string]::IsNullOrWhiteSpace($value))

    return $value.Trim()
}

function Read-OptionalText {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$CurrentValue
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
        return $CurrentValue.Trim()
    }

    if ($NonInteractive) {
        return $null
    }

    $value = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }
    return $value.Trim()
}

function Select-AssessmentMode {
    param([string]$CurrentMode)

    if (-not [string]::IsNullOrWhiteSpace($CurrentMode)) {
        return $CurrentMode
    }

    if ($NonInteractive) {
        throw 'Mode is required when -NonInteractive is used.'
    }

    Write-Host ''
    Write-Host 'Select the Pre-Sales assessment mode:' -ForegroundColor Cyan
    Write-Host '  1. External-system export assessment'
    Write-Host '  2. eCTDmanager export assessment'
    Write-Host '  3. eCTDmanager database and archive move'
    Write-Host '  4. eCTDmanager hybrid assessment'
    Write-Host '  5. Archive and index move'
    Write-Host ''

    do {
        $selection = Read-Host 'Enter 1, 2, 3, 4 or 5'
    } while ($selection -notin @('1','2','3','4','5'))

    switch ($selection) {
        '1' { return 'ExternalExport' }
        '2' { return 'ECTDManagerExport' }
        '3' { return 'ECTDManagerDatabaseArchive' }
        '4' { return 'ECTDManagerHybrid' }
        '5' { return 'ArchiveOnly' }
    }
}

function ConvertTo-PathArray {
    param([object]$Value)

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Value)) {
        if ($null -eq $item) { continue }
        foreach ($part in ([string]$item -split ';')) {
            if (-not [string]::IsNullOrWhiteSpace($part)) {
                $result.Add($part.Trim())
            }
        }
    }
    return @($result)
}

function Read-RequiredPathList {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [string[]]$CurrentPaths
    )

    $paths = ConvertTo-PathArray -Value $CurrentPaths
    if ($paths.Count -gt 0) { return $paths }

    if ($NonInteractive) {
        throw "$Label path is required for the selected mode."
    }

    Write-Host ''
    Write-Host "$Label is required for this assessment mode." -ForegroundColor Cyan
    Write-Host 'Enter one or more paths separated by semicolons.'
    do {
        $value = Read-Host "$Label path(s)"
        $paths = ConvertTo-PathArray -Value $value
    } while ($paths.Count -eq 0)

    return $paths
}

function Read-DirectCopyInput {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [string[]]$CurrentPaths,
        [Nullable[Double]]$CurrentSizeGB
    )

    $paths = ConvertTo-PathArray -Value $CurrentPaths
    if ($paths.Count -gt 0 -and $null -ne $CurrentSizeGB) {
        throw "$Label evidence must be supplied either as path(s) or as a customer-provided aggregate size, not both."
    }

    if ($paths.Count -gt 0 -or $null -ne $CurrentSizeGB) {
        return [pscustomobject][ordered]@{
            paths  = $paths
            sizeGB = $CurrentSizeGB
        }
    }

    if ($NonInteractive) {
        throw "$Label evidence is required for the selected mode. Supply a path or a customer-provided aggregate size."
    }

    Write-Host ''
    Write-Host "$Label evidence is required for this assessment mode." -ForegroundColor Cyan
    Write-Host '  1. Calculate aggregate size from a path'
    Write-Host '  2. Enter a customer-provided aggregate size in GB'

    do {
        $choice = Read-Host 'Select 1 or 2'
    } while ($choice -notin @('1','2'))

    if ($choice -eq '1') {
        $selectedPaths = Read-RequiredPathList -Label $Label -CurrentPaths @()
        return [pscustomobject][ordered]@{
            paths  = $selectedPaths
            sizeGB = $null
        }
    }

    do {
        $sizeText = Read-Host "$Label total size in GB"
        $parsed = 0.0
        $valid = [double]::TryParse(
            $sizeText,
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed
        )
    } while (-not $valid -or $parsed -lt 0)

    return [pscustomobject][ordered]@{
        paths  = @()
        sizeGB = [Nullable[Double]]$parsed
    }
}

function ConvertTo-SafeFileName {
    param([Parameter(Mandatory = $true)][string]$Value)

    $safe = $Value -replace '[^A-Za-z0-9._-]', '_'
    $safe = $safe.Trim('_')
    if ([string]::IsNullOrWhiteSpace($safe)) { return 'Assessment' }
    return $safe
}

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repositoryRoot = Split-Path -Path $scriptRoot -Parent
$modulePath = Join-Path -Path $repositoryRoot -ChildPath 'engine\powershell51\eMAS.PreSales.Collection.psm1'

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Required module was not found: $modulePath"
}
Import-Module -Name $modulePath -Force -ErrorAction Stop

$Mode = Select-AssessmentMode -CurrentMode $Mode
$requirements = Get-eMASModeRequirements -Mode $Mode

if ([string]::IsNullOrWhiteSpace($CurrentApplication) -and -not [string]::IsNullOrWhiteSpace($requirements.defaultApplication)) {
    $CurrentApplication = $requirements.defaultApplication
}

$CustomerName = Read-RequiredText -Prompt 'Customer name' -CurrentValue $CustomerName
$ProjectName = Read-RequiredText -Prompt 'Project or opportunity name' -CurrentValue $ProjectName
$CurrentApplication = Read-RequiredText -Prompt 'Current application or source system name' -CurrentValue $CurrentApplication
$CurrentVersion = Read-OptionalText -Prompt 'Current application version (press Enter if unknown)' -CurrentValue $CurrentVersion
$CurrentHotfix = Read-OptionalText -Prompt 'Current application hotfix (press Enter if not applicable or unknown)' -CurrentValue $CurrentHotfix

if ($requirements.requiresDatabase) {
    $CurrentDatabaseType = Read-OptionalText -Prompt 'Current database type (press Enter if unknown)' -CurrentValue $CurrentDatabaseType
    $CurrentDatabaseVersion = Read-OptionalText -Prompt 'Current database version (press Enter if unknown)' -CurrentValue $CurrentDatabaseVersion
}

if ([string]::IsNullOrWhiteSpace($AssessmentReference)) {
    $AssessmentReference = '{0}-{1}' -f (ConvertTo-SafeFileName -Value $CustomerName), (Get-Date -Format 'yyyyMMdd-HHmmss')
}

if ($requirements.requiresExport) {
    $ExportRoot = Read-RequiredPathList -Label 'Export evidence' -CurrentPaths $ExportRoot
}
else {
    $ExportRoot = @()
}

$archiveInput = $null
$indexInput = $null
$databaseInput = $null

if ($requirements.requiresArchive) {
    $archiveInput = Read-DirectCopyInput -Label 'Archive' -CurrentPaths $ArchiveRoot -CurrentSizeGB $ArchiveSizeGB
}
if ($requirements.requiresIndex) {
    $indexInput = Read-DirectCopyInput -Label 'Index' -CurrentPaths $IndexRoot -CurrentSizeGB $IndexSizeGB
}
if ($requirements.requiresDatabase) {
    $databaseInput = Read-DirectCopyInput -Label 'Database or database backup' -CurrentPaths $DatabasePath -CurrentSizeGB $DatabaseSizeGB
}

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}
$OutputRoot = (Resolve-Path -LiteralPath $OutputRoot).Path

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$safeReference = ConvertTo-SafeFileName -Value $AssessmentReference
$executionId = 'EMAS-PS-{0}-{1}' -f $safeReference, $timestamp
$baseName = 'eMAS_PreSalesCollection_{0}_{1}' -f $safeReference, $timestamp
$logPath = Join-Path -Path $OutputRoot -ChildPath ($baseName + '.log')
$resultPath = Join-Path -Path $OutputRoot -ChildPath ($baseName + '.result.json')

New-Item -ItemType File -Path $logPath -Force | Out-Null

try {
    Write-Host ''
    Write-Host 'eMAS Pre-Sales Customer Collection' -ForegroundColor Cyan
    Write-Host ('Assessment mode: {0}' -f $requirements.displayName)
    Write-Host ('Assessment reference: {0}' -f $AssessmentReference)
    Write-Host ''

    Write-eMASLog -LogPath $logPath -Message '[1/7] Starting Pre-Sales customer collection.'
    Write-eMASLog -LogPath $logPath -Message ("Execution ID: {0}" -f $executionId) -NoConsole
    Write-eMASLog -LogPath $logPath -Message ("Mode: {0}" -f $Mode) -NoConsole
    Write-eMASLog -LogPath $logPath -Message ("Current system: {0} {1} {2}" -f $CurrentApplication, $CurrentVersion, $CurrentHotfix) -NoConsole

    Write-eMASLog -LogPath $logPath -Message '[2/7] Loading runtime configuration.'
    if ([string]::IsNullOrWhiteSpace($RuntimeConfigPath)) {
        $defaultConfig = Join-Path -Path $repositoryRoot -ChildPath 'config\runtime\eMAS_Runtime_Config.json'
        if (Test-Path -LiteralPath $defaultConfig -PathType Leaf) {
            $RuntimeConfigPath = $defaultConfig
        }
    }

    $runtimeConfigIdentity = Get-eMASRuntimeConfigIdentity -RuntimeConfigPath $RuntimeConfigPath
    $runtimeConfig = $null
    if ($runtimeConfigIdentity.loaded) {
        $runtimeConfig = $runtimeConfigIdentity.configObject
        Write-eMASLog -LogPath $logPath -Message ("Loaded runtime mapping {0} version {1}." -f $runtimeConfigIdentity.mappingId, $runtimeConfigIdentity.mappingVersion) -NoConsole
    }
    else {
        Write-eMASLog -LogPath $logPath -Level WARN -Message $runtimeConfigIdentity.loadMessage
    }

    $exportEvidence = @()
    $dossierInventory = @()
    $sequenceInventory = @()

    Write-eMASLog -LogPath $logPath -Message '[3/7] Collecting export evidence.'
    if ($requirements.requiresExport) {
        $exportResult = Get-eMASExportInventory -Roots $ExportRoot -LogPath $logPath -RuntimeConfig $runtimeConfig
        $exportEvidence = @($exportResult.exportEvidence)
        $dossierInventory = @($exportResult.dossierInventory)
        $sequenceInventory = @($exportResult.sequenceInventory)
    }
    else {
        Write-eMASLog -LogPath $logPath -Message 'Export discovery is not applicable to the selected mode.' -NoConsole
    }

    Write-eMASLog -LogPath $logPath -Message '[4/7] Collecting direct-copy aggregate volumes.'
    $directCopyEvidence = New-Object System.Collections.Generic.List[object]
    if ($requirements.requiresArchive) {
        foreach ($row in @(New-eMASDirectCopyEvidence -SourceType 'Archive' -Paths $archiveInput.paths -CustomerProvidedSizeGB $archiveInput.sizeGB -LogPath $logPath)) {
            $directCopyEvidence.Add($row)
        }
    }
    if ($requirements.requiresIndex) {
        foreach ($row in @(New-eMASDirectCopyEvidence -SourceType 'Index' -Paths $indexInput.paths -CustomerProvidedSizeGB $indexInput.sizeGB -LogPath $logPath)) {
            $directCopyEvidence.Add($row)
        }
    }
    if ($requirements.requiresDatabase) {
        foreach ($row in @(New-eMASDirectCopyEvidence -SourceType 'Database' -Paths $databaseInput.paths -CustomerProvidedSizeGB $databaseInput.sizeGB -LogPath $logPath)) {
            $directCopyEvidence.Add($row)
        }
    }

    Write-eMASLog -LogPath $logPath -Message '[5/7] Building collection summary.'
    $summary = Get-eMASCollectionSummary -ExportEvidence $exportEvidence -DirectCopyEvidence @($directCopyEvidence) -DossierInventory $dossierInventory -SequenceInventory $sequenceInventory

    $assessmentContext = [pscustomobject][ordered]@{
        customerName        = $CustomerName
        projectName         = $ProjectName
        assessmentReference = $AssessmentReference
        assessmentDateUtc   = (Get-Date).ToUniversalTime().ToString('o')
        assessmentStatus    = 'Customer Evidence Collected'
    }

    $currentSystem = [pscustomobject][ordered]@{
        application     = $CurrentApplication
        version         = $CurrentVersion
        hotfix          = $CurrentHotfix
        databaseType    = $(if ($requirements.requiresDatabase) { $CurrentDatabaseType } else { $null })
        databaseVersion = $(if ($requirements.requiresDatabase) { $CurrentDatabaseVersion } else { $null })
    }

    foreach ($dossier in $dossierInventory) {
        $dossier.sourceApplication = $CurrentApplication
        $dossier.sourceApplicationVersion = $CurrentVersion
    }

    Write-eMASLog -LogPath $logPath -Message '[6/7] Writing normalized result JSON.'
    $result = New-eMASPreSalesCollectionResult `
        -ExecutionId $executionId `
        -AssessmentMode $Mode `
        -ModeDisplayName $requirements.displayName `
        -AssessmentContext $assessmentContext `
        -CurrentSystem $currentSystem `
        -ExportEvidence $exportEvidence `
        -DirectCopyEvidence @($directCopyEvidence) `
        -DossierInventory $dossierInventory `
        -SequenceInventory $sequenceInventory `
        -CollectionSummary $summary `
        -RuntimeConfigIdentity $runtimeConfigIdentity `
        -LogFileName (Split-Path -Path $logPath -Leaf)

    $result | ConvertTo-Json -Depth 25 | Set-Content -LiteralPath $resultPath -Encoding UTF8

    Write-eMASLog -LogPath $logPath -Message '[7/7] Collection completed successfully.'
    Write-eMASLog -LogPath $logPath -Message ("Result JSON: {0}" -f $resultPath) -NoConsole
    Write-eMASLog -LogPath $logPath -Message ("Log: {0}" -f $logPath) -NoConsole

    Write-Host ''
    Write-Host 'Collection completed successfully.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Files created:'
    Write-Host ('  Result JSON: {0}' -f $resultPath)
    Write-Host ('  Execution log: {0}' -f $logPath)
    Write-Host ''
    Write-Host 'The result is ready for EXTEDO target planning and final estimation.'
    Write-Host 'Excel report generation will be enabled after the updated v3.2 template mapping is approved.'
}
catch {
    $message = $_.Exception.Message
    try {
        Write-eMASLog -LogPath $logPath -Level ERROR -Message ("Collection failed: {0}" -f $message)
    }
    catch {
        Write-Host ("Collection failed: {0}" -f $message) -ForegroundColor Red
    }
    exit 1
}
