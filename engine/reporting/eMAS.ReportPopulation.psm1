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

    throw 'RPT-VALIDATE-010: Python 3 is required by the MVP OpenXML helper but was not found.'
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
        [string] $MappingSchemaPath
    )

    $moduleRoot = Split-Path -Parent $PSCommandPath
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $moduleRoot)
    $helperPath = Join-Path $moduleRoot 'emas_report_openxml.py'
    if (-not $MappingSchemaPath) {
        $MappingSchemaPath = Join-Path $repositoryRoot 'config/report-mappings/report-template-map.schema.json'
    }

    foreach ($requiredPath in @($helperPath, $TemplateMappingPath, $TemplatePath, $MappingSchemaPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "RPT-VALIDATE-011: Required report-generation file was not found: $requiredPath"
        }
    }

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
