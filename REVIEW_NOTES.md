# Runtime Review Notes

Items identified during the current static review that still need follow-up:

- Page drag-and-drop and Move Up / Move Down logic has been corrected, but should still be verified in a real WPF session.
- Device Flow text can still be entered with inconsistent whitespace. A future cleanup should normalize flow text and reject malformed or repeated workflow entries.
- Developer Mode still uses the prototype password in source. Replace this before production deployment.
- `Traveler.ps1` still contains functions later overridden by `TravelerRules.ps1` and `ExcelCompiler.ps1`. Once runtime behavior is confirmed, consolidate the final implementations to remove duplicate definitions.
- Registry IDs are currently generated from the registry count. This is acceptable while registries are append-only, but a future cleanup should generate the next unused ID explicitly.
- Full WPF interaction and Microsoft Excel COM compilation still require regression testing on the target Windows Master PC.
