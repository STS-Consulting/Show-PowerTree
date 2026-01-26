function Format-FileExtensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Extensions
    )

    $formattedExtensions = @()

    foreach ($currentExtension in $Extensions) {
        if ([string]::IsNullOrWhiteSpace($currentExtension)) { continue }

        $extension = $currentExtension.Trim().ToLower()

        if ($extension.StartsWith('*.')) {
            # Already in correct format (*.extension)
            $formattedExtensions += $extension
        } elseif ($extension.StartsWith('.')) {
            # If it starts with a dot, prepend *
            $formattedExtensions += "*$extension"
        } elseif ($extension.StartsWith('*')) {
            # If it starts with * but not with *., insert a dot after *
            $formattedExtensions += "*.$($extension.Substring(1))"
        } else {
            # Otherwise, prepend "*."
            $formattedExtensions += "*.$extension"
        }
    }

    return $formattedExtensions
}
