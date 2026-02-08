# Home Assistant Integration

## Overview

The T-Beam WiFi Companion Radio connects to Home Assistant via the
[meshcore-ha](https://github.com/meshcore-dev/meshcore-ha) custom integration.
The integration communicates with the T-Beam over TCP (port 5000) and creates
HA entities for monitoring the mesh network.

```
[T-Beam] --WiFi--> [Home Network] --TCP:5000--> [meshcore-ha] --> [HA Entities]
                                                                     |
                                                                     v
                                                               [Automations]
                                                               [Dashboards]
                                                               [MQTT Bridge]
```

## Installation

### Via HACS (Recommended)

1. Open HACS in Home Assistant
2. Click the 3-dot menu > **Custom repositories**
3. Add URL: `https://github.com/meshcore-dev/meshcore-ha`
4. Category: **Integration**
5. Click **Install**
6. Restart Home Assistant

### Manual Installation

```bash
# From the HA host machine:
git clone https://github.com/meshcore-dev/meshcore-ha.git /tmp/meshcore-ha
cp -r /tmp/meshcore-ha/custom_components/meshcore /config/custom_components/meshcore

# If using Docker:
docker cp /tmp/meshcore-ha/custom_components/meshcore homeassistant:/config/custom_components/meshcore
docker restart homeassistant
```

## Configuration

### 1. Find T-Beam IP Address

The T-Beam gets its IP via DHCP when connected to WiFi:

```bash
# Scan your network for port 5000
nmap -p 5000 YOUR_SUBNET/24

# Or check your router's DHCP lease table
```

**Recommended**: Set a static DHCP reservation on your router for the T-Beam's
MAC address so the IP doesn't change.

### 2. Add Integration

1. Go to **Settings > Devices & Services**
2. Click **+ Add Integration**
3. Search for **MeshCore**
4. Select connection type: **TCP**
5. Enter:
   - **Host**: T-Beam's IP address
   - **Port**: 5000
   - **Self Telemetry**: Enable (recommended)
   - **Telemetry Interval**: 300 (seconds)
6. Click **Submit**

### 3. Add Monitored Devices

After the initial connection, go to the integration's options to add:

- **Repeaters**: Monitor mesh repeater stations (requires admin password)
- **Tracked Clients**: Track T-Deck and other client nodes

## Available Entities

The integration creates entities for:

| Entity Type | Examples |
|-------------|---------|
| Sensors | Battery voltage, RSSI, SNR, packet count, uptime |
| Binary Sensors | Online/offline status, charging state |
| Device Tracker | GPS location of nodes |
| Text | Node name, firmware version |
| Select | Configuration options |

## Example Automations

### Notify on New Mesh Message

```yaml
automation:
  - alias: "MeshCore - New Message Notification"
    trigger:
      - platform: state
        entity_id: sensor.meshcore_last_message
    action:
      - service: notify.mobile_app
        data:
          title: "MeshCore Message"
          message: "{{ trigger.to_state.state }}"
```

### Low Battery Alert

```yaml
automation:
  - alias: "MeshCore - T-Beam Low Battery"
    trigger:
      - platform: numeric_state
        entity_id: sensor.meshcore_tbeam_battery
        below: 20
    action:
      - service: notify.mobile_app
        data:
          title: "MeshCore Battery Low"
          message: "T-Beam battery is at {{ states('sensor.meshcore_tbeam_battery') }}%"
```

### MQTT Bridge (Optional)

To also publish mesh data to MQTT for other consumers:

```yaml
automation:
  - alias: "MeshCore - MQTT Bridge"
    trigger:
      - platform: state
        entity_id: sensor.meshcore_last_message
    action:
      - service: mqtt.publish
        data:
          topic: "meshcore/messages"
          payload: >
            {{ {"from": trigger.to_state.attributes.sender,
                "message": trigger.to_state.state,
                "timestamp": now().isoformat()} | to_json }}
          retain: false
```

## Example Dashboard Card

```yaml
type: entities
title: MeshCore Network
entities:
  - entity: binary_sensor.meshcore_tbeam_online
    name: T-Beam Status
  - entity: sensor.meshcore_tbeam_battery
    name: T-Beam Battery
  - entity: sensor.meshcore_tbeam_rssi
    name: Signal Strength
  - entity: sensor.meshcore_packets_received
    name: Packets Received
  - entity: device_tracker.meshcore_tdeck
    name: T-Deck Location
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Cannot connect" during setup | Verify T-Beam IP, check port 5000 is open, ensure WiFi connected |
| Integration loads but no entities | Wait 60s for first data poll, check HA logs |
| TCP timeout | T-Beam WiFi may have disconnected, check signal strength |
| "meshcore" not found in integrations | Restart HA, check `custom_components/meshcore/` exists |
| Dependency errors | HA will auto-install `meshcore`, `pycryptodome`, etc. on first load |

## MQTT Alternative: meshcoretomqtt

If you prefer a pure MQTT approach without the HA integration:

```bash
pip3 install pyserial paho-mqtt
git clone https://github.com/Andrew-a-g/meshcoretomqtt.git
cd meshcoretomqtt
# Edit config.ini with your MQTT broker details
python3 mctomqtt.py
```

This reads serial output from a MeshCore repeater and publishes to MQTT topics.
Requires the repeater firmware to be built with `-D MESH_PACKET_LOGGING=1`.
