# MPS E-Traveler User Guide

## 1. Start the application

Normal users should open:

```text
SERVER_PACKAGE\MPS E-Traveler.cmd
```

The launcher copies/refreshes the local runtime and connects it back to the shared server data.

## 2. Select Device / Die

1. Search the device name.
2. Select the correct Die when more than one configuration exists.
3. Select the required workflow traveler.

## 3. Edit Setup

Maintain the runtime conditions for the selected traveler:

- Site
- Tester
- Handler
- Baking Required / Not Required
- Golden Sample Required / Not Required
- Template Folder

Shared template identity is based on **Workflow + Tester + Handler**. Site, Baking and Golden Sample remain traveler-specific conditions.

## 4. Edit Pages

Use **Edit Pages** to maintain traveler page sources and order.

Available actions:

- Choose / Replace `.xls`
- Open Page `.xls`
- Add Common Page
- Remove Page (regular/common pages only)
- Move Up / Move Down
- Drag from the dedicated handle
- Save Changes

### Page identity

Regular/common pages keep a stable page identity:

- `SlotId` = permanent source identity
- `RegularNo` = permanent visible page identity
- `Position` = current traveler order

Moving Page 3 changes only its position. Page 3 remains Page 3 and keeps the same source file.

`HW_INFO`, `SOCKET_INFO`, Golden Sample and Baking do not consume regular Page numbers.

## 5. Review and compile

Before compiling:

1. Open **View .xls / Traveler Review**.
2. Check Device / Die / Workflow.
3. Check Site, Tester, Handler, Baking and Golden Sample.
4. Verify active page order and source paths.
5. Open individual pages when required.
6. Preview the combined traveler when required.
7. Compile the final Excel 97-2003 `.xls` file.

## 6. Template location

Templates can be stored anywhere that all intended users can access. A central shared path is recommended, for example:

```text
\\Server\MPS E-Traveler\Templates\
```

Avoid personal local folders for production templates because other users may not have the same path.

## 7. Basic troubleshooting

- If the application does not start, confirm you are launching from `SERVER_PACKAGE`.
- If another user is active, wait for that session to close and retry.
- If a page cannot open, confirm the `.xls` file still exists and the network path is reachable.
- If startup still fails, run `SERVER_PACKAGE\_Support\Diagnostic.cmd` and capture the output.
