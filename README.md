# IceMeshCore - MeshCore LoRa Mesh Setup

Off-grid LoRa mesh communication setup using [MeshCore](https://meshcore.co.uk/) firmware on LilyGo hardware, integrated with Home Assistant.

## Architecture

```
                    LoRa 868 MHz
 [T-Deck] <~~~~~~~~~~~~~~~~~~~~~~~~~> [T-Beam Relay]
 (Portable Client)                     (Stationary Gateway)
  - BLE Companion                       - WiFi Companion
  - Keyboard + Display                  - Strong Antenna
  - MeshCore App (BLE)                  - TCP:5000
                                        |
                                        | WiFi
                                        v
                                   [Home Network]
                                        |
                                        v
                                   [Home Assistant]
                                    - meshcore-ha
                                    - MQTT Bridge
                                    - Automations
```

## Hardware

| Device | Role | Radio | Firmware | Connection |
|--------|------|-------|----------|------------|
| LilyGo T-Beam (SX1276) | Relay / Gateway | LoRa 868 MHz, 20 dBm | Companion Radio WiFi | WiFi -> TCP:5000 |
| LilyGo T-Deck | Portable Client | LoRa 868 MHz | Companion Radio BLE | BLE to Phone / Standalone |

### T-Beam (Relay)
- **Role**: Stationary mesh relay with external antenna, WiFi gateway to Home Assistant
- **Firmware**: Custom-built `Tbeam_SX1276_companion_radio_wifi` (built from source)
- **Features**: LoRa relay, GPS, WiFi TCP server (port 5000), OLED display
- **Power**: USB or battery (AXP2101 PMU)

### T-Deck (Client)
- **Role**: Portable handheld mesh client
- **Firmware**: Pre-built `LilyGo_TDeck_companion_radio_ble` v1.12.0
- **Features**: Physical keyboard, display, BLE pairing, standalone messaging
- **BLE PIN**: 123456 (default)

## Quick Start

### 1. Flash T-Beam (Relay)

See [docs/flash-tbeam.md](docs/flash-tbeam.md) for detailed instructions.

```bash
# Clone MeshCore source
git clone https://github.com/meshcore-dev/MeshCore.git
cd MeshCore

# Copy custom WiFi companion config
cp ../configs/tbeam_sx1276_wifi.ini variants/lilygo_tbeam_SX1276/platformio.ini

# Edit WiFi credentials (REQUIRED - replace placeholders!)
nano variants/lilygo_tbeam_SX1276/platformio.ini

# Build and flash
pio run -e Tbeam_SX1276_companion_radio_wifi -t upload --upload-port /dev/ttyACM0
```

### 2. Flash T-Deck (Client)

See [docs/flash-tdeck.md](docs/flash-tdeck.md) for detailed instructions.

```bash
# Download pre-built firmware
./scripts/flash-tdeck.sh /dev/ttyACM0
```

### 3. Home Assistant Integration

See [docs/homeassistant.md](docs/homeassistant.md) for detailed instructions.

1. Install `meshcore-ha` custom component
2. Restart Home Assistant
3. Add MeshCore integration via Settings > Devices & Services
4. Select TCP connection, enter T-Beam IP and port 5000

## Directory Structure

```
IceMeshCore/
  configs/          # PlatformIO config templates (no credentials!)
  scripts/          # Flash and utility scripts
  docs/             # Detailed documentation
  homeassistant/    # HA dashboard and automation examples
  README.md         # This file
```

## Important Notes

- **Frequency**: 868 MHz (EU legal requirement for DE/AT/CH)
- **No credentials in this repo** - WiFi/MQTT passwords must be set locally before building
- **MeshCore is open source** - firmware is free, T-Deck registration key optional
- **T-Beam radio**: This setup uses SX1276 variant. Check your hardware before building!

## Links

- [MeshCore Project](https://meshcore.co.uk/)
- [MeshCore GitHub](https://github.com/meshcore-dev/MeshCore)
- [MeshCore Web Flasher](https://flasher.meshcore.co.uk/)
- [MeshCore HA Integration](https://github.com/meshcore-dev/meshcore-ha)
- [MeshCore Web App](https://app.meshcore.nz)
- [MeshCore Config Tool](https://config.meshcore.dev/)

## License

MIT
