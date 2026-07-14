BeforeAll {
    $repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $modulePath = Join-Path $repoRoot 'engine\powershell51\eMAS.PreSales.Collection.psm1'
    Import-Module $modulePath -Force
}

Describe 'eMAS Pre-Sales assessment modes' {
    It 'requires only export evidence for ExternalExport' {
        $mode = Get-eMASModeRequirements -Mode ExternalExport
        $mode.requiresExport | Should -BeTrue
        $mode.requiresArchive | Should -BeFalse
        $mode.requiresIndex | Should -BeFalse
        $mode.requiresDatabase | Should -BeFalse
    }

    It 'requires archive, index and database but not export for database/archive mode' {
        $mode = Get-eMASModeRequirements -Mode ECTDManagerDatabaseArchive
        $mode.requiresExport | Should -BeFalse
        $mode.requiresArchive | Should -BeTrue
        $mode.requiresIndex | Should -BeTrue
        $mode.requiresDatabase | Should -BeTrue
    }
}

Describe 'Direct-copy aggregate evidence' {
    It 'does not expose file or folder inventory columns' {
        $source = Join-Path $TestDrive 'Archive'
        New-Item -ItemType Directory -Path $source | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'a.bin') -Value ('x' * 1024)
        $log = Join-Path $TestDrive 'test.log'
        New-Item -ItemType File -Path $log | Out-Null

        $row = @(New-eMASDirectCopyEvidence -SourceType Archive -Paths @($source) -LogPath $log)[0]
        $row.PSObject.Properties.Name | Should -Contain 'sizeBytes'
        $row.PSObject.Properties.Name | Should -Not -Contain 'fileCount'
        $row.PSObject.Properties.Name | Should -Not -Contain 'folderCount'
        $row.PSObject.Properties.Name | Should -Not -Contain 'longPathCount'
    }
}

Describe 'Export discovery' {
    It 'discovers a dossier and numeric sequence from export evidence' {
        $root = Join-Path $TestDrive 'Export'
        $sequence = Join-Path $root 'ProductA\DossierEU\0000'
        New-Item -ItemType Directory -Path (Join-Path $sequence 'm1') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sequence 'index.xml') -Value '<ectd />'
        Set-Content -LiteralPath (Join-Path $sequence 'index-md5.txt') -Value 'abc'

        $runtime = [pscustomobject]@{
            config = [pscustomobject]@{
                SequenceFolderRegex = '^\d{4}$'
                MaxPathLength = 240
            }
            rules = [pscustomobject]@{
                regions = @(
                    [pscustomobject]@{
                        RuleId = 'REG-EU-TEST'
                        Active = 'Yes'
                        Priority = 1
                        matchTokens = @('DossierEU')
                        ResultRegion = 'EU'
                        Authority = 'EMA / EU National Authority'
                        RegionalImplementation = 'EU eCTD Module 1'
                        Confidence = 'Medium'
                    }
                )
                dossierTypes = @()
            }
        }

        $log = Join-Path $TestDrive 'test.log'
        New-Item -ItemType File -Path $log | Out-Null
        $result = Get-eMASExportInventory -Roots @($root) -LogPath $log -RuntimeConfig $runtime

        @($result.dossierInventory).Count | Should -Be 1
        @($result.sequenceInventory).Count | Should -Be 1
        $result.sequenceInventory[0].format | Should -Be 'eCTD 3.x'
        $result.sequenceInventory[0].region | Should -Be 'EU'
    }
}
