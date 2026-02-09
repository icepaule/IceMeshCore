#!/usr/bin/env python3
"""Download OpenStreetMap tiles for MeshCore T-Deck offline maps.
Tiles are saved in /tiles/{z}/{x}/{y}.png format for the SD card.
"""

import os
import sys
import math
import time
import urllib.request
import concurrent.futures
from pathlib import Path

# Germany + Austria bounding box
MIN_LAT = 46.37   # Southern Austria
MAX_LAT = 55.06   # Northern Germany
MIN_LON = 5.87    # Western Germany
MAX_LON = 16.95   # Eastern Austria

# Output directory (mount SD card here)
OUTPUT_DIR = "/mnt/sdcard/tiles"

# Zoom levels to download
MIN_ZOOM = 1
MAX_ZOOM = 13

# Rate limiting
MAX_WORKERS = 3
DELAY_PER_REQUEST = 0.15  # seconds between requests per worker

# OSM tile servers (rotate between them)
TILE_SERVERS = [
    "https://a.tile.openstreetmap.org",
    "https://b.tile.openstreetmap.org",
    "https://c.tile.openstreetmap.org",
]

USER_AGENT = "MeshCore-TileDownloader/1.0 (offline map cache)"

server_idx = 0

def lat_lon_to_tile(lat, lon, zoom):
    """Convert lat/lon to tile x,y coordinates."""
    lat_rad = math.radians(lat)
    n = 2 ** zoom
    x = int((lon + 180.0) / 360.0 * n)
    y = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return x, y

def get_tile_ranges(zoom):
    """Get x,y tile ranges for the bounding box at given zoom."""
    x_min, y_min = lat_lon_to_tile(MAX_LAT, MIN_LON, zoom)
    x_max, y_max = lat_lon_to_tile(MIN_LAT, MAX_LON, zoom)
    return x_min, x_max, y_min, y_max

def count_tiles():
    """Count total tiles to download."""
    total = 0
    for z in range(MIN_ZOOM, MAX_ZOOM + 1):
        x_min, x_max, y_min, y_max = get_tile_ranges(z)
        count = (x_max - x_min + 1) * (y_max - y_min + 1)
        total += count
        print(f"  Zoom {z:2d}: {count:>8,} tiles  (x:{x_min}-{x_max}, y:{y_min}-{y_max})")
    return total

def download_tile(args):
    """Download a single tile."""
    global server_idx
    z, x, y = args

    filepath = Path(OUTPUT_DIR) / str(z) / str(x) / f"{y}.png"

    # Skip if already exists
    if filepath.exists() and filepath.stat().st_size > 0:
        return "skip"

    filepath.parent.mkdir(parents=True, exist_ok=True)

    server = TILE_SERVERS[server_idx % len(TILE_SERVERS)]
    server_idx += 1
    url = f"{server}/{z}/{x}/{y}.png"

    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    for attempt in range(3):
        try:
            time.sleep(DELAY_PER_REQUEST)
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = resp.read()
                filepath.write_bytes(data)
                return "ok"
        except Exception as e:
            if attempt == 2:
                return f"err:{e}"
            time.sleep(2 ** attempt)

    return "err:max_retries"

def main():
    if len(sys.argv) > 1:
        global OUTPUT_DIR
        OUTPUT_DIR = sys.argv[1]

    print(f"=== MeshCore Map Tile Downloader ===")
    print(f"Region: Germany + Austria")
    print(f"Bbox: lat {MIN_LAT}-{MAX_LAT}, lon {MIN_LON}-{MAX_LON}")
    print(f"Zoom: {MIN_ZOOM}-{MAX_ZOOM}")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Workers: {MAX_WORKERS}")
    print()
    print("Tile count per zoom level:")
    total = count_tiles()
    print(f"\nTotal: {total:,} tiles")
    print(f"Estimated size: ~{total * 15 // 1024} MB (avg 15KB/tile)")
    print(f"Estimated time: ~{total * DELAY_PER_REQUEST / MAX_WORKERS / 60:.0f} minutes")
    print()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Generate all tile coordinates
    tiles = []
    for z in range(MIN_ZOOM, MAX_ZOOM + 1):
        x_min, x_max, y_min, y_max = get_tile_ranges(z)
        for x in range(x_min, x_max + 1):
            for y in range(y_min, y_max + 1):
                tiles.append((z, x, y))

    downloaded = 0
    skipped = 0
    errors = 0
    start_time = time.time()

    print(f"Downloading {len(tiles):,} tiles...")

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(download_tile, t): t for t in tiles}

        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if result == "ok":
                downloaded += 1
            elif result == "skip":
                skipped += 1
            else:
                errors += 1

            done = downloaded + skipped + errors
            if done % 500 == 0 or done == len(tiles):
                elapsed = time.time() - start_time
                rate = downloaded / elapsed if elapsed > 0 else 0
                eta = (len(tiles) - done) / (done / elapsed) if done > 0 and elapsed > 0 else 0
                print(f"  Progress: {done:,}/{len(tiles):,} | Downloaded: {downloaded:,} | Skipped: {skipped:,} | Errors: {errors} | {rate:.1f} tiles/s | ETA: {eta/60:.0f}min")

    elapsed = time.time() - start_time
    print(f"\n=== Complete ===")
    print(f"Downloaded: {downloaded:,} tiles")
    print(f"Skipped (existing): {skipped:,}")
    print(f"Errors: {errors}")
    print(f"Time: {elapsed/60:.1f} minutes")

    # Calculate total size
    total_size = 0
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            total_size += os.path.getsize(os.path.join(root, f))
    print(f"Total size: {total_size / 1024 / 1024:.0f} MB")

if __name__ == "__main__":
    main()
