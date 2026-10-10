"""
serial_bridge.py
================
Reads live data from Arduino (via COM port) and serves it to
the web dashboard over a simple HTTP + WebSocket interface.

Usage:
    pip install pyserial websockets
    python codes/serial_bridge.py --port COM3

The web dashboard at dashboard/index.html connects to
ws://localhost:8765 to receive JSON messages.

JSON message format (sent every sample):
{
  "dist":  <float>,   // HC-SR04 raw distance (cm)
  "level": <float>,   // Calibrated water level (cm)
  "pct":   <float>,   // Fill percentage (%)
  "relay": <int>      // 1 = pump ON, 0 = pump OFF
}
"""

import asyncio
import json
import argparse
import sys
import threading
import time
from datetime import datetime

try:
    import serial
except ImportError:
    print("[ERROR] pyserial not installed. Run: pip install pyserial")
    sys.exit(1)

try:
    import websockets
except ImportError:
    print("[ERROR] websockets not installed. Run: pip install websockets")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Shared state between serial reader thread and websocket server
# ---------------------------------------------------------------------------
latest_data = {
    "dist":  0.0,
    "level": 0.0,
    "pct":   0.0,
    "relay": 0,
    "ts":    ""
}
connected_clients = set()
data_lock = threading.Lock()

# ---------------------------------------------------------------------------
def parse_arduino_line(line: str) -> dict | None:
    """
    Parse CSV line from Arduino:
      DIST,<cm>,LEVEL,<cm>,PCT,<%>,RELAY,<0|1>
    Returns dict or None on parse failure.
    """
    line = line.strip()
    if not line or line.startswith("#"):
        return None
    try:
        parts = line.split(",")
        if len(parts) != 8:
            return None
        return {
            "dist":  float(parts[1]),
            "level": float(parts[3]),
            "pct":   float(parts[5]),
            "relay": int(parts[7]),
            "ts":    datetime.now().strftime("%H:%M:%S")
        }
    except (ValueError, IndexError):
        return None

# ---------------------------------------------------------------------------
def serial_reader(port: str, baud: int):
    """Background thread: reads from serial and updates latest_data."""
    global latest_data
    print(f"[SERIAL] Opening {port} at {baud} baud ...")
    try:
        ser = serial.Serial(port, baud, timeout=2)
    except serial.SerialException as e:
        print(f"[SERIAL ERROR] {e}")
        return

    print(f"[SERIAL] Connected to {port}")
    while True:
        try:
            raw = ser.readline().decode("utf-8", errors="replace")
            parsed = parse_arduino_line(raw)
            if parsed:
                with data_lock:
                    latest_data.update(parsed)
                print(f"[DATA] Dist={parsed['dist']:.2f}cm  "
                      f"Level={parsed['level']:.2f}cm  "
                      f"Fill={parsed['pct']:.1f}%  "
                      f"Pump={'ON' if parsed['relay'] else 'OFF'}")
        except serial.SerialException as e:
            print(f"[SERIAL ERROR] {e}")
            time.sleep(2)
        except Exception:
            pass

# ---------------------------------------------------------------------------
async def ws_handler(websocket):
    """WebSocket handler — streams data to each connected browser."""
    connected_clients.add(websocket)
    print(f"[WS] Client connected. Total: {len(connected_clients)}")
    try:
        while True:
            with data_lock:
                payload = json.dumps(latest_data)
            await websocket.send(payload)
            await asyncio.sleep(0.5)   # 2 Hz push rate
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        connected_clients.discard(websocket)
        print(f"[WS] Client disconnected. Total: {len(connected_clients)}")

# ---------------------------------------------------------------------------
async def main_async(port: str, baud: int, ws_port: int):
    # Start serial reader in a daemon thread
    t = threading.Thread(target=serial_reader, args=(port, baud), daemon=True)
    t.start()

    print(f"[WS]  WebSocket server starting on ws://localhost:{ws_port}")
    print(f"[WEB] Open dashboard/index.html in your browser.")
    print("[INFO] Press Ctrl+C to stop.\n")

    async with websockets.serve(ws_handler, "localhost", ws_port):
        await asyncio.Future()  # run forever

# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Serial -> WebSocket bridge for Ultrasonic Level Transmitter Dashboard"
    )
    parser.add_argument("--port",    default="COM3",  help="Arduino COM port (default: COM3)")
    parser.add_argument("--baud",    default=115200, type=int, help="Baud rate (default: 115200)")
    parser.add_argument("--ws-port", default=8765,   type=int, help="WebSocket port (default: 8765)")
    args = parser.parse_args()

    try:
        asyncio.run(main_async(args.port, args.baud, args.ws_port))
    except KeyboardInterrupt:
        print("\n[EXIT] Bridge stopped.")
