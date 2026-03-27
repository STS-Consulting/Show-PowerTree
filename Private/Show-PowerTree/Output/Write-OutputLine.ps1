function Write-OutputLine {
    [CmdletBinding()]
    param (
        [string]$Line,
        [System.Text.StringBuilder]$OutputBuilder
    )
    if ($null -ne $OutputBuilder) {
        [void]$OutputBuilder.AppendLine($Line)
    } else {
        Microsoft.PowerShell.Utility\Write-Information -MessageData $Line -InformationAction Continue
    }
}
