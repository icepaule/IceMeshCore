# IceMeshCore - MeshCore LoRa Mesh Communication Setup

Complete step-by-step guide for setting up a [MeshCore](https://meshcore.co.uk/) LoRa mesh network with LilyGo hardware, integrated with Home Assistant for monitoring and messaging from a tablet/dashboard.

## Architecture Overview

```
                        LoRa 869.618 MHz
                       SF10 / BW 62.5 kHz

  [T-Deck "IceDeck"] <~~~~~~~~~~~~~~~~~~~~~~~> [T-Beam SX1276]
   (Portable Client)            |                (Relay / Gateway)
    - MeshOS/Ultra FW           |                 - WiFi Companion FW
    - Physical Keyboard         |                 - Built from Source
    - GPS + Offline Maps        |                 - TCP:5000
    - SD Card (Map Tiles)       |                 |
                                |                 | WiFi (IoT VLAN)
                     [T-Beam Supreme SX1262]      v
                      (Dedicated Repeater)    [Home Network]
                       - Repeater FW               |
                       - OLED Status Display        v
                       - GPS + BME280         [Home Assistant]
                       - Built from Source     - meshcore-ha Integration
                                               - MeshCore Dashboard
                                               - MQTT Bridge
                                               - Automations & Alerts
                                                    |
                                                    v
                                             [Galaxy Tab Kiosk]
                                              - HA Dashboard URL
                                              - Send/Receive Messages
                                              - Monitor Mesh Status
```

## Hardware

| Device | Chip | Role | Radio | Firmware | Connection |
|--------|------|------|-------|----------|------------|
| LilyGo T-Beam v1.x | ESP32 + SX1276 | Relay / Gateway | 869.618 MHz, 20 dBm | Companion Radio WiFi (custom build) | WiFi TCP:5000 |
| LilyGo T-Beam Supreme | ESP32-S3 + SX1262 | Dedicated Repeater | 869.618 MHz, 22 dBm | Repeater (custom build + OLED status) | USB / Standalone |
| LilyGo T-Deck | ESP32-S3 + SX1262 | Portable Client | 869.618 MHz, 22 dBm | MeshOS/Ultra (closed-source) | USB / Standalone |

### Radio Settings (EU - Long Range)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Frequency | 869.618 MHz | EU MeshCore standard, legal in DE/AT/CH |
| Spreading Factor | SF10 | Long range (~5-10 km rural, ~2-3 km urban) |
| Bandwidth | 62.5 kHz | Narrow = better sensitivity and range |
| Coding Rate | 4/5 | Minimum FEC, sufficient for good signal |
| TX Power | 20-22 dBm | Maximum legal (T-Beam: 20, Supreme/T-Deck: 22) |

## Step-by-Step Setup

1. **[Flash T-Beam Relay](#step-1-flash-t-beam)** - Build and flash WiFi companion firmware
2. **[Flash T-Beam Supreme Repeater](#step-2-flash-repeater)** - Build and flash dedicated repeater with OLED status
3. **[Flash T-Deck Client](#step-3-flash-t-deck)** - Flash MeshOS via web flasher
4. **[Configure T-Deck](#step-4-configure-t-deck)** - Set radio parameters and name
5. **[Setup Home Assistant](#step-5-home-assistant-integration)** - Install meshcore-ha + dashboard
6. **[Download Map Tiles](#step-6-offline-map-tiles)** - Germany + Austria offline maps for T-Deck
7. **[Test Communication](#step-7-test-mesh-communication)** - Verify bidirectional messaging

### Detailed Instructions

| Guide | Description |
|-------|-------------|
| [docs/setup-guide.md](docs/setup-guide.md) | Complete setup walkthrough (all steps) |
| [docs/flash-tbeam.md](docs/flash-tbeam.md) | T-Beam SX1276 WiFi companion flashing |
| [docs/flash-tbeam-supreme.md](docs/flash-tbeam-supreme.md) | T-Beam Supreme SX1262 repeater flashing |
| [docs/flash-tdeck.md](docs/flash-tdeck.md) | T-Deck MeshOS/Ultra flashing |
| [docs/homeassistant.md](docs/homeassistant.md) | Home Assistant integration |
| [docs/radio-settings.md](docs/radio-settings.md) | Radio configuration reference |
| [docs/oled-status-display.md](docs/oled-status-display.md) | Customizing the repeater OLED display |
| [docs/benutzerhandbuch-messaging.md](docs/benutzerhandbuch-messaging.md) | User guide for Galaxy Tab messaging (DE) |

## Directory Structure

```
IceMeshCore/
  configs/                          # PlatformIO config templates (no credentials!)
    tbeam_sx1276_wifi.ini             # T-Beam SX1276 WiFi companion
    tbeam_supreme_sx1262_repeater.ini # T-Beam Supreme SX1262 repeater
  docs/                             # Detailed step-by-step documentation
    setup-guide.md                    # Complete setup walkthrough
    flash-tbeam.md                    # T-Beam flashing details + troubleshooting
    flash-tbeam-supreme.md            # T-Beam Supreme repeater guide (comprehensive)
    flash-tdeck.md                    # T-Deck flashing details
    oled-status-display.md            # OLED display customization guide
    homeassistant.md                  # HA integration setup
    architecture.md                   # Network architecture details
    radio-settings.md                 # Radio configuration reference
    benutzerhandbuch-messaging.md     # Galaxy Tab user guide (German)
    images/                           # Screenshots and console output examples
  homeassistant/                    # HA configuration examples
    dashboard-meshcore.yaml
    automations-meshcore.yaml
  scripts/                          # Build and utility scripts
    build-tbeam.sh                    # Build + flash T-Beam SX1276
    build-tbeam-supreme.sh            # Build + flash T-Beam Supreme SX1262
    flash-tdeck.sh                    # Flash T-Deck
    download-tiles.py                 # Download offline map tiles
  README.md
```

## Important Notes

- **EU Frequency**: 868 MHz band (legal requirement for DE/AT/CH)
- **No credentials in repo** - WiFi/MQTT passwords must be set locally
- **T-Beam radio identification**: Check your hardware!
  - SX1276: Older T-Beam models (v1.0, v1.1, some v1.2) - 868 MHz, 20 dBm max
  - SX1262: Newer models (T-Beam Supreme, some v1.2+) - 868 MHz, 22 dBm max
- **MeshOS/Ultra**: Closed-source T-Deck firmware with map support, flashed via web tool
- **MeshCore open-source**: Companion radio and repeater firmware is open source and built from source
- **OLED Status Display**: The T-Beam Supreme repeater includes a custom 3-screen status display showing traffic stats, signal quality, battery, and neighbor info

## Links

- [MeshCore Project](https://meshcore.co.uk/)
- [MeshCore Firmware Source](https://github.com/meshcore-dev/MeshCore)
- [MeshCore Web Flasher](https://flasher.meshcore.co.uk/) (for T-Deck MeshOS/Ultra)
- [MeshCore HA Integration](https://github.com/meshcore-dev/meshcore-ha)
- [MeshCore Web App](https://app.meshcore.nz)
- [MeshCore Config Tool](https://config.meshcore.dev/)

## License

MIT - See [LICENSE](LICENSE)
