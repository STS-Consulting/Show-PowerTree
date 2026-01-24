function Get-OneDriveStatus {
    <#
    .SYNOPSIS
        Determines if a file or folder is OneDrive and its sync state.

    .DESCRIPTION
        Checks file attributes to determine if an item is OneDrive-managed and returns its sync state:
        - OnlineOnly: File exists only in cloud (sparse file attribute or ~Placeholder indicator)
        - LocallyAvailable: File is locally available but may be syncing
        - AlwaysAvailable: File is fully synced/pinned locally
        - NotOneDrive: File is not OneDrive-managed

    .PARAMETER Item
        The FileSystemInfo object to check.

    .OUTPUTS
        String representing the OneDrive status: 'OnlineOnly', 'LocallyAvailable', 'AlwaysAvailable', or 'NotOneDrive'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )

    # First, check if this is in a OneDrive path
    $itemPath = $Item.FullName
    $isInOneDrive = $itemPath -match '([\\\/]OneDrive|OneDrive\s*[-–]\s*)'

    if (-not $isInOneDrive) {
        return 'NotOneDrive'
    }

    # Item is in OneDrive. Now determine sync state.
    # Cloud-filtered files/folders have the ReparsePoint attribute (0x400)
    $isReparsePoint = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

    # Check for sparse file attribute (0x10000) - indicates Online-Only (cloud-only)
    $isSparse = ($Item.Attributes -band 0x10000) -ne 0

    if ($isSparse) {
        return 'OnlineOnly'
    }

    # For OneDrive files/folders without sparse attribute,
    # if reparse point is set, it's part of cloud filter
    # Default to LocallyAvailable for items in OneDrive
    return 'LocallyAvailable'
}
