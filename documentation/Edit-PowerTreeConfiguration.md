---
external help file: PowerTree-help.xml
Module Name: Show-PowerTree
online version: https://github.com/spaansba/PowerTree
schema: 2.0.0
---

# Edit-PowerTreeConfiguration

## SYNOPSIS

Opens the PowerTree configuration file for editing.

## SYNTAX

```
Edit-PowerTreeConfiguration [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Edit-PowerTreeConfiguration is a utility cmdlet that manages your PowerTree and PowerTreeRegistry configuration file. It automatically locates or creates the configuration file and opens it in the appropriate editor for your operating system.

## EXAMPLES

### Example 1: Open configuration file

```powershell
PS C:\> Edit-PowerTreeConfiguration
```

Opens the PowerTree configuration file in the default editor. If no configuration file exists, creates a new one with default settings.

## NOTES

**Configuration File Location:**

- **Windows:** `$env:USERPROFILE\.PowerTree\config.json`
- **macOS/Linux:** `$HOME/.PowerTree/config.json`

**Default Editor Behavior:**

- **Windows:** Opens with the system default application for JSON files
- **macOS:** Uses the `open` command to launch the default editor
- **Linux:** Attempts to use `xdg-open`, `nano`, `vim`, or `vi` in that order

**Configuration File Structure:**

```
{
  "FileSystem": {
    "MaximumDepth": -1,
    "Files": {
      "IncludeExtensions": [],
      "ExcludeExtensions": [],
      "FileSizeMaximum": "-1kb",
      "FileSizeMinimum": "-1kb"
    },
    "Sorting": {
      "By": "Name",
      "SortFolders": false
    },
    "HumanReadableSizes": true,
    "ExcludeDirectories": []
  },
  "Registry": {
    "MaximumDepth": -1,
    "DisplayValues": false,
    "ExcludeKeys": []
  },
  "Shared": {
    "LineStyle": "unicode",
    "ShowExecutionStats": true,
    "ShowConfigurations": true,
    "ShowConnectorLines": true,
    "OpenOutputFileOnFinish": true
  }
}
```

**Configuration Options**

| Option                               | Description                                                  | Default     | Overridden By                     |
| ------------------------------------ | ------------------------------------------------------------ | ----------- | --------------------------------- |
| `FileSystem.MaximumDepth`            | Maximum directory depth to traverse (-1 = unlimited)         | `-1`        | `-Depth` parameter                |
| `FileSystem.ExcludeDirectories`      | Standard directories to always exclude                       | `[]`        | `-ExcludeDirectories` parameter   |
| `FileSystem.HumanReadableSizes`      | Show sizes as KB/MB/GB instead of raw bytes                  | `true`      | Configuration file only           |
| `FileSystem.Files.IncludeExtensions` | Only show files with these extensions (empty = all files)    | `[]`        | `-IncludeExtensions` parameter    |
| `FileSystem.Files.ExcludeExtensions` | Hide files with these extensions                             | `[]`        | `-ExcludeExtensions` parameter    |
| `FileSystem.Files.FileSizeMinimum`   | Hide files smaller than this size (-1kb = no limit)          | `"-1kb"`    | `-FileSizeMinimum` parameter      |
| `FileSystem.Files.FileSizeMaximum`   | Hide files larger than this size (-1kb = no limit)           | `"-1kb"`    | `-FileSizeMaximum` parameter      |
| `FileSystem.Sorting.By`              | Default sort method ("Name", "Size", "Date", etc.)           | `"Name"`    | `-Sort` and `-SortBy*` parameters |
| `FileSystem.Sorting.SortFolders`     | Apply sorting to directories (false = folders first)         | `false`     | Configuration file only           |
| `Registry.MaximumDepth`              | Maximum registry depth to traverse (-1 = unlimited)          | `-1`        | `-Depth` parameter                |
| `Registry.DisplayValues`             | Show registry value data (can be verbose)                    | `false`     | `-DisplayValues` parameter        |
| `Registry.ExcludeKeys`               | Registry keys to always exclude                              | `[]`        | `-ExcludeKeys` parameter          |
| `Shared.LineStyle`                   | Tree connector style ("unicode" for ├── or "ascii" for \|--) | `"unicode"` | Configuration file only           |
| `Shared.ShowExecutionStats`          | Display timing and file count statistics                     | `true`      | Configuration file only           |
| `Shared.ShowConfigurations`          | Display active configuration at start                        | `true`      | Configuration file only           |
| `Shared.ShowConnectorLines`          | Show tree connector lines                                    | `true`      | Configuration file only           |
| `Shared.OpenOutputFileOnFinish`      | Automatically open output file when using -OutFile           | `true`      | Configuration file only           |

## RELATED LINKS

[PowerTree GitHub Repository](https://github.com/spaansba/PowerTree)

[Show-PowerTree](Show-PowerTree.md)

[Show-PowerTreeRegistry](Show-PowerTreeRegistry.md)
