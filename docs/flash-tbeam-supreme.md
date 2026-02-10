# Flashing the T-Beam Supreme SX1262 (Dedicated Repeater)

Komplette Anleitung zum Aufsetzen eines LilyGo T-Beam Supreme als dedizierter MeshCore-Repeater mit OLED-Statusanzeige. Der Repeater leitet Mesh-Pakete weiter und erweitert die Reichweite des Netzes - ohne WiFi oder Bluetooth, rein per LoRa.

## Was ist ein Repeater?

Ein Repeater ist ein "stummer" Mesh-Knoten: Er empfaengt LoRa-Pakete und leitet sie weiter, hat aber keinen Host-Anschluss (kein WiFi, kein BLE, kein USB-Client). Er braucht nur Strom (USB oder Akku) und eine moeglichst gute Antenne an einem hohen Punkt.

```
  [T-Deck]  <~~~LoRa~~~>  [Repeater]  <~~~LoRa~~~>  [T-Beam Gateway]
  (mobil)                  (Dach/Mast)                (Zuhause + WiFi)
```

Der Repeater verdoppelt (oder mehr) die Reichweite zwischen zwei Geraeten, die sich sonst nicht direkt erreichen koennten.

## Hardware

| Komponente | Details |
|------------|---------|
| Board | LilyGo T-Beam Supreme v3.0 |
| MCU | ESP32-S3 (Dual-Core, 8 MB Flash, 8 MB PSRAM) |
| Radio | Semtech SX1262 (max 22 dBm / 158 mW) |
| Display | SH1106 OLED 128x64 Pixel (I2C) |
| GPS | u-blox NEO-M10S |
| PMU | AXP2101 (Akku-Management) |
| Sensoren | BME280 (Temperatur/Feuchte/Druck, optional) |
| Anschluss | USB-C (Strom + Programmierung) |
| Antenne | SMA-Buchse fuer externe 868 MHz Antenne |

### Was man zusaetzlich braucht

- **USB-C Kabel** (Daten, nicht nur Laden!)
- **868 MHz Antenne** mit SMA-Stecker (die mitgelieferte Stummelantenne funktioniert, eine externe Antenne auf dem Dach ist deutlich besser)
- **Linux-Rechner** mit PlatformIO installiert (oder WSL2 unter Windows)
- Optional: USB-Powerbank oder 18650-Akku fuer mobilen Betrieb

## Voraussetzungen

### PlatformIO installieren

PlatformIO ist das Build-System fuer ESP32-Firmware. Installation:

```bash
pip3 install platformio --break-system-packages
```

Pruefen ob es funktioniert:

```bash
pio --version
# Sollte z.B. "PlatformIO Core, version 6.x.x" ausgeben
```

### MeshCore-Quellcode klonen

```bash
cd ~
git clone https://github.com/meshcore-dev/MeshCore.git
cd MeshCore
```

> **Hinweis**: Der Quellcode ist ~50 MB gross. Die erste Kompilierung laedt zusaetzlich ~500 MB an Toolchains und Libraries herunter.

## Schritt 1: Konfiguration kopieren

Kopiere die vorbereitete PlatformIO-Konfiguration in das richtige Verzeichnis:

```bash
cp /pfad/zu/IceMeshCore/configs/tbeam_supreme_sx1262_repeater.ini \
   ~/MeshCore/variants/lilygo_tbeam_supreme_SX1262/platformio.ini
```

> **WICHTIG**: Die Datei muss `platformio.ini` heissen und im Verzeichnis `variants/lilygo_tbeam_supreme_SX1262/` liegen. Wenn dort schon eine Datei existiert, wird sie ueberschrieben.

## Schritt 2: Konfiguration anpassen

Oeffne die Konfigurationsdatei:

```bash
nano ~/MeshCore/variants/lilygo_tbeam_supreme_SX1262/platformio.ini
```

### Repeater-Name aendern

Finde diese Zeile und aendere den Namen:

```ini
  -D ADVERT_NAME='"MeinRepeater"'
```

> Der Name darf maximal 15 Zeichen lang sein. Er wird im Mesh-Netz angezeigt, wenn andere Geraete den Repeater sehen.

### Admin-Passwort aendern

