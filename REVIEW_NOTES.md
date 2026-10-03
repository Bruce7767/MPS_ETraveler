# Runtime Review Notes

Items identified during the current static review that are intentionally not changed in this reliability patch:

- Page drag-and-drop should be verified on a real WPF session. The current mouse-down handler uses the selected list item and may need hit-testing if dragging a newly clicked item behaves inconsistently.
- Device Flow text can still be entered with inconsistent whitespace. A future cleanup should normalize flow text and reject malformed or repeated workflow entries.
- Developer Mode still uses the prototype password in source. Replace this before production deployment.
- `Traveler.ps1` still contains functions later overridden by `TravelerRules.ps1` and `ExcelCompiler.ps1`. Once runtime behavior is confirmed, consolidate the final implementations to remove duplicate definitions.
- Existing template-folder path maintenance should be moved into the Developer-controlled setup screen if routine folder reassignment is required. The normal `Open Folder` action now opens the configured folder directly.
- Full WPF interaction and Microsoft Excel COM compilation still require regression testing on the target Windows Master PC.
