# IceMeshCore - MeshCore LoRa Mesh Communication Setup

Complete step-by-step guide for setting up a [MeshCore](https://meshcore.co.uk/) LoRa mesh network with LilyGo hardware, integrated with Home Assistant for monitoring and messaging from a tablet/dashboard.

## Architecture Overview

```
                        LoRa 868.618 MHz
                       SF10 / BW 62.5 kHz
  [T-Deck "IceDeck"] <~~~~~~~~~~~~~~~~~~~~~~~> [T-Beam SX1276]
   (Portable Client)                            (Relay / Gateway)
    - MeshOS/Ultra FW                            - WiFi Companion FW
    - Physical Keyboard                          - Built from Source
    - GPS + Offline Maps                         - TCP:5000
    - SD Card (Map Tiles)                        |
    - Direct LoRa Mesh                           | WiFi (IoT VLAN)
                                                 v
                                            [Home Network]
                                                 |
                                                 v
                                          [Home Assistant]
                                           - meshcore-ha Integration
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
| LilyGo T-Deck | ESP32-S3 + SX1262 | Portable Client | 869.618 MHz, 22 dBm | MeshOS/Ultra (closed-source) | USB / Standalone |

### Radio Settings (EU - Long Range)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Frequency | 869.618 MHz | EU MeshCore standard, legal in DE/AT/CH |
| Spreading Factor | SF10 | Long range (~5-10 km rural, ~2-3 km urban) |
| Bandwidth | 62.5 kHz | Narrow = better sensitivity and range |
| Coding Rate | 4/5 | Minimum FEC, sufficient for good signal |
| TX Power | 20-22 dBm | Maximum legal (T-Beam: 20, T-Deck: 22) |

## Step-by-Step Setup

1. **[Flash T-Beam Relay](#step-1-flash-t-beam)** - Build and flash WiFi companion firmware
2. **[Flash T-Deck Client](#step-2-flash-t-deck)** - Flash MeshOS via web flasher
3. **[Configure T-Deck](#step-3-configure-t-deck)** - Set radio parameters and name
4. **[Setup Home Assistant](#step-4-home-assistant-integration)** - Install meshcore-ha + dashboard
5. **[Download Map Tiles](#step-5-offline-map-tiles)** - Germany + Austria offline maps for T-Deck
6. **[Test Communication](#step-6-test-mesh-communication)** - Verify bidirectional messaging

Detailed instructions: [docs/setup-guide.md](docs/setup-guide.md)

## Directory Structure

```
IceMeshCore/
  configs/              # PlatformIO config templates (no credentials!)
    tbeam_sx1276_wifi.ini
  docs/                 # Detailed step-by-step documentation
    setup-guide.md      # Complete setup walkthrough
    flash-tbeam.md      # T-Beam flashing details + troubleshooting
    flash-tdeck.md      # T-Deck flashing details
    homeassistant.md    # HA integration setup
    architecture.md     # Network architecture details
    radio-settings.md   # Radio configuration reference
    images/             # Diagrams and console output examples
  homeassistant/        # HA configuration examples
    dashboard-meshcore.yaml
    automations-meshcore.yaml
  scripts/              # Build and utility scripts
    build-tbeam.sh
    flash-tdeck.sh
    download-tiles.py
  README.md
```

## Important Notes

- **EU Frequency**: 868 MHz band (legal requirement for DE/AT/CH)
- **No credentials in repo** - WiFi/MQTT passwords must be set locally
- **T-Beam radio identification**: This setup uses **SX1276** - check your hardware!
  - SX1276: 868 MHz only, 20 dBm max
  - SX1262: 868 MHz, 22 dBm max (different firmware!)
- **MeshOS/Ultra**: Closed-source T-Deck firmware with map support, flashed via web tool
- **MeshCore open-source**: Companion radio firmware is open source and built from source

## Links

- [MeshCore Project](https://meshcore.co.uk/)
- [MeshCore Firmware Source](https://github.com/meshcore-dev/MeshCore)
- [MeshCore Web Flasher](https://flasher.meshcore.co.uk/) (for T-Deck MeshOS/Ultra)
- [MeshCore HA Integration](https://github.com/meshcore-dev/meshcore-ha)
- [MeshCore Web App](https://app.meshcore.nz)
- [MeshCore Config Tool](https://config.meshcore.dev/)

## License

MIT - See [LICENSE](LICENSE)
