function Write-ConfigurationToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    $outFile = $Config.OutFile
    $configData = @()

    # Don't show configuration if we're outputting to a file
    if (-not [string]::IsNullOrEmpty($outFile)) {
        return
    }

    if ($Config -is [TreeRegistryConfig]) {
        $configData = Get-RegistryConfigurationData -TreeRegistryConfig $Config
        $lineStyle = $Config.LineStyle.SingleLine
    } elseif ($Config -is [TreeConfig]) {
        $configData = Get-TreeConfigurationData -TreeConfig $Config
        $lineStyle = '─'
    } else {
        Write-Error 'Invalid configuration type. Expected TreeConfig or TreeRegistryConfig.'
        return
    }

    Write-Information -MessageData ' ' -InformationAction Continue
    if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
        $headerColor = $global:PSStyle.Formatting.TableHeader
        $configColor = $global:PSStyle.Foreground.Green
        $resetColor = $global:PSStyle.Reset

        Write-Information -MessageData "$headerColor`Configuration$resetColor" -InformationAction Continue
        Write-Information -MessageData "$headerColor$($lineStyle * 13)$resetColor" -InformationAction Continue
        Write-Verbose 'Some settings might be sourced from the .config.json file'

        # Display configuration data
        foreach ($configLine in $configData) {
            Write-Information -MessageData "$configColor$configLine$resetColor" -InformationAction Continue
        }
    } else {
        # Fallback to plain text if PSStyle is somehow missing (though unlikely in PS 7.5+)
        Write-Information -MessageData 'Configuration' -InformationAction Continue
        Write-Information -MessageData ($lineStyle * 13) -InformationAction Continue
        Write-Verbose 'Some settings might be sourced from the .config.json file'

        # Display configuration data
        foreach ($configLine in $configData) {
            Write-Information -MessageData $configLine -InformationAction Continue
        }
    }

    Write-Information -MessageData ' ' -InformationAction Continue
}
