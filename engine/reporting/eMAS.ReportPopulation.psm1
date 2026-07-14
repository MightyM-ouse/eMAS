Set-StrictMode -Version 2.0

function Resolve-eMASPythonExecutable {
    [CmdletBinding()]
    param([string] $PythonExecutablePath)

    if ($PythonExecutablePath) {
        $resolved = Resolve-Path -LiteralPath $PythonExecutablePath -ErrorAction Stop
        return $resolved.ProviderPath
    }

    foreach ($candidate in @('python3', 'python')) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) { return $command.Source }
    }

    throw 'RPT-VALIDATE-010: Python 3 is required by the OpenXML report helper but was not found.'
}

function Resolve-eMASResultSchemaPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepositoryRoot,

        [Parameter(Mandatory = $true)]
        [string] $TemplateMappingPath,

        [string] $ResultSchemaPath
    )

    if ($ResultSchemaPath) {
        return (Resolve-Path -LiteralPath $ResultSchemaPath -ErrorAction Stop).ProviderPath
    }

    try {
        $mapping = Get-Content -LiteralPath $TemplateMappingPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "RPT-MAP-004: Template mapping JSON could not be loaded. $($_.Exception.Message)"
    }

    $configuredPath = [string] $mapping.resultSchemaPath
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        throw 'RPT-RESULT-SCHEMA-002: The selected report mapping does not declare resultSchemaPath.'
    }

    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        $candidate = $configuredPath
    }
    else {
        $candidate = Join-Path $RepositoryRoot $configuredPath
    }

    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "RPT-RESULT-SCHEMA-003: The normalized result schema file was not found: $candidate"
    }

    return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).ProviderPath
}

function Export-eMASResultToTemplate {
    [CmdletBinding(DefaultParameterSetName = 'ResultObject')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ResultObject')]
        [ValidateNotNull()]
        [object] $Result,

        [Parameter(Mandatory = $true, ParameterSetName = 'ResultJson')]
        [ValidateNotNullOrEmpty()]
        [string] $ResultJsonPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TemplateMappingPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TemplatePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputWorkbookPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExecutionLogPath,

        [string] $PythonExecutablePath,
        [string] $MappingSchemaPath,
        [string] $ResultSchemaPath
    )

    $moduleRoot = Split-Path -Parent $PSCommandPath
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $moduleRoot)
    $helperPath = Join-Path $moduleRoot 'emas_report_openxml_v32.py'
    if (-not $MappingSchemaPath) {
        $MappingSchemaPath = Join-Path $repositoryRoot 'config/report-mappings/report-template-map.schema.json'
    }

    foreach ($requiredPath in @($helperPath, $TemplateMappingPath, $TemplatePath, $MappingSchemaPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "RPT-VALIDATE-011: Required report-generation file was not found: $requiredPath"
        }
    }

    $effectiveResultSchemaPath = Resolve-eMASResultSchemaPath `
        -RepositoryRoot $repositoryRoot `
        -TemplateMappingPath $TemplateMappingPath `
        -ResultSchemaPath $ResultSchemaPath

    $temporaryResultPath = $null
    try {
        if ($PSCmdlet.ParameterSetName -eq 'ResultObject') {
            $temporaryResultPath = Join-Path ([System.IO.Path]::GetTempPath()) ("emas-result-{0}.json" -f ([guid]::NewGuid().ToString('N')))
            $json = $Result | ConvertTo-Json -Depth 100
            [System.IO.File]::WriteAllText($temporaryResultPath, $json, (New-Object System.Text.UTF8Encoding($false)))
            $effectiveResultPath = $temporaryResultPath
        }
        else {
            $effectiveResultPath = (Resolve-Path -LiteralPath $ResultJsonPath -ErrorAction Stop).ProviderPath
        }

        $python = Resolve-eMASPythonExecutable -PythonExecutablePath $PythonExecutablePath
        $arguments = @(
            $helperPath,
            '--result', $effectiveResultPath,
            '--result-schema', $effectiveResultSchemaPath,
            '--mapping', $TemplateMappingPath,
            '--mapping-schema', $MappingSchemaPath,
            '--template', $TemplatePath,
            '--output', $OutputWorkbookPath,
            '--log', $ExecutionLogPath
        )
        $rawOutput = & $python @arguments 2>&1
        $exitCode = $LASTEXITCODE
        $responseText = ($rawOutput | Select-Object -Last 1 | Out-String).Trim()
        try { $response = $responseText | ConvertFrom-Json -ErrorAction Stop }
        catch { throw "RPT-VALIDATE-012: OpenXML helper returned malformed output. $responseText" }
        if ($exitCode -ne 0 -or $response.Status -ne 'Passed') {
            $firstFinding = @($response.Validation.Findings)[0]
            throw ("{0}: {1}" -f $firstFinding.Code, $firstFinding.Message)
        }
        return $response
    }
    finally {
        if ($temporaryResultPath -and (Test-Path -LiteralPath $temporaryResultPath)) {
            Remove-Item -LiteralPath $temporaryResultPath -Force
        }
    }
}

Export-ModuleMember -Function Export-eMASResultToTemplate