```ini
  -D ADMIN_PASSWORD='"CHANGE_THIS_PASSWORD"'
```

> **WICHTIG**: Aendere das Standard-Passwort! Mit diesem Passwort kann man sich ueber das Mesh remote auf den Repeater einloggen und Einstellungen aendern.

### GPS-Koordinaten (optional)

Wenn du den festen Standort des Repeaters angeben willst:

```ini
  -D ADVERT_LAT=48.1234
  -D ADVERT_LON=11.5678
```

> Lasse `0` wenn der Repeater GPS hat und seinen Standort selbst bestimmen soll. Bei `0` wird der GPS-Fix verwendet, sobald einer verfuegbar ist.

### Radio-Parameter

Die Radio-Einstellungen muessen bei **allen Geraeten im Mesh identisch** sein:

```ini
  ; EU Radio Settings - NICHT AENDERN wenn andere Geraete schon laufen!
  -D LORA_FREQ=869.618       ; EU g3 Sub-Band (legal in DE/AT/CH)
  -D LORA_BW=62.5            ; Bandbreite in kHz
  -D LORA_SF=10              ; Spreading Factor (hoeher = weiter, langsamer)
  -D LORA_CR=5               ; Coding Rate 4/5
```

> **Achtung**: Wenn du einen bestehenden Mesh mit diesen Einstellungen hast, aendere hier NICHTS. Die Einstellungen muessen auf allen Knoten gleich sein, sonst koennen sie sich nicht "hoeren".

### TX-Leistung

```ini
  -D LORA_TX_POWER=22        ; Max 22 dBm fuer SX1262
```

> Der SX1262 kann bis 22 dBm (158 mW). In der EU sind auf 869.4-869.65 MHz bis zu 500 mW (27 dBm) ERP erlaubt, aber die Antennenverstaerkung zaehlt dazu.

## Schritt 3: T-Beam Supreme anschliessen

1. Stecke das USB-C Kabel in den T-Beam Supreme und in den Computer
2. Pruefe ob das Geraet erkannt wird:

```bash
ls /dev/ttyACM*
# Sollte /dev/ttyACM0 zeigen
```

3. Pruefe den USB-Geraetetyp:

```bash
lsusb | grep -i "esp\|jtag\|serial"
# Sollte zeigen: "Espressif USB JTAG/serial debug unit"
```

> Der T-Beam Supreme (ESP32-S3) erscheint als **USB JTAG/serial debug unit** - das ist normal und korrekt. Er braucht keinen separaten USB-zu-Serial Chip.

### Falls das Geraet nicht erkannt wird

- Anderes USB-Kabel probieren (manche Kabel sind nur Ladekabel ohne Datenleitungen)
- Anderen USB-Port probieren (USB 2.0 Ports sind zuverlaessiger als USB 3.0)
- `dmesg | tail -20` pruefen fuer Fehlermeldungen

## Schritt 4: Firmware kompilieren und flashen

### Variante A: Mit dem Build-Script (empfohlen)

```bash
cd /pfad/zu/IceMeshCore
./scripts/build-tbeam-supreme.sh
```

Das Script:
1. Prueft ob PlatformIO installiert ist
2. Prueft ob der MeshCore-Quellcode vorhanden ist
3. Prueft ob das Admin-Passwort geaendert wurde
4. Kompiliert die Firmware (~15-60 Sekunden)
5. Fragt ob geflasht werden soll
6. Flasht auf den T-Beam Supreme

### Variante B: Manuell mit PlatformIO

```bash
cd ~/MeshCore

# Nur kompilieren (ohne flashen)
pio run -e T_Beam_S3_Supreme_SX1262_repeater

# Kompilieren und flashen
pio run -e T_Beam_S3_Supreme_SX1262_repeater -t upload
```

### Was passiert beim Flashen

```
Connecting...
Chip is ESP32-S3 (revision v0.2)
Uploading stub...
Stub running...
Changing baud rate to 460800
Flash will be erased from 0x00000000 to 0x00003fff...
Flash will be erased from 0x00008000 to 0x00008fff...
Flash will be erased from 0x0000e000 to 0x0000ffff...
Flash will be erased from 0x00010000 to 0x0011efff...
Writing at 0x00010000... (2 %)
...
Writing at 0x0011dbd1... (100 %)
Wrote 1108032 bytes (739023 compressed) at 0x00010000 in 7.5 seconds
Hash of data verified.
Hard resetting via RTS pin...
```

