# Calibration of Ultrasonic Level Transmitter using Arduino UNO and Gauss Elimination Method

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Arduino](https://img.shields.io/badge/Arduino-UNO-00979D?logo=arduino&logoColor=white)](codes/Level_Calibration.ino)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2019a%2B-orange?logo=mathworks)](codes/level_calibration_gauss.m)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?logo=python&logoColor=white)](requirements.txt)

> **B.Tech Instrumentation & Control Engineering — Semester 3 | Numerical Methods Project**

---

## Project Overview

This project implements a complete **hardware + software calibration system** for an Ultrasonic Level Transmitter. It demonstrates the application of **Gauss Elimination Method** (a core Numerical Methods algorithm) in a real industrial instrumentation context.

The system continuously measures water level inside a tank using an **HC-SR04 ultrasonic sensor** connected to an **Arduino UNO**. The raw distance data is calibrated using a **linear regression model solved by Gauss Elimination on Normal Equations**. A **relay module** controls a water pump with hysteresis, **two LEDs** serve as visual indicators, and a live **web-based HMI dashboard** and **MATLAB GUI** display real-time data.

---

## System Architecture

```
                   ┌─────────────────────────────────────┐
                   │         PHYSICAL HARDWARE            │
                   │                                      │
   Water Tank      │  HC-SR04 ──► Arduino UNO ──► Relay  │
   (0–30 cm)       │               │                │    │
                   │              LED                Pump │
                   └───────────────┼─────────────────────┘
                                   │ Serial (115200 baud)
                          ─────────┼─────────────────────
                         │         ▼                      │
                         │  serial_bridge.py              │
                         │  (Python WebSocket server)     │
                         │         │                      │
                         │   ws://localhost:8765          │
                         │         ▼                      │
                         │  dashboard/index.html          │
                         │  (Web HMI — Browser)           │
                          ────────────────────────────────
                                   │
                            ───────┴───────
                           │               │
                      MATLAB GUI       Browser HMI
                   (level_calibration  (app.js runs
                    _gauss.m — reads    Gauss Elim in
                    COM port directly)  JavaScript)
```

---

## Hardware Components

| Component | Model | Purpose |
|---|---|---|
| Microcontroller | **Arduino UNO** (ATmega328P) | Main controller |
| Ultrasonic Sensor | **HC-SR04** | Distance / level measurement |
| Relay Module | 5V single-channel (active-LOW) | Water pump control |
| Green LED | Any 5mm LED + 220Ω resistor | Normal / LOW level indicator |
| Red LED | Any 5mm LED + 220Ω resistor | HIGH level / Pump ON indicator |
| Water Container | Transparent tank / bottle | Test vessel |

---

## Wiring Diagram

```
Arduino UNO          HC-SR04
──────────           ───────
Pin 9  ──────────►  TRIG
Pin 8  ◄──────────  ECHO
5V     ──────────►  VCC
GND    ──────────►  GND

Arduino UNO          Relay Module (Active-LOW)
──────────           ─────────────────────────
Pin 7  ──────────►  IN
5V     ──────────►  VCC
GND    ──────────►  GND
                     COM ──► Pump +ve
                     NO  ──► Power +ve  (Normally Open → Pump OFF by default)

Arduino UNO          LEDs
──────────           ────
Pin 6  ──► 220Ω ──► GREEN LED (+) ──► GND   (Normal / LOW)
Pin 5  ──► 220Ω ──► RED LED   (+) ──► GND   (HIGH / Pump ON)
```

---

## Repository Structure

```
Ultrasonic_Level_Transmitter_Calibration/
│
├── README.md                          ← This file
├── LICENSE                            ← MIT License
├── requirements.txt                   ← Python dependencies
├── .gitignore
│
├── codes/
│   ├── Level_Calibration.ino          ← Arduino UNO firmware (HC-SR04 + Relay + LEDs)
│   ├── level_calibration_gauss.m      ← MATLAB HMI — live COM port reading + Gauss Elim
│   ├── level_calibration_gauss.py     ← Python standalone calibration analysis
│   ├── serial_bridge.py               ← Python WebSocket bridge (Arduino → Web Dashboard)
│   └── generate_report.py             ← Auto-generates PDF + DOCX + PNG calibration report
│
├── dashboard/
│   ├── index.html                     ← Web HMI Dashboard (open in browser)
│   ├── style.css                      ← Dark glassmorphism UI stylesheet
│   └── app.js                         ← WebSocket client + Chart.js + Gauss Elim in JS
│
├── diagrams/
│   └── circuit_diagram.txt            ← ASCII schematic & pinout table
│
└── reports/
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.pdf
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.docx
    ├── calibration_curve.png
    └── Presentation_Outline.txt
```

---

## Quick Start Guide

### Step 1 — Hardware Setup
1. Wire components as per the **Wiring Diagram** above.
2. Upload `codes/Level_Calibration.ino` to Arduino UNO using Arduino IDE.
3. Open Arduino Serial Monitor at **115200 baud** to verify output:
   ```
   DIST,21.45,LEVEL,11.52,PCT,38.4,RELAY,0
   ```

### Step 2 — Update Calibration Coefficients
1. Fill the tank to known levels (use a ruler as reference).
2. Collect 5–10 (Distance, Level) data point pairs.
3. Run Gauss Elimination in any of these ways:
   - **MATLAB:** Run `level_calibration_gauss.m` — GUI handles everything.
   - **Web Dashboard:** Use the Calibration panel → click **RUN GAUSS ELIMINATION**.
   - **Python:** Run `python codes/level_calibration_gauss.py`.
4. Copy the resulting `a0` and `a1` values into `Level_Calibration.ino`:
   ```cpp
   const float COEFF_A0 = 32.6081f;   // ← update this
   const float COEFF_A1 = -0.9982f;   // ← update this
   ```
5. Re-upload the sketch.

### Step 3A — MATLAB HMI
```matlab
% In MATLAB, change COM_PORT on line 1, then run:
run('codes/level_calibration_gauss.m')
```
The MATLAB GUI will open, showing:
- Live level trend chart
- Real-time status panel (distance, level %, pump state)
- Gauss Elimination calibration with one click

### Step 3B — Web Dashboard HMI
```bash
# 1. Install Python dependencies
pip install -r requirements.txt

# 2. Start the serial-to-WebSocket bridge
python codes/serial_bridge.py --port COM3

# 3. Open the dashboard in your browser
#    Just double-click:  dashboard/index.html
#    Or navigate to it in your browser (File → Open)
```
> If no Arduino is connected, the dashboard automatically enters **Demo Mode** with simulated data.

---

## Numerical Method: Gauss Elimination

The calibration model is:

```
Level (cm) = a₀ + a₁ × Distance (cm)
```

### Normal Equations (Least-Squares Linear Fit)

For n measured points (Dᵢ, Lᵢ):

```
[ n      ΣDᵢ  ] [ a₀ ]   [ ΣLᵢ    ]
[ ΣDᵢ   ΣDᵢ² ] [ a₁ ] = [ ΣDᵢLᵢ  ]
```

### Gauss Elimination with Partial Pivoting

1. Form augmented matrix **[A | b]**
2. **Forward Elimination**: For each pivot column k, find the row with the largest absolute value (partial pivoting), swap rows, then eliminate below
3. **Back Substitution**: Solve for a₁, then a₀

This is implemented identically in:
- `Level_Calibration.ino` (Arduino C++)
- `level_calibration_gauss.m` (MATLAB)
- `level_calibration_gauss.py` (Python)
- `dashboard/app.js` (JavaScript)

---

## Calibration Metrics

| Metric | Description |
|---|---|
| **RMSE** | Root Mean Square Error between fitted and measured levels |
| **R²** | Coefficient of determination (1.0 = perfect fit) |
| **a₀** | Intercept — zero offset correction |
| **a₁** | Slope — sensitivity (cm level per cm distance) |

### Sample Results (5 calibration points)

| Point | Distance (cm) | True Level (cm) | Fitted Level (cm) | Error (cm) |
|:---:|:---:|:---:|:---:|:---:|
| 1 | 28.5 | 4.0 | 4.11 | -0.11 |
| 2 | 23.2 | 9.5 | 9.41 | +0.09 |
| 3 | 18.1 | 14.8 | 14.77 | +0.03 |
| 4 | 13.4 | 19.2 | 19.46 | -0.26 |
| 5 | 8.0 | 24.5 | 24.24 | +0.26 |

**RMSE ≈ 0.149 cm &ensp;|&ensp; R² ≈ 0.9998**

---

## Pump Control Logic (Hysteresis)

```
Level ≥ 22 cm → Relay ON  (Pump runs to drain / fill)
Level ≤  8 cm → Relay OFF (Pump stops)
```

Hysteresis band prevents rapid on/off cycling near the threshold.

---

## Requirements

| Tool | Minimum Version | Purpose |
|---|---|---|
| Arduino IDE | 1.8+ | Upload `.ino` firmware |
| Python | 3.8+ | Serial bridge + standalone analysis |
| MATLAB | R2019a+ | MATLAB HMI GUI |
| Any modern browser | Chrome/Firefox/Edge | Web HMI Dashboard |

Python packages: see [`requirements.txt`](requirements.txt)

---

## License

MIT License — see [LICENSE](LICENSE) for full text.

---

## Authors

Developed as **Semester 3 Numerical Methods Project** — B.Tech Instrumentation & Control Engineering.

> *This project demonstrates that Gauss Elimination, a fundamental numerical algorithm, has direct real-world application in industrial sensor calibration.*
