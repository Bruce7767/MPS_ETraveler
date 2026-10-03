# MPS E-Traveler

Windows desktop utility for maintaining Device/Die traveler configurations and compiling legacy Excel `.xls` traveler workbooks.

## What it does

- Registers Device and Die configurations
- Maintains Device Flow definitions
- Configures Site, Tester, Handler, Baking and Golden Sample settings
- Links each traveler page to an external `.xls` source file
- Reorders traveler pages before compilation
- Opens template folders with the Windows folder picker
- Compiles final Excel 97-2003 traveler workbooks through Microsoft Excel
- Lists all Die configurations registered under the same Device
- Protects maintenance functions with Developer Mode

## Requirements

- Windows x64
- Windows PowerShell 5.1 or later
- Microsoft Excel desktop

## Project structure

```text
src/
├─ E-Traveler.ps1
└─ Modules/
   ├─ AppShell.ps1
   ├─ Data.ps1
   ├─ Traveler.ps1
   ├─ TemplateSetup.ps1
   ├─ PageEditor.ps1
   ├─ DeviceDialogs.ps1
   └─ Main.ps1
```

Runtime data is stored locally. Traveler templates and page files stay outside the application and are referenced by their Windows paths.

Production Device, traveler and worksheet data are not included in this repository.
