# Flashing the T-Deck (Portable Client)

## Prerequisites

- LilyGo T-Deck (ESP32-S3)
- USB-C cable
- Linux host with esptool installed

## Install esptool

```bash
pip3 install esptool --break-system-packages
```

## Download Firmware

The T-Deck uses a pre-built firmware binary from the MeshCore releases.

```bash
# Download latest companion BLE firmware for T-Deck
curl -sL "https://github.com/meshcore-dev/MeshCore/releases/download/companion-v1.12.0/LilyGo_TDeck_companion_radio_ble-v1.12.0-e738a74-merged.bin" \
  -o LilyGo_TDeck_companion_radio_ble-v1.12.0-merged.bin
```

Or use the flash script from this repo:

```bash
./scripts/flash-tdeck.sh /dev/ttyACM0
```

## Flash

1. Connect T-Deck via USB
2. Put it into bootloader mode: **Hold BOOT button while pressing RST**
3. Flash:

```bash
esptool --port /dev/ttyACM0 --baud 921600 --chip esp32s3 \
  write_flash 0x0 LilyGo_TDeck_companion_radio_ble-v1.12.0-merged.bin
```

The device will reboot automatically after flashing.

## Initial Setup

### Option A: Standalone (T-Deck only)

The T-Deck has a built-in keyboard and display. After flashing:

1. The device boots and shows the MeshCore UI
2. Use the keyboard to navigate menus
3. Set your frequency to **868.0 MHz** (EU)
4. Set your node name
5. Send a "Flood Routed Advertisement" to announce yourself on the mesh

### Option B: With Phone App

1. Install the MeshCore app:
   - [Android (Google Play)](https://play.google.com/store/apps/details?id=nz.meshcore.app)
   - [iOS (App Store)](https://apps.apple.com/app/meshcore/id6740226514)
2. Enable Bluetooth on your phone
3. Open MeshCore app and scan for devices
4. Pair with the T-Deck using PIN **123456**
5. Configure via the app:
   - Set frequency to 868.0 MHz
   - Set node name
   - Set location (optional)
   - Send advertisement

### Option C: Web Config Tool

For repeater/room-server firmware, use the web config tool:
- https://config.meshcore.dev/

## Messaging

Once both T-Deck and T-Beam are configured on the same frequency:

1. **T-Deck** sends a "Flood Routed Advertisement"
2. **T-Beam** (relay) receives and re-broadcasts the advertisement
3. Other nodes discover the T-Deck
4. Direct encrypted messaging is now possible

Messages are end-to-end encrypted using public key cryptography.

## Available Firmware Types for T-Deck

| Firmware | Use Case |
|----------|----------|
| `companion_radio_ble` | Standalone + BLE phone app (recommended) |
| `companion_radio_usb` | USB serial connection to computer |
| `repeater` | Headless relay (wastes the keyboard/display) |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't enter bootloader | Hold BOOT before/during RST press |
| esptool can't find device | Check `ls /dev/ttyACM*`, try different USB port |
| Display stays blank | Wait 10-15s after flash, try RST button |
| BLE not pairing | Default PIN is 123456, restart both devices |
| No mesh nodes visible | Check both devices on same frequency (868 MHz) |
