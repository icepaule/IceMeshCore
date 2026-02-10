# OLED-Statusanzeige anpassen (UITask)

Diese Dokumentation erklaert, wie die OLED-Statusanzeige auf dem T-Beam Supreme Repeater funktioniert und wie man sie anpassen kann.

## Ueberblick

Der T-Beam Supreme hat ein **SH1106 OLED-Display** mit 128x64 Pixeln, angesteuert ueber I2C (Adresse 0x3C). Die Display-Logik liegt in zwei Dateien im MeshCore-Quellcode:

```
MeshCore/
  examples/simple_repeater/
    UITask.h          # Klasse und Datenstrukturen
    UITask.cpp         # Display-Rendering und Button-Logik
    main.cpp           # Verbindung zwischen Mesh und Display
    MyMesh.h           # Mesh-Klasse (getNeighbourCount() hinzugefuegt)
    MyMesh.cpp         # Mesh-Implementierung
```

## Architektur

```
  main.cpp
    |
    |-- the_mesh (MyMesh)       Mesh-Netzwerk-Logik
    |     |
    |     +-- getNeighbourCount()   Anzahl Nachbar-Repeater
    |     +-- getNodePrefs()        Radio-Konfiguration
    |
    |-- radio_driver (extern)   Radio-Hardware-Treiber
    |     |
    |     +-- getPacketsRecv()      Empfangene Pakete
    |     +-- getPacketsSent()      Gesendete Pakete
    |     +-- getLastRSSI()         Letzte Signalstaerke
    |     +-- getLastSNR()          Letztes Signal-Rausch-Verhaeltnis
    |     +-- getPacketsRecvErrors() Empfangsfehler
    |
    |-- board (extern)          Board-Hardware
    |     |
    |     +-- getBattMilliVolts()   Akku-Spannung
    |
    +-- ui_task (UITask)        Display-Steuerung
          |
          +-- updateStats(UIStats)  Stats alle 2 Sekunden aktualisiert
          +-- loop()                Button lesen + Display rendern
```

### Datenfluss

1. **main.cpp** liest alle 2 Sekunden Stats aus `radio_driver`, `board` und `the_mesh`
2. Die Stats werden in eine `UIStats`-Struktur gepackt
3. `ui_task.updateStats(stats)` uebergibt die Daten an das Display
4. `ui_task.loop()` rendert den aktuellen Screen jede Sekunde

## UIStats-Struktur

```cpp
struct UIStats {
  uint32_t packets_recv;     // Empfangene Pakete gesamt
  uint32_t packets_sent;     // Gesendete Pakete gesamt
  uint32_t recv_errors;      // Empfangsfehler (CRC etc.)
  int16_t  last_rssi;        // Letzte Signalstaerke in dBm
  float    last_snr;         // Letztes SNR in dB
  uint16_t batt_mv;          // Akku-Spannung in Millivolt
  uint32_t uptime_secs;      // Laufzeit in Sekunden
  int      num_neighbours;   // Anzahl Nachbar-Repeater (1-Hop)
};
```

## Die drei Screens

### Screen 1/3: Info

```
IceRepeater          1/3
____________________________
FREQ: 869.618 SF10
BW: 62.50 CR: 5
TX: 22 dBm

v1.12.0 (29 Jan 2026)
```

Zeigt die Radio-Konfiguration. Nuetzlich um schnell zu pruefen, ob die Parameter stimmen.

### Screen 2/3: Traffic

```
Traffic              2/3
____________________________
RX: 12345
TX: 6789
Errors: 0

Up: 2d 14h
```

Zeigt die Paket-Statistiken. RX und TX sollten im Laufe der Zeit steigen. Errors sollten nahe 0 bleiben.

### Screen 3/3: Radio

```
Radio                3/3
____________________________
RSSI: -85 dBm
SNR: 7.2 dB
Batt: 4.12V

Neighbors: 3
```

Zeigt die aktuelle Signalqualitaet und den Systemstatus.

## Button-Bedienung

- **Kurzer Druck**: Naechster Screen (1/3 -> 2/3 -> 3/3 -> 1/3)
- **Druck bei ausgeschaltetem Display**: Display einschalten
- **Auto-Off**: Display schaltet nach 60 Sekunden automatisch ab

## Anpassungen vornehmen

### Neue Daten auf dem Display anzeigen

1. **UIStats erweitern** (`UITask.h`): Neues Feld hinzufuegen

```cpp
struct UIStats {
  // ... bestehende Felder ...
  float temperature;    // NEU: Temperatur vom BME280
};
```

2. **Daten befuellen** (`main.cpp`): Im Stats-Update-Block

```cpp
if (millis() >= next_stats_update) {
  UIStats stats;
  // ... bestehende Stats ...
  stats.temperature = sensors.getTemperature();  // NEU
  ui_task.updateStats(stats);
  next_stats_update = millis() + 2000;
}
```

3. **Anzeigen** (`UITask.cpp`): In einer der render-Methoden

