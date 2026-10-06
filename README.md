# MPS E-Traveler

Windows desktop application for maintaining and compiling Final Test e-travelers from controlled Excel 97-2003 (`.xls`) page templates.

## Current release

**3.0.0**

The current repository is intentionally kept to the production baseline. Previous development packages are not kept in the working tree.

## Source package

The complete Visual Studio / .NET 8 source is provided in:

```text
MPS_ETraveler_3.0.0_Source.zip
```

Extract the archive to get the solution, WPF application source, self-test project, build script and deployment launcher.

## Main functions

- Device + Die configuration
- Workflow-specific traveler setup
- Shared template families by Workflow + Tester + Handler
- Site-specific `HW_INFO` and `SOCKET_INFO`
- Conditional Baking and Golden Sample pages
- Common page add / remove / reorder
- Stable page identity and source mapping
- Traveler review and Excel preview / compile
- SQLite shared configuration database
- Single-user server lock
- Developer-mode protected maintenance

## Technology

- C# / .NET 8
- Windows Presentation Foundation (WPF)
- SQLite
- Microsoft Excel COM Automation

## Build

On the Admin / Build PC:

```bat
BUILD_FINAL_SERVER_PACKAGE.cmd
```

A successful build creates `SERVER_PACKAGE` for engineer use.

Normal engineer launch:

```text
SERVER_PACKAGE\MPS E-Traveler.cmd
```

## Documentation

- `docs/USER_GUIDE.md` — operating guide
- `SECURITY_AND_DEPLOYMENT.txt` — deployment and permission guidance

## Page identity model

- `SlotId` = permanent source identity
- `RegularNo` = permanent visible regular-page identity
- `Position` = current traveler order

Moving a page changes its position only. A page keeps its page identity and its assigned `.xls` source after reordering.