> Der Flash-Vorgang dauert ~10-20 Sekunden. Danach startet der T-Beam automatisch neu.

### Falls der Flash fehlschlaegt

Wenn der T-Beam nicht in den Flash-Modus geht oder der Flash abbricht:

**Methode 1: Manueller Bootloader-Modus**

1. T-Beam vom USB trennen
2. **BOOT**-Taste gedrueckt halten (kleine Taste neben USB)
3. USB-Kabel einstecken (waehrend BOOT gedrueckt bleibt)
4. BOOT-Taste loslassen
5. Flash-Befehl ausfuehren

**Methode 2: Niedrige Baudrate**

Falls der Flash bei hoher Baudrate abbricht:

```bash
# esptool direkt mit niedriger Baudrate
esptool.py --chip esp32s3 --port /dev/ttyACM0 \
  --no-stub --baud 115200 --before no-reset \
  write_flash -z \
  0x0000 .pio/build/T_Beam_S3_Supreme_SX1262_repeater/bootloader.bin \
  0x8000 .pio/build/T_Beam_S3_Supreme_SX1262_repeater/partitions.bin \
  0xe000 ~/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin \
  0x10000 .pio/build/T_Beam_S3_Supreme_SX1262_repeater/firmware.bin
```

**Methode 3: Wenn Meshtastic vorinstalliert ist**

Neue T-Beam Supreme kommen oft mit Meshtastic-Firmware. Die Meshtastic-Firmware blockiert manchmal den normalen Flash-Modus. Loesung:

```bash
# Meshtastic CLI installieren (temporaer)
python3 -m venv /tmp/mesh-venv
source /tmp/mesh-venv/bin/activate
pip install meshtastic

# Geraet in DFU-Modus versetzen
meshtastic --port /dev/ttyACM0 --enter-dfu

# Jetzt normal flashen
deactivate
pio run -e T_Beam_S3_Supreme_SX1262_repeater -t upload
```

## Schritt 5: Verifizieren

### Serial-Monitor

```bash
pio run -e T_Beam_S3_Supreme_SX1262_repeater -t monitor
```

Erwartete Ausgabe:

```
AXP2101 PMU init succeeded
Found SSD1306/SH1106 display
GPS detected
RadioLibWrapper: noise_floor = -115
Repeater ID: AB12CD34EF567890...
```

> **Hinweis**: Der Repeater gibt im Normalbetrieb wenig Serial-Output aus. Das ist normal - er arbeitet still im Hintergrund.

### OLED-Display

Nach dem Boot zeigt das Display:

1. **Boot-Screen** (4 Sekunden): MeshCore-Logo, Firmware-Version, "< Repeater >"
2. **Info-Screen (1/3)**: Repeater-Name, Frequenz, SF, BW, CR, TX-Power, Version

Per **Knopfdruck** (User-Button auf dem Board) kann man zwischen drei Screens wechseln:

| Screen | Inhalt | Beschreibung |
|--------|--------|-------------|
| 1/3 Info | Name, FREQ, SF, BW, CR, TX, Version | Radio-Konfiguration auf einen Blick |
| 2/3 Traffic | RX, TX, Errors, Uptime | Wie viele Pakete empfangen/gesendet, Laufzeit |
| 3/3 Radio | RSSI, SNR, Batt, Neighbors | Signalqualitaet, Akku-Spannung, Nachbar-Repeater |

> Das Display schaltet sich nach 60 Sekunden automatisch ab (Stromsparmodus). Ein erneuter Knopfdruck schaltet es wieder ein.

#### Was die Werte bedeuten

