# Proxmark Studio User Guide

## 1. First Launch

Proxmark Studio looks for a usable Proxmark3 client in this order:

1. The currently selected client recorded in application support
2. A validated embedded client, if one exists in the app bundle
3. A validated system installation in a known package path

If no working client is available, the app stays usable for browsing saved cards and settings, but live device actions remain disabled until you import a working core.

## 2. Import Or Update The Core

Use `Core Options` in the top bar or the `Settings` page to:

- Check for updates
- Install the latest discovered compatible core
- Download the stable channel
- Download the experimental channel
- Import a local core binary

When importing a local client:

- `pm3` wrapper scripts must have their matching `proxmark3` client beside them
- `share/proxmark3` data should stay with the client when available
- Broken clients are rejected if `pm3 --helpclient` or `proxmark3 -h` fails

## 3. Connect To Hardware

1. Connect the Proxmark3 over USB.
2. Hover over controls if you want a description of each action.
3. Click `Refresh Ports`.
4. Confirm the selected serial port. Iceman-style device names are preferred automatically when detected.
5. Click `Connect`.

## 4. Read Cards

Open `Read` to run:

- HF search
- LF search
- EMV scan
- Continuous HF scan
- Continuous LF scan
- Save the current read into the local card library
- Clone the current read into the next free slot

Saved reads appear in `Saved Cards` and can be reused in `Slots` and `Write`.

## 5. Saved Cards

Open `Saved Cards` to:

- Search the local library by label, tag type, UID, or notes
- Import saved-card metadata from file
- Select a card for slot assignment or writing
- Send a card to the next available slot
- Open a card in the write planner
- Delete a card from the library

## 6. Slots

Open `Slots` to manage the eight-slot workspace:

- Activate any slot
- Assign the currently selected saved card to a slot
- Replace an existing slot assignment
- Clear a slot
- Open the assigned card directly in the write planner

The active slot and selected card are shown at the top of the page.

## 7. Write Plans

Open `Write` to:

- Choose a saved card
- Edit one PM3 command per line
- Save the write plan back into the card library
- Append a verification scan automatically
- Assign the card to the next free slot after the plan is queued
- Run the plan through the live PM3 session

The planner shows live status for card selection, command count, and connection state.

## 8. Advanced And Console

Open `Advanced` for guided command-chain building and `Tools & Console` for:

- Live PM3 output
- Manual command entry
- Console clearing
- Quick visibility into HF and LF tool areas

## 9. Troubleshooting

### No core available

- Import a local Proxmark3 client from `Settings` or `Core Options`.
- If a bundled or imported core is rejected, validate it manually with `pm3 --helpclient` or `proxmark3 -h`.

### Device not detected

- Reconnect USB and click `Refresh Ports`.
- Verify the selected `/dev/tty.*` or `/dev/cu.*` path on macOS.
- Disconnect and reconnect from the app.

### Commands appear inactive

- Check `Tools & Console` for PM3 output.
- Confirm the device is connected before starting scans or running a write plan.
- Save the current write plan before running it if you expect commands to persist with the card.

### Online update actions do nothing

- Official online updates require release-feed metadata in the build.
- If no official feed is configured, import a local core instead.
