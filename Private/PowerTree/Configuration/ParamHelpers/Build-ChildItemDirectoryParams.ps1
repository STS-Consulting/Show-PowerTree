
function Build-ChildItemDirectoryParams {
    param(
        [boolean]$ShowHiddenFiles,
        [boolean]$ShowHiddenFolders
    )

    $dirParams = @{
        Directory   = $true
        ErrorAction = 'SilentlyContinue'
    }

    if ($ShowHiddenFolders) {
        $dirParams.Add('Force', $true)
    }
    return $dirParams
}
