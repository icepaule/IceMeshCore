# Flashing the T-Deck (Portable Client)

## Firmware Choice

The T-Deck supports two firmware types:

| Firmware | Maps | Keyboard UI | Source | How to Flash |
|----------|------|-------------|--------|-------------|
| **MeshOS/Ultra** (recommended) | Yes - offline maps | Full CLI + GUI | Closed-source | Web flasher |
| Companion Radio BLE | No | Serial CLI only | Open-source | esptool or PlatformIO |

**This guide uses MeshOS/Ultra** for full map support and the best standalone experience.

## Prerequisites

- LilyGo T-Deck (ESP32-S3 + SX1262)
- USB-C cable
- Chrome or Edge browser (for Web Serial API)
- MicroSD card with map tiles (optional, see [setup-guide.md](setup-guide.md#step-6-offline-map-tiles))

## Flash MeshOS/Ultra via Web Flasher

### Step 1: Open Web Flasher

Go to **[flasher.meshcore.co.uk](https://flasher.meshcore.co.uk/)** in Chrome or Edge.

> **Note**: Firefox and Safari do NOT support Web Serial API.

### Step 2: Select Device and Firmware

1. Select device: **LilyGo T-Deck**
2. Select firmware: **MeshOS** or **Ultra**
3. Select region: **EU 868 MHz**

### Step 3: Connect and Flash

1. Connect T-Deck via USB-C to your computer
2. Click **Flash** / **Connect**
3. Select the serial port when prompted (usually "USB JTAG/serial debug unit")
4. Wait for flashing to complete (~30 seconds)
5. T-Deck will reboot automatically

### Step 4: Verify Boot

After reboot, the T-Deck shows:

```
===== MeshCore Chat Terminal =====

WELCOME  NONAME
<public key>
   (enter '/help' for commands)
```

## Initial Configuration

Connect via serial terminal (115200 baud) or use the T-Deck's physical keyboard:

```bash
picocom -b 115200 /dev/ttyACM0
```

### Set Device Name

```
/set name YourName
```

### Configure EU Radio Settings

These must match your T-Beam's settings:

```
/set freq 869.618
/set sf 10
/set bw 62.5
/set cr 5
/set tx 22
```

### Enable GPS

```
/gps on
```

### Enable Mobile Repeater

Allows your T-Deck to relay messages for others:

```
/mobrep
```

### Reboot to Apply Radio Settings

Press the reset button or disconnect/reconnect USB. Then verify:

```
/get radio
```

Expected output:
```
  Radio Settings:
    Frequency: 869.618 MHz
    Spreading Factor: SF10
    Bandwidth: 62.5 kHz
    Coding Rate: 4/5
    TX Power: 22 dBm
```

## SD Card for Offline Maps

MeshOS supports offline map tiles on MicroSD:

1. Format SD card as **FAT32**
2. Create tile structure: `/tiles/{z}/{x}/{y}.png`
3. See [setup-guide.md](setup-guide.md#step-6-offline-map-tiles) for the download script
4. Insert SD card into T-Deck
5. Verify: `/sd` and `/sd ls /tiles`

## Available Commands

Type `/help` on the T-Deck for a full list. Key commands:

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/get radio` | Display current radio settings |
| `/card` | Show your identity (name + public key) |
| `/public <text>` | Send to Public channel (broadcast) |
| `/to <name>` | Select direct message recipient |
| `/send <text>` | Send direct message |
| `/messages 10` | Show last 10 messages |
| `/list 20` | List known contacts |
| `/repeaters 15` | Scan for repeaters (15 seconds) |
| `/battery` | Battery voltage and charge level |
| `/gps get` | GPS status and position |
| `/memory` | RAM usage statistics |
| `/sd` | SD card status |
| `/channels` | List configured channels |

## Alternative: Flash Open-Source Companion BLE

If you don't need maps, you can flash the open-source companion firmware:

```bash
# Download
curl -sL "https://github.com/meshcore-dev/MeshCore/releases/download/companion-v1.12.0/LilyGo_TDeck_companion_radio_ble-v1.12.0-e738a74-merged.bin" \
  -o tdeck-ble.bin

# Flash (may need to hold BOOT button during RST)
esptool --port /dev/ttyACM0 --baud 921600 --chip esp32s3 \
  write_flash 0x0 tdeck-ble.bin
```

This firmware connects via BLE to the MeshCore phone app (PIN: 123456).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Web flasher can't connect | Use Chrome/Edge, not Firefox. Try different USB port |
| Settings lost after reboot | Set all values, wait 2 seconds, then reboot |
| SD card not detected | Must be FAT32 (not exFAT), max 32 GB recommended |
| GPS no fix | Normal indoors. GPS needs clear sky view for initial fix |
| Radio settings show wrong values | Reboot required after `/set` commands |
| `/sd` shows "Not Mounted" | Re-seat SD card, check FAT32 format |
| Display blank after flash | Press reset button, wait 10 seconds |
