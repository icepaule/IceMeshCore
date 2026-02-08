#!/bin/bash
# Flash MeshCore Companion Radio BLE onto LilyGo T-Deck
# Usage: ./flash-tdeck.sh [serial_port]
# Default port: /dev/ttyACM0

set -e

PORT="${1:-/dev/ttyACM0}"
VERSION="v1.12.0"
FIRMWARE_URL="https://github.com/meshcore-dev/MeshCore/releases/download/companion-${VERSION}/LilyGo_TDeck_companion_radio_ble-${VERSION}-e738a74-merged.bin"
FIRMWARE_FILE="LilyGo_TDeck_companion_radio_ble-${VERSION}-merged.bin"

# Check esptool
if ! command -v esptool &> /dev/null && ! command -v esptool.py &> /dev/null; then
    echo "ERROR: esptool not found. Install with: pip3 install esptool"
    exit 1
fi
ESPTOOL=$(command -v esptool || command -v esptool.py)

# Check serial port
if [ ! -e "$PORT" ]; then
    echo "ERROR: Serial port $PORT not found!"
    echo "Available ports:"
    ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || echo "  None found. Is the T-Deck connected via USB?"
    exit 1
fi

# Download firmware if not present
if [ ! -f "$FIRMWARE_FILE" ]; then
    echo "Downloading firmware ${VERSION}..."
    curl -sL "$FIRMWARE_URL" -o "$FIRMWARE_FILE"
    echo "Downloaded: $FIRMWARE_FILE ($(stat -c%s "$FIRMWARE_FILE") bytes)"
fi

echo ""
echo "=== MeshCore T-Deck Flasher ==="
echo "Port:     $PORT"
echo "Firmware: $FIRMWARE_FILE"
echo "Version:  $VERSION"
echo ""
echo "IMPORTANT: Hold the BOOT button on the T-Deck while pressing RST to enter bootloader mode."
echo ""
read -p "Press Enter when ready to flash..."

$ESPTOOL --port "$PORT" --baud 921600 --chip esp32s3 write_flash 0x0 "$FIRMWARE_FILE"

echo ""
echo "=== Flash complete! ==="
echo ""
echo "Default BLE PIN: 123456"
echo ""
echo "Next steps:"
echo "  1. Download MeshCore app (Android/iOS)"
echo "  2. Pair via Bluetooth using PIN 123456"
echo "  3. Set frequency to 868.0 MHz (EU)"
echo "  4. Set your node name"
echo "  5. Send a 'Flood Routed Advertisement'"
