# MPS E-Traveler

Offline Windows desktop application for maintaining device traveler configurations and compiling Excel 97-2003 (`.xls`) traveler workbooks.

## Features

- Register Device + Die configurations
- Maintain Device Flow definitions
- Configure Site, Tester, Handler, Baking and Golden Sample settings
- Link traveler pages directly to external `.xls` files
- Reorder traveler pages
- Select template folders with the Windows folder picker
- Compile final `.xls` travelers through Microsoft Excel
- View all Die configurations registered under the same Device
- Developer-mode access control for maintenance functions

## Requirements

- Windows x64
- Windows PowerShell 5.1 or later
- Microsoft Excel desktop

## Source layout

- `src/E-Traveler.ps1` — application entry point
- `src/Modules/AppShell.ps1` — WPF shell and main layout
- `src/Modules/Data.ps1` — local state and data model
- `src/Modules/Traveler.ps1` — traveler rules and Excel compiler
- `src/Modules/TemplateSetup.ps1` — template-folder and setup dialogs
- `src/Modules/PageEditor.ps1` — page assignment and ordering
- `src/Modules/DeviceDialogs.ps1` — Device/Die and Device Flow dialogs
- `src/Modules/Main.ps1` — application event wiring

## Local data

Runtime data is stored locally beside the application. Template folders and traveler page files remain external and are referenced by their Windows paths.

The repository does not include production Device, traveler, template-folder or worksheet data.
