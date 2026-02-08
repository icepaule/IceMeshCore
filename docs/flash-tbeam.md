# Flashing the T-Beam (Relay / WiFi Gateway)

## Prerequisites

- LilyGo T-Beam with **SX1276** radio (check your board revision!)
- USB-C cable
- Linux host with PlatformIO installed
- WiFi network credentials

> **How to identify your radio chip**: Flash any T-Beam firmware and check serial output.
> If you see `radio init failed: -2`, you have the wrong radio variant.
> - SX1276: Older T-Beam models (v1.0, v1.1, some v1.2)
> - SX1262: Newer T-Beam models (v1.2+, Supreme)

## Install PlatformIO

```bash
pip3 install platformio --break-system-packages
```

## Clone MeshCore

```bash
git clone https://github.com/meshcore-dev/MeshCore.git
cd MeshCore
```

## Configure WiFi Credentials

Copy the template config:

```bash
cp /path/to/IceMeshCore/configs/tbeam_sx1276_wifi.ini variants/lilygo_tbeam_SX1276/platformio.ini
```

Edit the file and replace the WiFi placeholders:

```bash
nano variants/lilygo_tbeam_SX1276/platformio.ini
```

Find these lines and set your credentials:

```ini
  -D WIFI_SSID='"YOUR_WIFI_SSID"'
  -D WIFI_PWD='"YOUR_WIFI_PASSWORD"'
```

> **IMPORTANT**: The single quotes wrapping double quotes are required!
> Correct: `'"MyNetwork"'`
> Wrong: `'MyNetwork'` or `"MyNetwork"`

## Build and Flash

Connect the T-Beam via USB, then:

```bash
# Find the serial port
ls /dev/ttyACM* /dev/ttyUSB*

# Build and flash
pio run -e Tbeam_SX1276_companion_radio_wifi -t upload --upload-port /dev/ttyACM0
```

Build takes ~50-60 seconds on first run (downloads toolchain). Subsequent builds ~30s.

## Verify

Monitor serial output:

```bash
pio run -e Tbeam_SX1276_companion_radio_wifi -t monitor --upload-port /dev/ttyACM0
```

You should see:

```
AXP2101 PMU init succeeded
Found SSD1306/SH1106 display
GPS detected
RadioLibWrapper: noise_floor = -115
```

### WiFi Status Codes

If you add WiFi status debug logging, the status codes mean:

| Status | Meaning |
|--------|---------|
| 0 | WL_IDLE_STATUS |
| 1 | WL_NO_SSID_AVAIL (AP not in range) |
| 3 | WL_CONNECTED (success!) |
| 4 | WL_CONNECT_FAILED (wrong password?) |
| 6 | WL_DISCONNECTED |

## Configuration After Flash

Once the T-Beam is on WiFi (status=3), it runs a TCP server on **port 5000**.

The device will get an IP via DHCP. To find it:

```bash
# Scan your network for port 5000
nmap -p 5000 YOUR_SUBNET/24
```

Consider setting a static DHCP lease on your router for the T-Beam's MAC address.

## Notes

- **ESP32 RAM is limited** - WiFi uses more RAM than BLE, so MAX_CONTACTS is set to 100 (not 350)
- The T-Beam SX1276 has max TX power of 20 dBm
- GPS is enabled and will provide location data
- The OLED display shows basic status information
- WiFi credentials are compiled into the firmware (not configurable at runtime)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `radio init failed: -2` | Wrong radio variant. Try SX1262 config instead |
| No serial output after bootloader | Check baud rate (115200), try reset button |
| WiFi status stays at 1 | AP not in range, check SSID spelling |
| WiFi status stays at 4 | Wrong password |
| DRAM overflow at build | Reduce MAX_CONTACTS or MAX_GROUP_CHANNELS |
| `ttyACM0` not found | Check USB cable, install CH9102 driver if needed |