```cpp
void UITask::renderRadioScreen() {
  // ... bestehender Code ...

  // Temperatur hinzufuegen
  _display->setCursor(70, 40);  // Position anpassen
  sprintf(tmp, "%.1fC", _stats.temperature);
  _display->print(tmp);
}
```

### Einen vierten Screen hinzufuegen

1. **Konstante aendern** (`UITask.h`):

```cpp
#define NUM_UI_SCREENS 4    // war 3
```

2. **Render-Methode deklarieren** (`UITask.h`):

```cpp
void renderMyNewScreen();   // Neue Methode
```

3. **Switch-Case erweitern** (`UITask.cpp`):

```cpp
void UITask::renderCurrScreen() {
  // ... Boot-Screen ...
  switch (_screen) {
    case 0: renderInfoScreen(); break;
    case 1: renderTrafficScreen(); break;
    case 2: renderRadioScreen(); break;
    case 3: renderMyNewScreen(); break;    // NEU
  }
}
```

4. **Render-Methode implementieren** (`UITask.cpp`):

```cpp
void UITask::renderMyNewScreen() {
  char tmp[80];

  // Titel
  _display->setCursor(0, 0);
  _display->setTextSize(1);
  _display->setColor(DisplayDriver::BLUE);
  _display->print("Mein Screen");

  // Screen-Indikator
  _display->setColor(DisplayDriver::LIGHT);
  _display->drawTextRightAlign(128, 0, "4/4");

  // Trennlinie
  _display->fillRect(0, 11, 128, 1);

  // Inhalt
  _display->setCursor(0, 16);
  _display->setColor(DisplayDriver::LIGHT);
  sprintf(tmp, "Meine Daten: %d", meinWert);
  _display->print(tmp);
}
```

### Auto-Off Zeit aendern

In `UITask.cpp`:

```cpp
#define AUTO_OFF_MILLIS  60000  // 60 Sekunden (aendern nach Bedarf)
```

Auf `0` setzen deaktiviert Auto-Off (Display immer an - verbraucht mehr Strom).

### Display-Refresh-Rate aendern

In `UITask.cpp`, in der `loop()`-Methode:

```cpp
_next_refresh = millis() + 1000;   // 1 Sekunde (aendern nach Bedarf)
```

## Display-API Referenz

Die `DisplayDriver`-Klasse bietet folgende Methoden:

| Methode | Beschreibung |
|---------|-------------|
| `startFrame(Color bkg)` | Frame beginnen (loescht Display) |
| `endFrame()` | Frame an Display senden |
| `setCursor(x, y)` | Cursor-Position setzen (Pixel) |
| `setTextSize(sz)` | Schriftgroesse (1 = 6x8 Pixel pro Zeichen) |
| `setColor(Color)` | Farbe setzen (DARK, LIGHT, RED, GREEN, BLUE, YELLOW) |
| `print(str)` | Text an Cursor-Position ausgeben |
| `fillRect(x, y, w, h)` | Gefuelltes Rechteck zeichnen |
| `drawRect(x, y, w, h)` | Rahmen-Rechteck zeichnen |
| `drawTextCentered(mid_x, y, str)` | Text zentriert ausgeben |
| `drawTextRightAlign(x, y, str)` | Text rechtsbuendig ausgeben |
| `getTextWidth(str)` | Breite eines Texts in Pixeln |
| `drawXbm(x, y, bits, w, h)` | XBM-Bitmap zeichnen |
| `turnOn()` / `turnOff()` | Display ein-/ausschalten |
| `isOn()` | Display-Status abfragen |
| `width()` / `height()` | Display-Groesse (128 x 64) |

### Farben auf dem SH1106

Da der SH1106 ein monochromes (weiss-auf-schwarz) OLED ist, werden alle Farben ausser `DARK` als weiss dargestellt. Die Farb-Enums sind fuer Kompatibilitaet mit Farb-Displays (wie dem T-Deck) vorhanden.

### Display-Layout (128x64)

```
+--128 Pixel breit----------------+
|Titel               Screen-Nr   | y=0  (Zeile 1)
|_______________________________ | y=11 (Trennlinie)
|                                 | y=16 (Zeile 2)
|Daten Zeile 1                    |
|                                 | y=28 (Zeile 3)
|Daten Zeile 2                    |
|                                 | y=40 (Zeile 4)
|Daten Zeile 3                    |
|                                 | y=54 (Zeile 5)
|Daten Zeile 4                    |
+---------------------------------+ y=64
```

Mit `setTextSize(1)` (6x8 Pixel) passen ~21 Zeichen pro Zeile und 5-6 Datenzeilen aufs Display.

## Kompilieren und Testen

Nach Aenderungen:

```bash
cd ~/MeshCore
pio run -e T_Beam_S3_Supreme_SX1262_repeater -t upload
```

Kompilierzeit: ~15 Sekunden (nur geaenderte Dateien werden neu kompiliert).
