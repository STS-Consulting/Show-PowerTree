
function Build-ChildItemDirectoryParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$ShowHiddenFiles,
        [Parameter(Mandatory = $false)]
        [bool]$ShowHiddenFolders
    )

    $directoryParameters = @{
        Directory   = $true
        ErrorAction = 'SilentlyContinue'
    }

    if ($ShowHiddenFolders) {
        $directoryParameters.Add('Force', $true)
    }
    return $directoryParameters
}
