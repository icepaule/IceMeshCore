# IceMeshCore - Complete Setup Guide

Step-by-step walkthrough for setting up the complete MeshCore mesh network with Home Assistant integration.

## Prerequisites

### Hardware Required
- **LilyGo T-Beam** (v1.x with SX1276 radio) + USB-C cable
- **LilyGo T-Deck** + USB-C cable
- **MicroSD card** (32 GB recommended, FAT32 formatted) for offline maps
- **Linux PC** (for building firmware and configuration)
- **Home Assistant** instance (for monitoring/messaging dashboard)

### Software Required
- [PlatformIO](https://platformio.org/) (for building T-Beam firmware)
- Python 3 (for tile download script)
- Git
- A serial terminal (picocom, screen, or minicom)

### Network Requirements
- WiFi network that the T-Beam can reach
- Home Assistant accessible from the same network
- (Optional) MQTT broker for message bridging

---

## Step 1: Identify Your T-Beam Radio

> **CRITICAL**: The T-Beam comes with different LoRa radio chips. Using the wrong firmware will fail with `radio init failed: -2`.

| Radio Chip | Frequency | How to Identify |
|------------|-----------|-----------------|
| **SX1276** | 868 MHz (EU) / 915 MHz (US) | Older T-Beam v1.x models, chip labeled "SX1276" |
| **SX1262** | 868 MHz (EU) / 915 MHz (US) | Newer models, chip labeled "SX1262" |

Check the LoRa module on your T-Beam board. The chip markings are visible on the silver RF module.

This guide uses the **SX1276** variant. For SX1262, use the corresponding variant directory in MeshCore.

---

## Step 2: Flash T-Beam (WiFi Companion Radio)

### 2.1 Install PlatformIO

```bash
# Install PlatformIO CLI
pip install platformio

# Verify installation
pio --version
```

### 2.2 Clone MeshCore Source

```bash
mkdir ~/meshcore && cd ~/meshcore
git clone https://github.com/meshcore-dev/MeshCore.git
cd MeshCore
```

### 2.3 Configure WiFi Companion Firmware

Copy the provided config template:

```bash
cp /path/to/IceMeshCore/configs/tbeam_sx1276_wifi.ini \
   variants/lilygo_tbeam_SX1276/platformio.ini
```

**Edit the WiFi credentials** (required!):

```bash
nano variants/lilygo_tbeam_SX1276/platformio.ini
```

Find and replace these lines in the `[env:Tbeam_SX1276_companion_radio_wifi]` section:

```ini
  -D WIFI_SSID='"YOUR_WIFI_SSID"'
  -D WIFI_PWD='"YOUR_WIFI_PASSWORD"'
```

> **Important**: The nested single+double quotes `'"..."'` are required by PlatformIO!

The EU radio settings are already configured in the template:

```ini
  -D LORA_FREQ=869.618      # EU MeshCore standard frequency
  -D LORA_BW=62.5           # Narrow bandwidth for long range
  -D LORA_SF=10             # High spreading factor for long range
  -D LORA_CR=5              # Coding rate 4/5
  -D LORA_TX_POWER=20       # Max for SX1276
```

### 2.4 Build the Firmware

```bash
cd ~/meshcore/MeshCore
pio run -e Tbeam_SX1276_companion_radio_wifi
```

Expected output:
```
RAM:   [=         ]   7.3% (used 95064 bytes from 1310720 bytes)
Flash: [=====     ]  54.5% (used 1071717 bytes from 1966080 bytes)
========================= [SUCCESS] Took 30.27 seconds =========================
```

> **Troubleshooting - DRAM overflow**: If you get a DRAM overflow error, reduce `MAX_CONTACTS` from 100 to 80 or remove `DISPLAY_CLASS`. The ESP32 WiFi stack uses significant RAM.

### 2.5 Connect and Flash

1. Connect T-Beam via USB-C
2. Identify the serial port:
   ```bash
   ls /dev/ttyACM* /dev/ttyUSB*
   ```
   - T-Beam SX1276 typically appears as `/dev/ttyACM0` or `/dev/ttyUSB0`
   - The CH9102 USB chip shows as "USB Single Serial" in `dmesg`

3. Flash:
   ```bash
   pio run -e Tbeam_SX1276_companion_radio_wifi \
       --target upload --upload-port /dev/ttyACM0
   ```

### 2.6 Verify T-Beam is Working

After flashing, the T-Beam will:
1. Initialize the SX1276 radio
2. Connect to your WiFi network
3. Start a TCP server on port 5000
4. Display status on the OLED (if present)

Verify WiFi connectivity:
```bash
# Find the T-Beam's IP (check your router/DHCP server)
ping <T-BEAM-IP>

# Verify TCP port is open
nc -zv <T-BEAM-IP> 5000
```

Expected serial output (115200 baud):
```
Radio initialized
WiFi connecting to YOUR_SSID...
WiFi connected! IP: 192.168.1.50
TCP server started on port 5000
GPS detected
```

> **Troubleshooting - WiFi not connecting**:
> - `status=1` (WL_NO_SSID_AVAIL): SSID not found. Double-check the exact SSID spelling and ensure the T-Beam is in WiFi range.
> - `status=4` (WL_CONNECT_FAILED): Wrong password.
> - `status=6` (WL_DISCONNECTED): Temporary, will retry.
> - Add `-D WIFI_DEBUG_LOGGING=1` to build flags for detailed WiFi debug output.

> **Troubleshooting - radio init failed: -2**:
> You have the wrong radio variant! Check if your T-Beam has SX1276 or SX1262 and use the matching firmware.

---

## Step 3: Flash T-Deck (MeshOS/Ultra)

The T-Deck runs MeshOS/Ultra firmware which includes:
- Full mesh messaging with keyboard input
- Offline map rendering (requires SD card with tiles)
- GPS tracking and display
- Contact management
- Channel messaging

### 3.1 Flash via Web Flasher

> MeshOS/Ultra is closed-source and can only be flashed via the official web flasher.

1. Open **[flasher.meshcore.co.uk](https://flasher.meshcore.co.uk/)** in Chrome/Edge (requires Web Serial API)
2. Connect T-Deck via USB-C to the computer with the browser
3. Select device: **LilyGo T-Deck**
4. Select firmware: **MeshOS / Ultra**
5. Select region: **EU 868 MHz**
6. Click **Flash**
7. Select the serial port when prompted
8. Wait for flashing to complete (~30 seconds)

### 3.2 Initial T-Deck Boot

After flashing, the T-Deck will show:
```
===== MeshCore Chat Terminal =====

WELCOME  NONAME
<public key hash>
   (enter '/help' for commands)
```

---

## Step 4: Configure T-Deck

Connect the T-Deck via USB and open a serial terminal (115200 baud):

```bash
picocom -b 115200 /dev/ttyACM0
# or
screen /dev/ttyACM0 115200
```

### 4.1 Set Device Name

```
/set name YourName
```

### 4.2 Configure Radio Settings

These **must match** the T-Beam settings for communication:

```
/set freq 869.618
/set sf 10
/set bw 62.5
/set cr 5
/set tx 22
```

Each command responds with `OK - reboot to apply`.

### 4.3 Enable Features

```
/gps on          # Enable GPS receiver
/mobrep          # Enable mobile repeater (relay for others)
```

### 4.4 Verify Settings

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

### 4.5 Reboot to Apply

Reset the T-Deck (press reset button or disconnect/reconnect USB). After reboot, verify settings persisted:

```
/get radio
/card
```

The `/card` command shows your device name and biz card (shareable identity).

### 4.6 Useful T-Deck Commands

| Command | Description |
|---------|-------------|
| `/help` | Show all commands |
| `/get radio` | Show radio settings |
| `/card` | Show your identity/biz card |
| `/public <text>` | Send message to Public channel |
| `/to <name>` | Select direct message recipient |
| `/send <text>` | Send direct message to selected recipient |
| `/messages 10` | Show last 10 messages |
| `/list 20` | List contacts |
| `/repeaters 15` | Scan for repeaters (15 seconds) |
| `/battery` | Show battery status |
| `/gps get` | Show GPS status |
| `/memory` | Show RAM usage |
| `/sd` | Show SD card status |
| `/sd ls /tiles` | List SD card contents |

---

## Step 5: Home Assistant Integration

### 5.1 Install meshcore-ha

Clone the integration:
```bash
cd /tmp
git clone https://github.com/meshcore-dev/meshcore-ha.git
```

Copy to Home Assistant config:
```bash
# For Docker/Supervised HA:
cp -r /tmp/meshcore-ha/custom_components/meshcore \
      /path/to/ha-config/custom_components/meshcore

# Restart Home Assistant
docker restart homeassistant
```

### 5.2 Add MeshCore Integration

1. Go to **Settings > Devices & Services > Add Integration**
2. Search for **MeshCore**
3. Select connection type: **TCP**
4. Enter:
   - **Host**: `<T-BEAM-IP>` (e.g., `192.168.1.50`)
   - **Port**: `5000`
5. Click **Submit**

### 5.3 Entities Created

After setup, these entities are automatically created:

| Entity | Type | Description |
|--------|------|-------------|
| `sensor.meshcore_node_status_*` | Sensor | Online/offline status |
| `sensor.meshcore_battery_percentage_*` | Sensor | Battery level (%) |
| `sensor.meshcore_battery_voltage_*` | Sensor | Battery voltage (V) |
| `sensor.meshcore_frequency_*` | Sensor | Current frequency (MHz) |
| `sensor.meshcore_spreading_factor_*` | Sensor | Current SF |
| `sensor.meshcore_bandwidth_*` | Sensor | Current BW (kHz) |
| `sensor.meshcore_tx_power_*` | Sensor | TX power (dBm) |
| `select.meshcore_recipient_type` | Select | Choose Contact or Channel |
| `select.meshcore_contact` | Select | Choose message recipient |
| `select.meshcore_channel` | Select | Choose message channel |
| `text.meshcore_message` | Text | Message composition input |
| `text.meshcore_command` | Text | Raw command input |
| `binary_sensor.meshcore_*_contact` | Binary Sensor | Per-contact online status |

### 5.4 Create MeshCore Dashboard

Create a new dashboard in HA for the Galaxy Tab kiosk:

**Settings > Dashboards > Add Dashboard**
- Title: MeshCore
- Icon: `mdi:radio-tower`
- Show in sidebar: Yes

Add cards for the messenger view:

```yaml
# Messenger View - Example Card Configuration
type: vertical-stack
cards:
  - type: entities
    title: Send Message
    entities:
      - entity: select.meshcore_recipient_type
        name: Recipient Type
      - entity: select.meshcore_contact
        name: Contact
      - entity: select.meshcore_channel
        name: Channel
      - entity: text.meshcore_message
        name: Message
  - type: button
    name: Send Message
    icon: mdi:send
    tap_action:
      action: perform-action
      perform_action: meshcore.send_ui_message
```

```yaml
# Status View - Example Card Configuration
type: entities
title: T-Beam Gateway Status
entities:
  - entity: sensor.meshcore_node_status_t_beam
    name: Status
  - entity: sensor.meshcore_battery_percentage_t_beam
    name: Battery
  - entity: sensor.meshcore_frequency_t_beam
    name: Frequency
  - entity: sensor.meshcore_spreading_factor_t_beam
    name: Spreading Factor
  - entity: sensor.meshcore_bandwidth_t_beam
    name: Bandwidth
  - entity: sensor.meshcore_tx_power_t_beam
    name: TX Power
```

See [homeassistant/dashboard-meshcore.yaml](../homeassistant/dashboard-meshcore.yaml) for the complete dashboard configuration.

### 5.5 Add Automations

See [homeassistant/automations-meshcore.yaml](../homeassistant/automations-meshcore.yaml) for:

- **Message notifications**: Persistent notification for incoming mesh messages
- **MQTT bridge**: Forward mesh messages to MQTT topics (`meshcore/channel_msg`, `meshcore/direct_msg`)
- **Low battery alert**: Warning when T-Beam battery drops below 20%

### 5.6 MeshCore Services (for Automations/Scripts)

| Service | Description |
|---------|-------------|
| `meshcore.send_message` | Send direct message to a contact |
| `meshcore.send_channel_message` | Send to a public channel |
| `meshcore.send_ui_message` | Send using the UI helper entities |
| `meshcore.execute_command` | Execute raw MeshCore command |

#### Example: Send Message via Automation

```yaml
service: meshcore.send_message
data:
  node_id: "ContactName"
  message: "Hello from Home Assistant!"
```

#### Example: Send Public Channel Message

```yaml
service: meshcore.send_channel_message
data:
  channel_idx: 0
  message: "Broadcast from HA!"
```

### 5.7 Galaxy Tab Kiosk Setup

On the Galaxy Tab with Fully Kiosk Browser:

1. Set the start URL to: `http://<HA-IP>:8123/meshcore/messenger`
2. Login to Home Assistant
3. Enable kiosk mode
4. The tablet now shows the MeshCore messenger dashboard

---

## Step 6: Offline Map Tiles for T-Deck

MeshOS/Ultra on the T-Deck can display offline maps from a MicroSD card.

### 6.1 Tile Format

Tiles must be in standard XYZ slippy map format:
```
/tiles/{z}/{x}/{y}.png
```

Where:
- `z` = zoom level (1-13 recommended)
- `x` = tile column
- `y` = tile row
- Format: 256x256 PNG

### 6.2 Download Tiles

Use the provided download script:

```bash
# Mount SD card
mount /dev/sdX1 /mnt/sdcard

# Download Germany + Austria tiles (zoom 1-13)
python3 scripts/download-tiles.py /mnt/sdcard/tiles
```

The script will show:
```
=== MeshCore Map Tile Downloader ===
Region: Germany + Austria
Bbox: lat 46.37-55.06, lon 5.87-16.95
Zoom: 1-13
Output: /mnt/sdcard/tiles

Tile count per zoom level:
  Zoom  1:        1 tiles
  Zoom  2:        1 tiles
  ...
  Zoom 12:   20,066 tiles
  Zoom 13:   79,695 tiles

Total: 106,640 tiles
Estimated size: ~1562 MB (avg 15KB/tile)
Estimated time: ~89 minutes
```

### 6.3 Customize Region

Edit the bounding box in `download-tiles.py`:

```python
# Germany + Austria bounding box
MIN_LAT = 46.37   # Southern Austria
MAX_LAT = 55.06   # Northern Germany
MIN_LON = 5.87    # Western Germany
MAX_LON = 16.95   # Eastern Austria

# Zoom levels
MIN_ZOOM = 1
MAX_ZOOM = 13     # Higher = more detail but exponentially more tiles
```

### 6.4 Insert SD Card

1. Unmount the SD card: `umount /mnt/sdcard`
2. Insert into T-Deck's MicroSD slot
3. Verify on T-Deck: `/sd` and `/sd ls /tiles`

---

## Step 7: Test Mesh Communication

### 7.1 Verify Radio Settings Match

Both devices **must** use identical radio settings:

| Setting | T-Beam | T-Deck |
|---------|--------|--------|
| Frequency | 869.618 MHz | 869.618 MHz |
| SF | 10 | 10 |
| BW | 62.5 kHz | 62.5 kHz |
| CR | 4/5 | 4/5 |

### 7.2 Send Test Message from HA to T-Deck

From Home Assistant, call the service:

```yaml
service: meshcore.send_channel_message
data:
  channel_idx: 0
  message: "Hello from Home Assistant!"
```

On the T-Deck you should see:
```
L MSG -> (Flood) hops 0 [] SNR=9.2
 Time: 19:15:11 8/2/2026
   <sender-id>: Hello from Home Assistant!
```

### 7.3 Send Test Message from T-Deck to HA

On the T-Deck serial console or keyboard:
```
/public Hello from T-Deck!
```

In Home Assistant, check the HA logs or the MQTT topic `meshcore/channel_msg`.

### 7.4 Relay Behavior

MeshCore routing is **automatic**:
- **At home**: T-Deck messages are relayed through the T-Beam to HA/MQTT
- **Away from home**: T-Deck communicates directly via LoRa with other mesh nodes
- No manual configuration needed - the mesh routing protocol handles path selection

---

## Troubleshooting

### T-Beam: WiFi Connection Issues

| WiFi Status | Meaning | Solution |
|-------------|---------|----------|
| `status=1` | SSID not found | Check SSID spelling, verify WiFi range |
| `status=4` | Auth failed | Wrong password |
| `status=6` | Disconnected | Temporary, will auto-retry |

Add `-D WIFI_DEBUG_LOGGING=1` to build flags and rebuild for detailed WiFi diagnostics.

### T-Beam: radio init failed: -2

Wrong radio chip variant. The SX1276 firmware cannot run on SX1262 hardware and vice versa. Check your T-Beam's LoRa module markings.

### T-Beam: DRAM overflow during build

The ESP32 WiFi stack uses significant RAM. Solutions:
- Reduce `MAX_CONTACTS` (try 80 or 60)
- Reduce `MAX_GROUP_CHANNELS` (try 2)
- Remove `DISPLAY_CLASS` if OLED is not needed
- Reduce `OFFLINE_QUEUE_SIZE` (try 64)

### T-Deck: Settings lost after reboot

MeshOS stores settings in flash. If settings revert after reboot:
1. Set all values via `/set` commands
2. Wait a few seconds for flash write
3. Then reboot (press reset or power cycle)
4. Verify with `/get radio` after boot

### T-Deck: SD card not detected

- Ensure FAT32 format (not exFAT or NTFS)
- Check card is properly seated
- Try `/sd` command to see status
- Maximum supported: 32 GB

### No Messages Between Devices

1. Verify radio settings match on both devices (`/get radio`)
2. Ensure both are powered on and in LoRa range
3. Try `/public test` from T-Deck - this broadcasts to all devices on the same settings
4. Check T-Beam is connected to WiFi and HA can reach TCP:5000

### meshcore-ha: Entity Creation Errors

If you see errors about `MeshCoreMessageEntity` in HA logs, this is a known issue in meshcore-ha. Messages are still sent/received correctly - only the message tracking entities fail. The core functionality (send/receive, status monitoring) works fine.

---

## Radio Settings Reference

### EU Legal Limits (868 MHz Band)

- **Frequency**: 863-870 MHz (sub-band specific duty cycles)
- **ERP**: Max 25 mW (14 dBm) for most sub-bands, 500 mW (27 dBm) for 869.4-869.65 MHz
- **Duty Cycle**: 0.1% - 10% depending on sub-band
- MeshCore default 869.618 MHz falls in the 10% duty cycle band

### Choosing Radio Parameters

| Priority | SF | BW | Range (urban) | Range (rural) | Data Rate |
|----------|----|----|---------------|---------------|-----------|
| **Max Range** | SF12 | 31.25 kHz | ~3-5 km | ~15-20 km | Very slow |
| **Long Range** (recommended) | SF10 | 62.5 kHz | ~2-3 km | ~5-10 km | Slow |
| **Balanced** | SF8 | 125 kHz | ~1-2 km | ~3-5 km | Medium |
| **Fast** | SF7 | 250 kHz | ~0.5-1 km | ~2-3 km | Fast |

Higher SF = more range but slower data rate and higher airtime. For messaging, SF10/BW62.5 is a good compromise.

### Changing Radio Settings on T-Deck

```
/set freq 869.618    # Frequency in MHz
/set sf 10           # Spreading factor (7-12)
/set bw 62.5         # Bandwidth in kHz (7.8, 10.4, 15.6, 20.8, 31.25, 41.7, 62.5, 125, 250, 500)
/set cr 5            # Coding rate denominator (5=4/5, 6=4/6, 7=4/7, 8=4/8)
/set tx 22           # TX power in dBm
```

> **Important**: Both T-Beam and T-Deck MUST use identical freq/sf/bw/cr settings to communicate. TX power can differ.
