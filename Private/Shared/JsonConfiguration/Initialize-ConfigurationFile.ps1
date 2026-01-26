function Initialize-ConfigurationFile {
    [CmdletBinding()]
    param()

    $configurationPaths = Get-ConfigurationPaths
    $existingConfiguration = $configurationPaths | Where-Object { Test-Path $PSItem } | Select-Object -First 1

    if ($existingConfiguration) {
        Write-Verbose -Message "Using existing configuration file: $existingConfiguration"
        return
    }

    # No configuration file exists, create one
    if ($IsWindows -or $null -eq $IsWindows) {
        $configurationDirectory = Join-Path -Path $env:USERPROFILE -ChildPath '.PowerTree'
    } else {
        $configurationDirectory = Join-Path -Path $env:HOME -ChildPath '.PowerTree'
    }

    if (-not (Test-Path -Path $configurationDirectory)) {
        New-Item -Path $configurationDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose -Message "Created directory: $configurationDirectory"
    }

    $configurationPath = Join-Path -Path $configurationDirectory -ChildPath 'config.json'

    try {
        $defaultConfiguration = Get-DefaultConfiguration
        $defaultConfiguration | ConvertTo-Json -Depth 4 | Out-File -FilePath $configurationPath -Encoding utf8
        Write-Verbose -Message "Created new configuration file at: $configurationPath"
    } catch {
        Write-Warning "Failed to create configuration file: $PSItem"
    }
}
