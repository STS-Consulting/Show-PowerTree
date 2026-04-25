function Write-OutputLine {
    param (
        [string]$Line,
        [System.Text.StringBuilder]$OutputBuilder
    )
    if ($null -ne $OutputBuilder) {
        [void]$OutputBuilder.AppendLine($Line)
    } else {
        Write-Information -MessageData $Line -InformationAction Continue
    }
}
