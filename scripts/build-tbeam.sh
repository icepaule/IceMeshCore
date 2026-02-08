#!/bin/bash
# Build and flash MeshCore WiFi Companion Radio for T-Beam SX1276
# Usage: ./build-tbeam.sh [serial_port]
# Default port: /dev/ttyACM0

set -e

PORT="${1:-/dev/ttyACM0}"
MESHCORE_DIR="${MESHCORE_DIR:-$(dirname "$0")/../../MeshCore}"
ENV="Tbeam_SX1276_companion_radio_wifi"

# Check PlatformIO
if ! command -v pio &> /dev/null; then
    echo "ERROR: PlatformIO not found. Install with: pip3 install platformio"
    exit 1
fi

# Check MeshCore source
if [ ! -d "$MESHCORE_DIR" ]; then
    echo "MeshCore source not found at: $MESHCORE_DIR"
    echo "Clone it: git clone https://github.com/meshcore-dev/MeshCore.git"
    exit 1
fi

# Check WiFi credentials are set
INI_FILE="$MESHCORE_DIR/variants/lilygo_tbeam_SX1276/platformio.ini"
if grep -q "YOUR_WIFI_SSID" "$INI_FILE" 2>/dev/null; then
    echo "ERROR: WiFi credentials not set!"
    echo "Edit: $INI_FILE"
    echo "Replace YOUR_WIFI_SSID and YOUR_WIFI_PASSWORD with your actual credentials."
    exit 1
fi

echo "=== MeshCore T-Beam Builder ==="
echo "Environment: $ENV"
echo "Port:        $PORT"
echo "Source:      $MESHCORE_DIR"
echo ""

# Build
echo "Building firmware..."
cd "$MESHCORE_DIR"
pio run -e "$ENV"

echo ""
echo "Build successful!"
echo ""

# Flash
if [ -e "$PORT" ]; then
    read -p "Flash to $PORT? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pio run -e "$ENV" -t upload --upload-port "$PORT"
        echo ""
        echo "=== Flash complete! ==="
    fi
else
    echo "Serial port $PORT not found. Connect the T-Beam and run:"
    echo "  pio run -e $ENV -t upload --upload-port /dev/ttyACM0"
fi
