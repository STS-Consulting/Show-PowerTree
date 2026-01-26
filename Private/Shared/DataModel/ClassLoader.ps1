function Initialize-PowerTreeClasses {
    [CmdletBinding()]
    param()

    # Get the content of the Classes.ps1 file
    $classesPath = Join-Path -Path $PSScriptRoot -ChildPath "Classes.ps1"
    $classesContent = Get-Content -Path $classesPath -Raw

    # Execute the classes definition in the current scope
    . ([ScriptBlock]::Create($classesContent))

    # Force reload by creating test instances
    try {
        # Remove any existing types from the session if they exist
        if ([System.AppDomain]::CurrentDomain.GetAssemblies() |
            Where-Object { $PSItem.GetTypes() | Where-Object { $PSItem.Name -eq 'TreeConfig' } }) {
            Write-Verbose -Message "Existing TreeConfig type found, forcing refresh"
        }

        $null = [TreeConfig]::new()
        $null = [TreeStats]::new()
        Write-Verbose -Message "PowerTree classes initialized successfully"
        return $true
    } catch {
        Write-Error "Failed to initialize PowerTree classes: $PSItem"
        return $false
    }
}

# Run the initialization immediately when this module loads
$null = Initialize-PowerTreeClasses
