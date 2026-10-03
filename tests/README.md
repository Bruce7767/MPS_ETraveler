# Regression checks

`logic-check.ps1` covers the non-UI rules that can be checked without Microsoft Excel or an interactive WPF desktop session.

Current checks include:

- local state save and previous-state backup
- exact registry matching
- Baking and Golden Sample page rules
- Device Flow traveler preservation
- new workflow entries starting without a registry assignment

WPF interaction and Excel COM compilation are tested separately on the target Windows machine.
