Set-StrictMode -Version 2.0

function Get-eMASRuntimeAdapterContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Adapter = 'powershell51'
        RequiredPSEdition = 'Desktop'
        RequiredPowerShellVersion = '5.1'
        RequiredPlatform = 'Windows'
        SupportedPhases = @('PRE_SALES')
        EntryExecutable = 'powershell.exe'
        AdapterBoundary = 'Technical runtime compatibility only'
        UsesSharedCore = $true
    }
}

Export-ModuleMember -Function Get-eMASRuntimeAdapterContract
