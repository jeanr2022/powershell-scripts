- [x] Verify that the copilot-instructions.md file in the .github directory is created.
- [x] Clarify Project Requirements - PowerShell script project confirmed
- [x] Scaffold the Project - Created complete PowerShell project structure
- [x] Customize the Project - Added three sample PowerShell scripts with documentation
- [x] Install Required Extensions - No specific extensions required
- [x] Compile the Project - All PowerShell scripts validated successfully
- [x] Create and Run Task - VS Code task created for running Hello World script
- [x] Launch the Project - Project tested and working correctly
- [x] Ensure Documentation is Complete - README.md and documentation finalized

## PowerShell Script Project

This project contains PowerShell scripts for automation and system administration tasks.

### Available Scripts:
- `src/Hello-World.ps1` - Basic greeting and system info script
- `src/Get-SystemInfo.ps1` - Comprehensive system information gathering
- `src/Backup-Files.ps1` - File and directory backup utility

### How to Run:
1. Use the VS Code task: Run "Run Hello World Script" from Command Palette (Ctrl+Shift+P)
2. Or run directly in terminal: `powershell -Command "& '.\src\Hello-World.ps1'"`

### Development Guidelines:
- Follow PowerShell best practices documented in `docs/Development-Guide.md`
- Include comprehensive help documentation for all scripts
- Test scripts using Pester framework in `tests/` directory