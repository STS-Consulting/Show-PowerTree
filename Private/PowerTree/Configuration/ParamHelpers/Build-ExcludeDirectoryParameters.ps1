
function Build-ExcludedDirectoryParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$CommandLineExcludedDirectory = @(),
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )

    $excludedDirectories = @()

    if ($Settings -and $Settings.ExcludeDirectories -and $Settings.ExcludeDirectories.Count -gt 0) {
        $excludedDirectories += $Settings.ExcludeDirectories
    }

    if ($CommandLineExcludedDirectory -and $CommandLineExcludedDirectory.Count -gt 0) {
        foreach ($directory in $CommandLineExcludedDirectory) {
            if ($excludedDirectories -notcontains $directory) {
                # Exclude duplicates
                $excludedDirectories += $directory
            }
        }
    }

    return $excludedDirectories
}
