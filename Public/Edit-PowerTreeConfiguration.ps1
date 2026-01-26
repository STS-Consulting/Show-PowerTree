function Edit-PowerTreeConfiguration {
    <#
    .SYNOPSIS
        Opens the PowerTree configuration file in the default editor.

    .DESCRIPTION
        The Edit-PowerTreeConfiguration cmdlet (alias 'Edit-PowerTree', 'Edit-Ptree') finds or creates the
        'config.json' configuration file for PowerTree and opens it. If the file does not exist, it creates a default one.

    .EXAMPLE
        Edit-PowerTreeConfiguration
        Opens the local or user-profile configuration file (config.json).
    #>
    [CmdletBinding()]
    param()

    $configurationPaths = Get-ConfigurationPaths
    $existingConfiguration = $configurationPaths | Where-Object { Test-Path $PSItem } | Select-Object -First 1

    if ($existingConfiguration) {
        $configurationPath = $existingConfiguration
    } else {
        if ($IsWindows -or $null -eq $IsWindows) {
            $configurationDirectory = Join-Path -Path $env:USERPROFILE -ChildPath '.PowerTree'
        } else {
            $configurationDirectory = Join-Path -Path $env:HOME -ChildPath '.PowerTree'
        }

        if (-not (Test-Path -Path $configurationDirectory)) {
            New-Item -Path $configurationDirectory -ItemType Directory -Force | Out-Null
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Created directory: $configurationDirectory$($PSStyle.Reset)" -InformationAction Continue
        }

        $configurationPath = Join-Path -Path $configurationDirectory -ChildPath 'config.json'
    }

    $configurationExists = Test-Path -Path $configurationPath

    if (-not $configurationExists) {
        try {
            $configurationDirectory = Split-Path -Parent $configurationPath
            if (-not (Test-Path -Path $configurationDirectory)) {
                New-Item -Path $configurationDirectory -ItemType Directory -Force | Out-Null
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Created directory: $configurationDirectory$($PSStyle.Reset)" -InformationAction Continue
            }

            $defaultConfiguration = Get-DefaultConfiguration
            $defaultConfiguration | ConvertTo-Json -Depth 4 | Out-File -FilePath $configurationPath -Encoding utf8

            Write-Information -MessageData "$($PSStyle.Foreground.Green)Created new configuration file at: $configurationPath$($PSStyle.Reset)" -InformationAction Continue
        } catch {
            Write-Error "Failed to create configuration file: $PSItem" -ErrorAction Stop
        }
    } else {
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using existing configuration file: $configurationPath$($PSStyle.Reset)" -InformationAction Continue
    }

    try {
        $resolvedPath = Resolve-Path $configurationPath -ErrorAction Stop

        if ($IsWindows -or $null -eq $IsWindows) {
            Start-Process -FilePath $resolvedPath
        } elseif ($IsMacOS) {
            Start-Process 'open' -ArgumentList $resolvedPath
        } elseif ($IsLinux) {
            $editors = @('xdg-open', 'nano', 'vim', 'vi')
            $editorOpened = $false

            foreach ($editor in $editors) {
                try {
                    Start-Process -FilePath $editor -ArgumentList $resolvedPath -ErrorAction Stop
                    $editorOpened = $true
                    break
                } catch {
                    continue
                }
            }

            if (-not $editorOpened) {
                Write-Warning "Could not open editor. Please manually edit: $resolvedPath"
            }
        }
    } catch {
        Write-Warning "Could not open file: $PSItem"
    }
}
