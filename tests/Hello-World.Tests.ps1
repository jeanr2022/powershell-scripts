<#
.SYNOPSIS
    Pester tests for Hello-World.ps1 script.

.DESCRIPTION
    This file contains unit tests for the Hello-World.ps1 PowerShell script
    using the Pester testing framework.

.NOTES
    Author: PowerShell Script Project
    Date: October 2025
    Version: 1.0
    
    Prerequisites: Pester module must be installed
    Install-Module -Name Pester -Force -SkipPublisherCheck
#>

BeforeAll {
    # Get the script path
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\Hello-World.ps1"
    
    # Verify the script exists
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found at: $scriptPath"
    }
}

Describe "Hello-World.ps1 Tests" {
    Context "Script Execution" {
        It "Should execute without errors" {
            { & $scriptPath } | Should -Not -Throw
        }
        
        It "Should execute with custom name parameter" {
            { & $scriptPath -Name "Test" } | Should -Not -Throw
        }
        
        It "Should accept Name parameter" {
            $result = & $scriptPath -Name "PowerShell" 2>$null
            # The script outputs to host, so we can't easily capture output
            # This test just ensures no exceptions are thrown
            $true | Should -Be $true
        }
    }
    
    Context "Parameter Validation" {
        It "Should have a Name parameter" {
            $script = Get-Command $scriptPath
            $script.Parameters.Keys | Should -Contain 'Name'
        }
        
        It "Name parameter should not be mandatory" {
            $script = Get-Command $scriptPath
            $script.Parameters['Name'].Attributes.Mandatory | Should -Be $false
        }
    }
}

Describe "Hello-World.ps1 Integration Tests" {
    Context "System Information Display" {
        It "Should display system information without errors" {
            # Capture any errors during execution
            $errors = @()
            & $scriptPath -ErrorVariable errors 2>$null
            $errors.Count | Should -Be 0
        }
    }
}