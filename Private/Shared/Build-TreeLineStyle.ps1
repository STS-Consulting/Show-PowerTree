
function Build-TreeLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('ASCII', 'Unicode')]
        [string]$Style
    )

    $lineStyles = @{
        ASCII   = @{
            Branch                  = '+----'
            VerticalLine            = '|   '
            LastBranch              = '\----'
            Vertical                = '|'
            Space                   = '    '
            SingleLine              = '-'
            RegistryHeaderSeparator = '----         ---------'
        }
        Unicode = @{
            Branch                  = '├───'
            VerticalLine            = '│   '
            LastBranch              = '└───'
            Vertical                = '│'
            Space                   = '    '
            SingleLine              = '─'
            RegistryHeaderSeparator = '────         ─────────'
        }
    }

    return $lineStyles[$Style]
}
