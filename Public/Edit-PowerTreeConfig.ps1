function Edit-PowerTreeConfig {
    <#
    .SYNOPSIS
        Opens the PowerTree configuration file in the default editor.

    .DESCRIPTION
        The Edit-PowerTreeConfig cmdlet (alias 'Edit-PowerTree', 'Edit-Ptree') finds or creates the
        'config.json' file for PowerTree and opens it. If the file does not exist, it creates a default one.

    .EXAMPLE
        Edit-PowerTreeConfig
        Opens the local or user-profile config.json file.
    #>
    [CmdletBinding()]
    param()

    $configPaths = Get-ConfigPaths
    $existingConfig = $configPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($existingConfig) {
        $configPath = $existingConfig
    } else {
        if ($IsWindows -or $null -eq $IsWindows) {
            $configDir = Join-Path -Path $env:USERPROFILE -ChildPath '.PowerTree'
        } else {
            $configDir = Join-Path -Path $env:HOME -ChildPath '.PowerTree'
        }

        if (-not (Test-Path -Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Created directory: $configDir$($PSStyle.Reset)" -InformationAction Continue
        }

        $configPath = Join-Path -Path $configDir -ChildPath 'config.json'
    }

    $configExists = Test-Path -Path $configPath

    if (-not $configExists) {
        try {
            $configDir = Split-Path -Parent $configPath
            if (-not (Test-Path -Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Created directory: $configDir$($PSStyle.Reset)" -InformationAction Continue
            }

            $defaultConfig = Get-DefaultConfig
            $defaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8

            Write-Information -MessageData "$($PSStyle.Foreground.Green)Created new config file at: $configPath$($PSStyle.Reset)" -InformationAction Continue
        } catch {
            Write-Error "Failed to create config file: $PSItem"
            return
        }
    } else {
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using existing config file: $configPath$($PSStyle.Reset)" -InformationAction Continue
    }

    try {
        $resolvedPath = Resolve-Path $configPath -ErrorAction Stop

        if ($IsWindows -or $null -eq $IsWindows) {
            Start-Process $resolvedPath
        } elseif ($IsMacOS) {
            Start-Process 'open' -ArgumentList $resolvedPath
        } elseif ($IsLinux) {
            $editors = @('xdg-open', 'nano', 'vim', 'vi')
            $editorOpened = $false

            foreach ($editor in $editors) {
                try {
                    Start-Process $editor -ArgumentList $resolvedPath -ErrorAction Stop
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
