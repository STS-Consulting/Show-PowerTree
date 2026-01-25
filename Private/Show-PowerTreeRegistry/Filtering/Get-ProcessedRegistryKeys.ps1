
function Get-ProcessedRegistryKeys {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath,
        [Parameter(Mandatory = $false)]
        [string[]]$Exclude,
        [Parameter(Mandatory = $false)]
        [bool]$HasKeyFilters,
        [Parameter(Mandatory = $false)]
        [bool]$DisplayItemCounts
    )

    $childKeys = Get-ChildItem -LiteralPath $RegistryPath -Name -ErrorAction SilentlyContinue
    if (-not $childKeys) {
        return @()
    }

    # Apply exclude filters to child keys only if needed
    if ($HasKeyFilters) {
        $filteredChildKeys = @()
        foreach ($key in $childKeys) {
            if (-not (Test-FilterMatch -ItemName $key -Patterns $Exclude)) {
                $filteredChildKeys += $key
            }
        }
    } else {
        $filteredChildKeys = $childKeys
    }

    $keyItems = @()
    foreach ($key in $filteredChildKeys) {
        $keyPath = Join-Path $RegistryPath $key
        $keyItem = [PSCustomObject]@{
            TypeName = 'Key'
            Name     = $key
            Path     = $keyPath
            IsLast   = $false
        }

        # Only calculate counts if needed
        if ($DisplayItemCounts) {
            $keyItem | Add-Member -NotePropertyName 'ValueCount' -NotePropertyValue $(if ((Get-Item -LiteralPath $keyPath -ErrorAction SilentlyContinue)) { (Get-Item -LiteralPath $keyPath).ValueCount } else { 0 })
            $keyItem | Add-Member -NotePropertyName 'SubKeyCount' -NotePropertyValue $((Get-ChildItem -LiteralPath $keyPath -ErrorAction SilentlyContinue | Measure-Object).Count)
        }

        $keyItems += $keyItem
    }

    return $keyItems
}
