function Write-ConfigurationToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )

    $outFile = $Configuration.OutFile
    $configurationData = @()

    # Don't show configuration if we're outputting to a file
    if (-not [string]::IsNullOrEmpty($outFile)) {
        return
    }

    if ($Configuration -is [TreeRegistryConfig]) {
        $configurationData = Get-RegistryConfigurationData -TreeRegistryConfiguration $Configuration
        $lineStyle = $Configuration.LineStyle.SingleLine
    } elseif ($Configuration -is [TreeConfig]) {
        $configurationData = Get-TreeConfigurationData -TreeConfiguration $Configuration
        $lineStyle = '─'
    } else {
        Write-Error 'Invalid configuration type. Expected TreeConfig or TreeRegistryConfig.' -ErrorAction Stop
    }

    Write-Information -MessageData ' ' -InformationAction Continue
    if ($null -ne $global:PSStyle -and $null -ne $global:PSStyle.Formatting -and $null -ne $global:PSStyle.Formatting.TableHeader) {
        $headerColor = $global:PSStyle.Formatting.TableHeader
        $configurationColor = $global:PSStyle.Foreground.Green
        $resetColor = $global:PSStyle.Reset

        Write-Information -MessageData "$headerColor`Configuration$resetColor" -InformationAction Continue
        Write-Information -MessageData "$headerColor$($lineStyle * 13)$resetColor" -InformationAction Continue
        Write-Verbose -Message 'Some settings might be sourced from the configuration file (.config.json)'

        # Display configuration data
        foreach ($configurationLine in $configurationData) {
            Write-Information -MessageData "$configurationColor$configurationLine$resetColor" -InformationAction Continue
        }
    } else {
        # Fallback to plain text if PSStyle is somehow missing (though unlikely in PS 7.5+)
        Write-Information -MessageData 'Configuration' -InformationAction Continue
        Write-Information -MessageData ($lineStyle * 13) -InformationAction Continue
        Write-Verbose -Message 'Some settings might be sourced from the configuration file (.config.json)'

        # Display configuration data
        foreach ($configurationLine in $configurationData) {
            Write-Information -MessageData $configurationLine -InformationAction Continue
        }
    }

    Write-Information -MessageData ' ' -InformationAction Continue
}
