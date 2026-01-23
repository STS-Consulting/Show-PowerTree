
function Write-HeaderToOutput {
    [CmdletBinding()]
    param(
        [hashtable]$HeaderTable,
        [System.Text.StringBuilder]$OutputBuilder,
        [hashtable]$LineStyle
    )

    if ($null -ne $OutputBuilder) {
        [void]$OutputBuilder.AppendLine($HeaderTable.HeaderLine)
        [void]$OutputBuilder.AppendLine($HeaderTable.UnderscoreLine)
    } else {
        if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
            # Use PSStyle for PowerShell 7+
            $headerColor = $global:PSStyle.Formatting.TableHeader
            $resetColor = $global:PSStyle.Reset

            Write-Host "$headerColor$($HeaderTable.HeaderLine)$resetColor"
            Write-Host "$headerColor$($HeaderTable.UnderscoreLine)$resetColor"
        } else {
            # Fallback for older versions or if PSStyle is not available
            Write-Host $HeaderTable.HeaderLine -ForegroundColor Magenta
            Write-Host $HeaderTable.UnderscoreLine
        }
    }
}
