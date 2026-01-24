function Format-ExecutionTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.TimeSpan]$ExecutionTime
    )

    switch ($ExecutionTime) {
        { $PSItem.TotalMinutes -gt 1 } {
            '{0} min, {1} sec' -f [math]::Floor($PSItem.Minutes), $PSItem.Seconds
            break
        }
        { $PSItem.TotalSeconds -gt 1 } {
            '{0:0.00} sec' -f $PSItem.TotalSeconds
            break
        }
        default {
            '{0:N0} ms' -f $PSItem.TotalMilliseconds
        }
    }
}
