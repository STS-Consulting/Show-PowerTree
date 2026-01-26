function Get-SizeColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    $result = @{
        ConsoleColor = 'Green'
        AnsiColor    = $null
    }

    if ($null -ne $global:PSStyle) {
        $result.AnsiColor = $global:PSStyle.Foreground.Green
    }

    if ($Bytes -ge 100MB) {
        $result.ConsoleColor = 'Red'
        if ($null -ne $global:PSStyle) { $result.AnsiColor = $global:PSStyle.Foreground.Red }
    } elseif ($Bytes -ge 10MB) {
        $result.ConsoleColor = 'DarkYellow'
        if ($null -ne $global:PSStyle) { $result.AnsiColor = $global:PSStyle.Foreground.Yellow }
    } elseif ($Bytes -ge 1MB) {
        $result.ConsoleColor = 'Blue'
        if ($null -ne $global:PSStyle) { $result.AnsiColor = $global:PSStyle.Foreground.Blue }
    } elseif ($Bytes -ge 100KB) {
        $result.ConsoleColor = 'Cyan'
        if ($null -ne $global:PSStyle) { $result.AnsiColor = $global:PSStyle.Foreground.Cyan }
    }

    return [PSCustomObject]$result
}
