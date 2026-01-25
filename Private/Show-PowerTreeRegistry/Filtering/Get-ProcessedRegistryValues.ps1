
function Get-ProcessedRegistryValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$RegKey,
        [Parameter(Mandatory = $false)]
        [hashtable]$RegistryTypeMap,
        [Parameter(Mandatory = $false)]
        [bool]$UseRegistryDataTypes,
        [Parameter(Mandatory = $false)]
        [string[]]$Include,
        [Parameter(Mandatory = $false)]
        [string[]]$Exclude,
        [Parameter(Mandatory = $false)]
        [bool]$HasValueFilters
    )

    $valueItems = @()

    foreach ($valueName in $RegKey.GetValueNames()) {
        $valueType = $RegKey.GetValueKind($valueName)
        $displayName = if ($valueName -eq '') { '(Default)' } else { $valueName }
        $value = $RegKey.GetValue($valueName)

        # Apply include/exclude filters only if needed
        if ($HasValueFilters) {
            $shouldInclude = ($Include.Count -eq 0) -or (Test-FilterMatch -ItemName $displayName -Patterns $Include)
            $shouldExclude = Test-FilterMatch -ItemName $displayName -Patterns $Exclude

            if (-not $shouldInclude -or $shouldExclude) {
                continue
            }
        }

        # Choose between PowerShell type or Registry type
        $displayType = if ($UseRegistryDataTypes) {
            $RegistryTypeMap[$valueType.ToString()]
        } else {
            $valueType.ToString()
        }

        $valueItems += [PSCustomObject]@{
            TypeName = $displayType
            Name     = $displayName
            Value    = $value
            IsLast   = $false
        }
    }

    return $valueItems
}
