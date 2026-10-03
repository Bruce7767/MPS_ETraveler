# MPS E-Traveler

Windows desktop utility for maintaining Device/Die traveler configurations and compiling legacy Excel `.xls` traveler workbooks.

## What it does

- Registers Device and Die configurations
- Maintains Device Flow definitions
- Configures Site, Tester, Handler, Baking and Golden Sample settings
- Links each traveler page directly to an external `.xls` source file
- Reorders traveler pages before compilation
- Compiles final Excel 97-2003 traveler workbooks through Microsoft Excel
- Opens compiled travelers in Excel Read-Only mode
- Lists Device/Die configurations without silently choosing an ambiguous Die
- Protects maintenance functions with Developer Mode
- Keeps a previous valid local-data backup for recovery

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
   ├─ TravelerRules.ps1
   ├─ ExcelCompiler.ps1
   ├─ TemplateSetup.ps1
   ├─ TemplateFolder.ps1
   ├─ PageEditor.ps1
   ├─ DeviceDialogs.ps1
   ├─ DeviceSearch.ps1
   └─ Main.ps1

tests/
└─ logic-check.ps1
```

Runtime data is stored locally. Traveler templates and page files remain external and are referenced by their Windows paths. The application validates state writes and retains the previous valid state as a local backup.

GitHub Actions checks PowerShell syntax and core non-UI traveler rules. Full WPF interaction and Microsoft Excel COM compilation still require testing on the target Windows PC with Excel installed.

Production Device, traveler, template, MES mapping, internal-path and worksheet data are not included in this repository.
