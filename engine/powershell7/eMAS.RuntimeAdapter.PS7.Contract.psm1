Set-StrictMode -Version 2.0

function Get-eMASRuntimeAdapterContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Adapter = 'powershell7'
        RequiredPSEdition = 'Core'
        RequiredPowerShellVersion = '7.6'
        RequiredPlatform = 'Windows'
        DevelopmentPlatform = 'macOS allowed for pure unit and fixture tests'
        SupportedPhases = @('PRE_MIGRATION', 'POST_MIGRATION')
        EntryExecutable = 'pwsh.exe'
        AdapterBoundary = 'Technical runtime compatibility only'
        UsesSharedCore = $true
    }
}

Export-ModuleMember -Function Get-eMASRuntimeAdapterContract