| Wert | Erklaerung | Gut/Schlecht |
|------|-----------|-------------|
| RX | Empfangene Pakete seit Boot | Hoeher = mehr Mesh-Verkehr |
| TX | Gesendete Pakete (Weiterleitungen) | Hoeher = Repeater ist aktiv |
| Errors | Empfangsfehler (CRC etc.) | 0 = perfekt, >10% von RX = Problem |
| RSSI | Signalstaerke in dBm | -80 gut, -100 grenzwertig, -120 schlecht |
| SNR | Signal-Rausch-Verhaeltnis in dB | >5 gut, 0 grenzwertig, <-5 schlecht |
| Batt | Akku-Spannung (wenn Akku eingebaut) | 4.2V voll, 3.3V leer |
| Neighbors | Anzahl gesehener Nachbar-Repeater | Nur direkte 1-Hop Nachbarn |
| Uptime | Laufzeit seit Boot | Zeigt ob Repeater stabil laeuft |

## Schritt 6: Aufstellen

### Optimaler Standort

- **Hoch = gut**: Je hoeher die Antenne, desto besser die Reichweite
- **Freie Sicht**: LoRa geht nicht gut durch Beton/Metall, Fenster ist OK
- **Zwischen den Knoten**: Der Repeater sollte zwischen den Geraeten stehen, die er verbinden soll
- **Strom**: USB-Netzteil (5V/1A reicht) oder Akku + Solar

### Reichweite

| Szenario | Erwartete Reichweite |
|----------|---------------------|
| Indoor, gleiches Gebaeude | 50-200 m |
| Fensterbank zu Fensterbank | 500 m - 2 km |
| Dach/Mast, Stadtgebiet | 2-5 km |
| Dach/Mast, laendlich | 5-15 km |
| Bergspitze | 20+ km |

## Verwaltung ueber das Mesh

Man kann den Repeater remote ueber das Mesh-Netz konfigurieren (von einem Companion-Geraet oder T-Deck aus). Dazu verbindet man sich mit dem Admin-Passwort und kann dann CLI-Befehle senden:

| Befehl | Funktion |
|--------|---------|
| `get name` | Aktuellen Namen anzeigen |
| `set name MeinRepeater` | Namen aendern |
| `get freq` | Frequenz anzeigen |
| `stats` | Paket-Statistiken |
| `rstats` | Radio-Statistiken |
| `pstats` | Detaillierte Paket-Statistiken |
| `nbrs` | Nachbar-Repeater anzeigen |
| `reboot` | Neustart |

> Diese Befehle funktionieren auch ueber Serial (USB) wenn man direkt angeschlossen ist.

## Troubleshooting

| Problem | Ursache | Loesung |
|---------|---------|---------|
| `radio init failed: -2` | Falsches Radio-Modul in der Config | SX1262-Config pruefen, nicht SX1276 verwenden |
| Kein Serial-Output nach Flash | ESP32-S3 USB-JTAG braucht manchmal Reset | USB ab- und wieder anstecken |
| Display bleibt dunkel | I2C-Adresse oder Display nicht initialisiert | `DISPLAY_CLASS=SH1106Display` pruefen |
| Display zeigt "Please wait..." und haengt | Radio-Init fehlgeschlagen | Serial-Monitor pruefen, Antenne anschliessen |
| Keine Pakete empfangen (RX bleibt 0) | Falsche Radio-Parameter | Alle Geraete muessen gleiche FREQ/SF/BW/CR haben |
| Flash bricht bei hoher Baudrate ab | ESP32-S3 USB-JTAG instabil | `--no-stub --baud 115200` verwenden |
| `/dev/ttyACM0` nicht gefunden | USB-Kabel nur zum Laden | Datenkabel verwenden, `lsusb` pruefen |
| Repeater startet staendig neu (Bootloop) | Defekte Firmware oder Flash | Komplett neu flashen mit `--erase-all` |
| Uptime zaehlt nicht hoch | Board resettet sich | Stromversorgung pruefen, anderes USB-Kabel |

## Firmware aktualisieren

Bei einem neuen MeshCore-Release:

```bash
cd ~/MeshCore
git pull                    # Neueste Quellen holen
pio run -e T_Beam_S3_Supreme_SX1262_repeater -t upload   # Neu kompilieren und flashen
```

> Die Repeater-Identitaet (Schluessel) bleibt im SPIFFS-Dateisystem erhalten. Andere Geraete erkennen den Repeater nach einem Update noch.

## OLED-Statusanzeige anpassen

Die Statusanzeige auf dem OLED-Display kann angepasst werden. Details zur Code-Struktur und Anpassungsmoeglichkeiten: [docs/oled-status-display.md](oled-status-display.md)
