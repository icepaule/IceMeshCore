# MeshCore Radio Settings Reference

## EU Legal Limits (868 MHz Band)

| Sub-Band | Frequency | Max ERP | Duty Cycle |
|----------|-----------|---------|------------|
| g | 863.0 - 868.0 MHz | 25 mW (14 dBm) | 1% |
| g1 | 868.0 - 868.6 MHz | 25 mW (14 dBm) | 1% |
| g2 | 868.7 - 869.2 MHz | 25 mW (14 dBm) | 0.1% |
| **g3** | **869.4 - 869.65 MHz** | **500 mW (27 dBm)** | **10%** |
| g4 | 869.7 - 870.0 MHz | 25 mW (14 dBm) | 1% |

MeshCore default frequency **869.618 MHz** falls in the **g3 sub-band** (500 mW, 10% duty cycle).

## Recommended Settings

### Long Range (Default)

Best for messaging where speed is not critical.

```
Frequency:  869.618 MHz
SF:         10
BW:         62.5 kHz
CR:         4/5
TX Power:   20-22 dBm
```

- Urban range: ~2-3 km
- Rural/LoS range: ~5-10 km
- Good compromise between range and reliability

### Maximum Range

For reaching distant nodes. Very slow data rate.

```
Frequency:  869.618 MHz
SF:         12
BW:         31.25 kHz
CR:         4/7
TX Power:   22 dBm
```

- Urban range: ~3-5 km
- Rural/LoS range: ~15-20 km
- Very slow, high airtime consumption

### Balanced

For more responsive messaging with moderate range.

```
Frequency:  869.618 MHz
SF:         8
BW:         125 kHz
CR:         4/5
TX Power:   20-22 dBm
```

- Urban range: ~1-2 km
- Rural/LoS range: ~3-5 km
- Good message throughput

### Fast / Short Range

For high-throughput messaging in close proximity.

```
Frequency:  869.618 MHz
SF:         7
BW:         250 kHz
CR:         4/5
TX Power:   20 dBm
```

- Urban range: ~0.5-1 km
- Rural/LoS range: ~2-3 km
- Fast, low airtime

## Parameter Details

### Spreading Factor (SF 7-12)

Higher SF = longer range but slower and more airtime.

| SF | Relative Range | Airtime (vs SF7) | Use Case |
|----|---------------|-------------------|----------|
| 7 | 1x | 1x | Short range, fast |
| 8 | 1.4x | 2x | Balanced |
| 9 | 1.8x | 4x | Medium range |
| **10** | **2.3x** | **8x** | **Long range (recommended)** |
| 11 | 2.9x | 16x | Very long range |
| 12 | 3.6x | 32x | Maximum range |

### Bandwidth (kHz)

Narrower BW = better sensitivity (longer range) but slower.

| BW | Sensitivity Gain | Notes |
|----|-----------------|-------|
| 31.25 kHz | Best | Slow, good for maximum range |
| **62.5 kHz** | **Good** | **Good balance (recommended)** |
| 125 kHz | Medium | Standard LoRaWAN bandwidth |
| 250 kHz | Low | Fast, short range |
| 500 kHz | Lowest | Fastest, shortest range |

### Coding Rate (CR)

Higher CR = more error correction but more airtime.

| CR | Overhead | Use Case |
|----|----------|----------|
| **4/5** | **+25%** | **Normal conditions (recommended)** |
| 4/6 | +50% | Moderate interference |
| 4/7 | +75% | High interference |
| 4/8 | +100% | Extreme interference |

### TX Power

| Chip | Max TX Power | Notes |
|------|-------------|-------|
| SX1276 | 20 dBm | T-Beam |
| SX1262 | 22 dBm | T-Deck, newer T-Beams |

TX power does NOT need to match between devices. Only frequency, SF, BW, and CR must be identical.

## Changing Settings

### On T-Deck (MeshOS CLI)

```
/set freq 869.618
/set sf 10
/set bw 62.5
/set cr 5
/set tx 22
```

Settings require a reboot to apply. Verify after reboot:

```
/get radio
```

### On T-Beam (Firmware Build)

Edit the build flags in `platformio.ini`:

```ini
-D LORA_FREQ=869.618
-D LORA_BW=62.5
-D LORA_SF=10
-D LORA_CR=5
-D LORA_TX_POWER=20
```

Then rebuild and reflash:

```bash
pio run -e Tbeam_SX1276_companion_radio_wifi -t upload
```

## Important Rules

1. **All devices MUST use identical freq/SF/BW/CR** to communicate
2. TX power can differ between devices
3. When changing settings, update ALL devices in your mesh
4. Test communication after any radio parameter change
5. Stay within EU legal limits for your sub-band
