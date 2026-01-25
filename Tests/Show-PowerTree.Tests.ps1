

Describe 'Show-PowerTree Module' {
    BeforeAll {
        $sut = Join-Path -Path $PSScriptRoot -ChildPath '..\Show-PowerTree.psd1'
        Import-Module -Name $sut -Force -ErrorAction Stop -Scope Global
    }

    Context 'Validation' {
        It 'Can Import Module' {
            $module = Get-Module -Name Show-PowerTree
            $module | Should -Not -BeNullOrEmpty
        }

        It 'Exports Show-PowerTree' {
            Get-Command -Module Show-PowerTree -Name Show-PowerTree | Should -Not -BeNullOrEmpty
        }

        It 'Exports Edit-PowerTreeConfiguration' {
            Get-Command -Module Show-PowerTree -Name Edit-PowerTreeConfiguration | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Execution' {
        It 'Show-PowerTree Runs Without Error' {
            # We use a small depth to avoid long output, and expect it to run
            # We can't easily mock the console output here without more complex mocking,
            # but we can ensure it doesn't throw.
            { Show-PowerTree -Depth 0 } | Should -Not -Throw
        }
    }
}
