# Network Architecture

## MeshCore Node Types

MeshCore uses different firmware types for different roles:

| Firmware | Purpose | Host Connection | Mesh Relay |
|----------|---------|-----------------|------------|
| Companion Radio BLE | Client device, pairs with phone app | Bluetooth LE | Yes |
| Companion Radio USB | Client device, connects via USB serial | USB Serial | Yes |
| Companion Radio WiFi | Client device, TCP server over WiFi | WiFi TCP:5000 | Yes |
| Repeater | Dedicated relay node | None (serial CLI only) | Yes |
| Room Server | BBS-style message board | None (serial CLI only) | Yes |

**Important**: All companion radios also relay mesh packets. A WiFi companion is
effectively a repeater + WiFi gateway.

## Our Setup

```
                         LoRa 868 MHz (up to several km)
                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       /                |                       \
  +------------------+    +-------------------+    +------------------+
  |   T-Deck         |    |   T-Beam Supreme  |    |   T-Beam         |
  |   (Portable)     |    |   (Repeater)      |    |   (Stationary)   |
  |                  |    |                   |    |                  |
  |  MeshOS/Ultra    |    |  Repeater FW      |    |  Companion WiFi  |
  |  SX1262 868 MHz  |    |  SX1262 868 MHz   |    |  SX1276 868 MHz  |
  |  Keyboard+Display|    |  OLED Status (3x) |    |  External Antenna|
  |  GPS + Maps      |    |  GPS + BME280     |    |  GPS + OLED      |
  +------------------+    +-------------------+    +------------------+
         |                     (standalone)                 |
         | BLE                                              | WiFi
         v                                                  v
  +------------------+                              +------------------+
  |  Phone App       |                              |  Home Network    |
  |  (Android/iOS)   |                              |  (DHCP)          |
  +------------------+                              +------------------+
                                                             |
                                                             | TCP:5000
                                                             v
                                                     +------------------+
                                                     |  Home Assistant  |
                                                     |  meshcore-ha     |
                                                     |  integration     |
                                                     +------------------+
                                                             |
                                                     +-------+-------+
                                                     |               |
                                                     v               v
                                               [Dashboards]   [Automations]
                                               [Entities]     [MQTT Bridge]
```

## Communication Flow

1. **T-Deck -> T-Beam Supreme**: LoRa mesh packet (encrypted, 868 MHz)
2. **T-Beam Supreme -> T-Beam**: LoRa relay (packet forwarding, extends range)
3. **T-Beam -> Home Network**: WiFi (TCP server on port 5000)
4. **Home Network -> Home Assistant**: meshcore-ha integration (TCP client)
5. **Home Assistant -> User**: Dashboards, notifications, automations

## Device Roles

### T-Beam SX1276 (WiFi Gateway)

The stationary gateway node. Connects to Home Assistant via WiFi and bridges
the LoRa mesh to the home network.

- **Firmware**: Companion Radio WiFi (custom build from MeshCore source)
- **Connection**: WiFi TCP:5000 to meshcore-ha integration
- **Flash guide**: [docs/flash-tbeam.md](flash-tbeam.md)
- **Config template**: [configs/tbeam_sx1276_wifi.ini](../configs/tbeam_sx1276_wifi.ini)

### T-Beam Supreme SX1262 (Dedicated Repeater)

Extends mesh range by relaying packets between nodes that can't reach each other
directly. No WiFi or BLE - just LoRa packet forwarding.

Features a custom OLED status display with 3 screens:

| Screen | Content |
|--------|---------|
| 1/3 Info | Node name, frequency, SF, BW, CR, TX power, version |
| 2/3 Traffic | Packets received/sent, errors, uptime |
| 3/3 Radio | RSSI, SNR, battery voltage, neighbor count |

- **Firmware**: Repeater (custom build from MeshCore source, with OLED modifications)
- **Connection**: Standalone (USB for flashing/monitoring only)
- **Flash guide**: [docs/flash-tbeam-supreme.md](flash-tbeam-supreme.md)
- **OLED customization**: [docs/oled-status-display.md](oled-status-display.md)
- **Config template**: [configs/tbeam_supreme_sx1262_repeater.ini](../configs/tbeam_supreme_sx1262_repeater.ini)

### T-Deck (Portable Client)

The portable mesh client with physical keyboard, GPS, and offline maps.

- **Firmware**: MeshOS/Ultra (closed-source, flashed via web tool)
- **Connection**: BLE to phone app, or standalone with built-in keyboard
- **Flash guide**: [docs/flash-tdeck.md](flash-tdeck.md)

## Security

- All LoRa mesh messages are **end-to-end encrypted** (public key cryptography)
- WiFi companion uses standard WiFi encryption (WPA2/WPA3)
- TCP connection between HA and T-Beam is on the local network
- meshcore-ha integration runs locally (no cloud dependency)
- Repeater admin access requires a password (set at compile time)

## Frequency Configuration

| Region | Frequency | Max TX Power | Sub-Band |
|--------|-----------|-------------|----------|
| EU (DE/AT/CH) | 869.618 MHz | 500 mW (27 dBm) ERP | g3 (869.4-869.65 MHz, 10% duty) |
| US | 915 MHz | 1 W (30 dBm) | ISM 915 |
| Asia | 433 MHz | varies | - |

Our setup uses **869.618 MHz** (EU g3 sub-band), which allows up to 500 mW ERP
with 10% duty cycle - the best legal option for LoRa in Europe.

## Range Expectations

LoRa range depends heavily on antenna, terrain, and obstacles:

| Scenario | Expected Range |
|----------|---------------|
| Indoor, same building | 50-200m |
| Urban, line of sight | 1-3 km |
| Suburban, elevated antenna | 3-10 km |
| Rural, clear line of sight | 10-20+ km |
| With repeater chain | Extends range per hop |

The T-Beam Supreme with an external antenna on a high point gives the best
repeater coverage. Each repeater hop adds latency (~1-2 seconds per hop)
but extends the total range of the mesh network.
