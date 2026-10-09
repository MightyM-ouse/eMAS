# MS-04 demo runner suite catalog (data only).
#
# Every entry names an existing, committed harness and the exact arguments its
# param() block requires. Expected counts were taken from the accepted T2
# report (EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION) and confirmed by a
# direct pre-implementation run on macOS PowerShell 7.5.2. A count that differs
# from these values is reported as FAIL (CountDrift); it is never relaxed here
# without a reviewed change.
#
# Argument tokens resolved by the runner:
#   {HarnessOutput}            per-stage output directory inside the run directory
#   {Wave1CorpusRoot}          external frozen Wave 1 corpus root
#   {Wave1FreezeManifestPath}  WAVE1_FREEZE_MANIFEST.csv for that corpus
#   {Wave1DCorpusRoot}         external Wave1D dossier-diversity package root
#
# Counter kinds:
#   Summary     read the harness summary JSON written into {HarnessOutput}
#   ResultLine  parse the harness's final stdout result line
@{
    CatalogVersion = '1.0.0'

    Suites = @(
        @{
            Id = 'T2-SUXI'; GateGroup = 'FocusedT2'; Name = 'T2 SubmissionUnit XML inventory (focused)'
            Script = 'tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1'
            Modes = @('QuickCheck', 'FullRegression')
            Arguments = @('-OutputRoot', '{HarnessOutput}')
            OptionalArguments = @(@{ Requires = 'Wave1'; Arguments = @('-Wave1CorpusRoot', '{Wave1CorpusRoot}') })
            Requires = @()
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'submissionunit-xml-inventory-test-summary.json'
                TotalFields = @('Total'); FailFields = @('Failed'); PassFields = @('Passed'); SkipFields = @('Skipped')
                Gates = @{ FixtureFiles = 22 }
            }
            Expected = @{
                WithWave1 = @{ Total = 22; Passed = 22; Failed = 0; Skipped = 0 }
                Default = @{ Total = 22; Passed = 21; Failed = 0; Skipped = 1 }
            }
            SkipNote = 'The design SD-090 mixed v3/v4 check needs the external frozen Wave 1 SD-002 corpus (-Wave1CorpusRoot); without it the harness reports it as SKIP.'
        }
        @{
            Id = 'T4-ENGINE'; GateGroup = 'Established15'; Name = 'T4 IdentificationInterpretation engine'
            Script = 'tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1'
            Modes = @('QuickCheck', 'FullRegression')
            Arguments = @(); Requires = @()
            Counter = @{ Kind = 'ResultLine'; Pattern = '^IdentificationInterpretation engine tests completed: (?<total>\d+) total, (?<passed>\d+) passed, (?<failed>\d+) failed\.$' }
            Expected = @{ Default = @{ Total = 28; Passed = 28; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'T4-ORACLE'; GateGroup = 'Established15'; Name = 'T4 accepted oracle conformance (read-only)'
            Script = 'tests/identification-interpretation/engine/Test-eMASIdentificationOracleConformance.ps1'
            Modes = @('QuickCheck', 'FullRegression')
            Arguments = @(); Requires = @()
            Counter = @{ Kind = 'ResultLine'; Pattern = '^IdentificationInterpretation oracle conformance: (?<total>\d+) cases \(\d+ output, \d+ expected-failure\), (?<passed>\d+) passed, (?<failed>\d+) failed\.$' }
            Expected = @{ Default = @{ Total = 23; Passed = 23; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-RD'; GateGroup = 'Established15'; Name = 'Wave 1 RepositoryDiscovery'
            Script = 'tests/repository-discovery/Test-eMASRepositoryDiscovery.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'repository-discovery-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCaseCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 13; Passed = 13; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-BXI'; GateGroup = 'Established15'; Name = 'Wave 1 BackboneXmlInventory'
            Script = 'tests/backbone-xml-inventory/Test-eMASBackboneXmlInventory.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'backbone-xml-inventory-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('PrimaryFixtureCount', 'RegressionFixtureCount', 'AdditionalCheckCount')
                FailFields = @('PrimaryFixtureFailCount', 'RegressionFixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 24; Passed = 24; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-RI'; GateGroup = 'Established15'; Name = 'Wave 1 ReferenceInventory'
            Script = 'tests/reference-inventory/Test-eMASReferenceInventory.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'reference-inventory-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('PrimaryFixtureCount', 'RegressionFixtureCount', 'AdditionalCheckCount')
                FailFields = @('PrimaryFixtureFailCount', 'RegressionFixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 28; Passed = 28; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-RR'; GateGroup = 'Established15'; Name = 'Wave 1 ReferenceResolution'
            Script = 'tests/reference-resolution/Test-eMASReferenceResolution.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'reference-resolution-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 31; Passed = 31; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-MRI'; GateGroup = 'Established15'; Name = 'Wave 1 MissingReferenceInterpretation'
            Script = 'tests/missing-reference-interpretation/Test-eMASMissingReferenceInterpretation.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'missing-reference-interpretation-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 33; Passed = 33; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-DCC'; GateGroup = 'Established15'; Name = 'Wave 1 DeclaredChecksumComparison'
            Script = 'tests/declared-checksum-comparison/Test-eMASDeclaredChecksumComparison.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'declared-checksum-comparison-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 37; Passed = 37; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-CMI'; GateGroup = 'Established15'; Name = 'Wave 1 ChecksumMismatchInterpretation'
            Script = 'tests/checksum-mismatch-interpretation/Test-eMASChecksumMismatchInterpretation.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'checksum-mismatch-interpretation-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{ FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19 }
            }
            Expected = @{ Default = @{ Total = 54; Passed = 54; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1-CEC'; GateGroup = 'Established15'; Name = 'Wave 1 ClassificationEvidenceCollection'
            Script = 'tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-FreezeManifestPath', '{Wave1FreezeManifestPath}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'classification-evidence-collection-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FixtureFailCount', 'AdditionalCheckFailCount')
                Gates = @{
                    FrozenFixtureCountVerifiedBefore = 19; FrozenFixtureCountVerifiedAfter = 19
                    Wave1EFrozenFixtureCountVerifiedBefore = 22; Wave1EFrozenFixtureCountVerifiedAfter = 22
                }
            }
            Expected = @{ Default = @{ Total = 62; Passed = 62; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'T1B'; GateGroup = 'Established15'; Name = 'T1b regional XML evidence'
            Script = 'tests/regional-xml-evidence/Test-eMASRegionalXmlEvidence.ps1'
            Modes = @('FullRegression')
            Arguments = @('-OutputRoot', '{HarnessOutput}'); Requires = @()
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'regional-xml-evidence-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('CheckCount'); FailFields = @('FailCount'); PassFields = @('PassCount')
                Gates = @{ FixtureHashesVerifiedBeforeAndAfter = 11 }
            }
            Expected = @{ Default = @{ Total = 10; Passed = 10; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1E'; GateGroup = 'Established15'; Name = 'Wave1E eCTD v4 physical discovery'
            Script = 'tests/repository-discovery-ectd4/Test-eMASRepositoryDiscoveryEctd4.ps1'
            Modes = @('FullRegression')
            Arguments = @('-OutputRoot', '{HarnessOutput}'); Requires = @()
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'repository-discovery-ectd4-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('FixtureCount', 'AdditionalCheckCount'); FailFields = @('FailCount'); PassFields = @('PassCount', 'AdditionalPassCount')
                Gates = @{ FreezeGateCount = 22 }
            }
            Expected = @{ Default = @{ Total = 24; Passed = 24; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'W1D'; GateGroup = 'Established15'; Name = 'Wave1D dossier diversity'
            Script = 'tests/dossier-diversity/Test-eMASDossierDiversity.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1DCorpusRoot}', '-Wave1CorpusRoot', '{Wave1CorpusRoot}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1D', 'Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'dossier-diversity-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('CheckCount'); FailFields = @('FailCount', 'NormativeFailCount'); PassFields = @('PassCount')
            }
            Expected = @{ Default = @{ Total = 61; Passed = 61; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'ROOT'; GateGroup = 'Established15'; Name = 'Root-level dossier'
            Script = 'tests/root-level-dossier/Test-eMASRootLevelDossier.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'root-level-dossier-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('CheckCount'); FailFields = @('FailCount'); PassFields = @('PassCount')
            }
            Expected = @{ Default = @{ Total = 3; Passed = 3; Failed = 0; Skipped = 0 } }
        }
        @{
            Id = 'B3'; GateGroup = 'Established15'; Name = 'B3 RepositoryDiscovery candidate semantics'
            Script = 'tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1'
            Modes = @('FullRegression')
            Arguments = @('-CorpusRoot', '{Wave1CorpusRoot}', '-OutputRoot', '{HarnessOutput}')
            Requires = @('Wave1')
            Counter = @{
                Kind = 'Summary'; SummaryFile = 'repository-discovery-candidate-semantics-test-summary.json'; StatusField = 'OverallStatus'
                TotalFields = @('CheckCount'); FailFields = @('FailCount'); PassFields = @('PassCount')
            }
            Expected = @{ Default = @{ Total = 12; Passed = 12; Failed = 0; Skipped = 0 } }
        }
    )

    # Committed freeze manifests the runner verifies itself (runner-native, read-only).
    CommittedManifests = @(
        @{ Id = 'SUXI'; Path = 'tests/fixtures/submissionunit-xml-inventory/SUXI_FREEZE_MANIFEST.csv'; PathColumn = 'RelativePath'; HashColumn = 'SHA256'; ExpectedRows = 22 }
        @{ Id = 'WAVE1E'; Path = 'tests/fixtures/repository-discovery-ectd4/wave1e/WAVE1E_FREEZE_MANIFEST.csv'; PathColumn = 'FixtureFilename'; HashColumn = 'FixtureSHA256'; ExpectedRows = 22 }
    )

    # Repository paths hashed before and after every run (read-only gate).
    ProtectedTrees = @('tests/fixtures', 'tests/identification-interpretation/oracle', 'config', 'engine', 'scripts')

    # Fields removed before comparing an observed Identification/1.0 document with a
    # supplied expected document. The first three are the accepted oracle volatile
    # fields. The last three are assigned per run on the dossier route: the
    # ExecutionId is runner-generated and DocumentSha256 hashes the in-memory,
    # timestamped evidence document, so it differs between otherwise identical runs.
    IdentificationVolatileFields = @(
        'Execution.EngineVersion', 'Execution.StartedAtUtc', 'Execution.CompletedAtUtc',
        'Execution.ExecutionId', 'EvidenceSource.ExecutionId', 'EvidenceSource.DocumentSha256'
    )
}
