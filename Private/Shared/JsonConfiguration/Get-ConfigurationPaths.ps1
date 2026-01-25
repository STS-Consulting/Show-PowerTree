function Get-ConfigurationPaths {
    [CmdletBinding()]
    param()

    return @(
        "$PSScriptRoot\PowerTree.config.json",
        "$PSScriptRoot\..\PowerTree.config.json",
        "$PSScriptRoot\..\..\PowerTree.config.json",
        "$env:USERPROFILE\.PowerTree\PowerTree.config.json",
        "$env:USERPROFILE\.Settings\PowerTree\PowerTree.config.json",
        "$env:HOME\.PowerTree\PowerTree.config.json"
    )
}
