#!/bin/bash
# Build and flash MeshCore Repeater firmware for T-Beam Supreme SX1262
#
# Usage: ./build-tbeam-supreme.sh [serial_port]
# Default port: /dev/ttyACM0
#
# Prerequisites:
#   - PlatformIO installed (pip3 install platformio)
#   - MeshCore source cloned (git clone https://github.com/meshcore-dev/MeshCore.git)
#   - Config copied and edited (see docs/flash-tbeam-supreme.md)

set -e

PORT="${1:-/dev/ttyACM0}"
MESHCORE_DIR="${MESHCORE_DIR:-$(dirname "$0")/../../MeshCore}"
ENV="T_Beam_S3_Supreme_SX1262_repeater"
INI_FILE="$MESHCORE_DIR/variants/lilygo_tbeam_supreme_SX1262/platformio.ini"

echo "=== MeshCore T-Beam Supreme Repeater Builder ==="
echo ""

# Check PlatformIO
if ! command -v pio &> /dev/null; then
    echo "FEHLER: PlatformIO nicht gefunden."
    echo "Installieren mit: pip3 install platformio --break-system-packages"
    exit 1
fi

# Check MeshCore source
if [ ! -d "$MESHCORE_DIR" ]; then
    echo "FEHLER: MeshCore-Quellcode nicht gefunden: $MESHCORE_DIR"
    echo ""
    echo "Klonen mit:"
    echo "  git clone https://github.com/meshcore-dev/MeshCore.git"
    echo ""
    echo "Oder MESHCORE_DIR setzen:"
    echo "  MESHCORE_DIR=/pfad/zu/MeshCore ./build-tbeam-supreme.sh"
    exit 1
fi

# Check config file exists
if [ ! -f "$INI_FILE" ]; then
    echo "FEHLER: Konfigurationsdatei nicht gefunden: $INI_FILE"
    echo ""
    echo "Kopiere die Vorlage:"
    echo "  cp configs/tbeam_supreme_sx1262_repeater.ini $INI_FILE"
    echo ""
    echo "Dann Repeater-Name und Admin-Passwort anpassen."
    exit 1
fi

# Check admin password is changed
if grep -q "CHANGE_THIS_PASSWORD" "$INI_FILE" 2>/dev/null; then
    echo "WARNUNG: Admin-Passwort wurde nicht geaendert!"
    echo "Bearbeite: $INI_FILE"
    echo "Aendere ADMIN_PASSWORD auf ein sicheres Passwort."
    echo ""
    read -p "Trotzdem fortfahren (mit Standard-Passwort)? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Show config
REPEATER_NAME=$(grep "ADVERT_NAME" "$INI_FILE" | head -1 | sed "s/.*'\"\(.*\)\"'.*/\1/")
echo "Konfiguration:"
echo "  Environment: $ENV"
echo "  Repeater:    $REPEATER_NAME"
echo "  Port:        $PORT"
echo "  Quellcode:   $MESHCORE_DIR"
echo ""

# Build
echo "Kompiliere Firmware..."
cd "$MESHCORE_DIR"
pio run -e "$ENV"

echo ""
echo "Kompilierung erfolgreich!"
echo ""

# Flash
if [ -e "$PORT" ]; then
    # Show device info
    USB_INFO=$(lsusb 2>/dev/null | grep -i "esp\|jtag\|serial\|lilygo" | head -1)
    if [ -n "$USB_INFO" ]; then
        echo "Erkanntes Geraet: $USB_INFO"
    fi
    echo ""

    read -p "Firmware auf $PORT flashen? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Flashe..."
        pio run -e "$ENV" -t upload --upload-port "$PORT"
        echo ""
        echo "=== Flash erfolgreich! ==="
        echo ""
        echo "Der Repeater '$REPEATER_NAME' startet jetzt neu."
        echo "Das OLED-Display sollte nach ~4 Sekunden den Info-Screen zeigen."
        echo ""
        echo "Serial-Monitor starten mit:"
        echo "  pio run -e $ENV -t monitor --upload-port $PORT"
    fi
else
    echo "Serieller Port $PORT nicht gefunden."
    echo ""
    echo "T-Beam Supreme per USB-C anschliessen, dann:"
    echo "  pio run -e $ENV -t upload --upload-port /dev/ttyACM0"
    echo ""
    echo "Falls der Port anders heisst:"
    echo "  ls /dev/ttyACM* /dev/ttyUSB*"
fi
