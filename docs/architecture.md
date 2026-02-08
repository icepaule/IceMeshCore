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
                       /                                        \
  +------------------+                                    +------------------+
  |   T-Deck         |                                    |   T-Beam         |
  |   (Portable)     |                                    |   (Stationary)   |
  |                  |                                    |                  |
  |  Companion BLE   |                                    |  Companion WiFi  |
  |  SX1276 868 MHz  |                                    |  SX1276 868 MHz  |
  |  Keyboard+Display|                                    |  External Antenna|
  |  GPS             |                                    |  GPS + OLED      |
  +------------------+                                    +------------------+
         |                                                        |
         | BLE                                                    | WiFi
         v                                                        v
  +------------------+                                    +------------------+
  |  Phone App       |                                    |  Home Network    |
  |  (Android/iOS)   |                                    |  (DHCP)          |
  +------------------+                                    +------------------+
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

1. **T-Deck -> T-Beam**: LoRa mesh packet (encrypted, 868 MHz)
2. **T-Beam -> Home Network**: WiFi (TCP server on port 5000)
3. **Home Network -> Home Assistant**: meshcore-ha integration (TCP client)
4. **Home Assistant -> User**: Dashboards, notifications, automations

## Security

- All LoRa mesh messages are **end-to-end encrypted** (public key cryptography)
- WiFi companion uses standard WiFi encryption (WPA2/WPA3)
- TCP connection between HA and T-Beam is on the local network
- meshcore-ha integration runs locally (no cloud dependency)

## Frequency Configuration

| Region | Frequency | Max TX Power |
|--------|-----------|-------------|
| EU (DE/AT/CH) | 868 MHz | 25 mW (14 dBm) ERP |
| US | 915 MHz | 1 W (30 dBm) |
| Asia | 433 MHz | varies |

Our setup uses **868 MHz** as required by EU regulations.

## Range Expectations

LoRa range depends heavily on antenna, terrain, and obstacles:

| Scenario | Expected Range |
|----------|---------------|
| Indoor, same building | 50-200m |
| Urban, line of sight | 1-3 km |
| Suburban, elevated antenna | 3-10 km |
| Rural, clear line of sight | 10-20+ km |
| With repeater chain | Extends range per hop |

The T-Beam with an external antenna on a high point gives the best relay coverage.
