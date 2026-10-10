<<<<<<< HEAD
# Ultrasonic Level Transmitter Calibration System

**Course Project:** B.Tech Instrumentation & Control Engineering (ICE) — Semester 3  
**Topic:** Calibration of Ultrasonic Level Transmitter using Gaussian Curve Fitting & Error Analysis  

---

## 📌 Project Overview
This project focuses on the modeling, calibration, firmware design, and error estimation for an **Ultrasonic Level Transmitter** system (utilizing HC-SR04 / JSN-SR04T sensor). Ultrasonic sensors measure liquid level non-contactually based on the **Time-of-Flight (ToF)** principle. However, environmental variations (temperature, air density, humidity), sensor non-linearities, and mounting geometry cause measurement deviations.

To achieve industrial accuracy standards (e.g., 4–20 mA current loop transmission), this project implements a **Gaussian Elimination least-squares matrix solver** to derive optimal linear and polynomial calibration parameters ($m$ gain, $c$ offset), evaluating key static characteristics:
* **Zero & Span Errors**
* **Sensitivity ($\Delta V / \Delta L$ or $\Delta I / \Delta L$)**
* **Linearity Error (% FSR)**
* **Hysteresis (% FSR)**
* **Accuracy & Repeatability**

---

## 📁 Repository Structure

```text
├── README.md                               ← Project overview & usage guide
├── codes/
│   ├── level_calibration_gauss.py          ← Python calibration & curve fitting solver (Run first)
│   ├── level_calibration_gauss.m           ← MATLAB version of Gaussian solver & plots
│   ├── Level_Calibration.ino               ← Arduino C++ firmware with filtering & calibration
│   └── generate_report.py                  ← Script generating PDF, DOCX, & PNG reports
├── diagrams/
│   └── circuit_diagram.txt                 ← ASCII schematic & wiring pinout table
└── reports/
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.pdf   ← Complete PDF calibration report
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.docx  ← Editable Word document report
    ├── calibration_curve.png               ← High-res calibration & error plots
    └── Presentation_Outline.txt            ← Viva & project presentation slide outline
```

---

## ⚡ Quick Start Guide

### 1. Requirements
- **Python 3.8+** with `numpy`, `matplotlib`, `scipy`, `reportlab`, `python-docx`
- **Arduino IDE 1.8+** or Arduino CLI (for `.ino` firmware compilation)
- **MATLAB R2020a+** (optional, for `.m` verification)

### 2. Running Python Verification Script
To run the Gaussian curve fitting solver and view calibration error metrics directly:
```bash
python codes/level_calibration_gauss.py
```

### 3. Generating Complete Reports & Plots
To automatically create `calibration_curve.png`, PDF report, and Word DOCX report in the `reports/` directory:
```bash
python codes/generate_report.py
```

---

## 🔬 Mathematical Formulation

### Time of Flight (ToF) Principle
The distance $d$ from the ultrasonic transducer to the liquid surface is given by:
$$d = \frac{v_{\text{sound}} \cdot t}{2}$$
where $v_{\text{sound}} \approx 331.3 + 0.606 \times T \, (\text{m/s})$ at ambient temperature $T \, (^\circ\text{C})$.  
The liquid level $L$ inside a vessel of total height $H$ is:
$$L = H - d$$

### Gaussian Elimination Least-Squares Matrix Fitting
For a linear calibration relation $y = a_1 x + a_0$ between True Level $x_i$ and Measured Output $y_i$:
$$\begin{bmatrix} \sum x_i^2 & \sum x_i \\ \sum x_i & N \end{bmatrix} \begin{bmatrix} a_1 \\ a_0 \end{bmatrix} = \begin{bmatrix} \sum x_i y_i \\ \sum y_i \end{bmatrix}$$

Using Gaussian elimination with partial pivoting:
1. Construct augmented matrix $[A | B]$.
2. Perform forward elimination to transform $A$ into upper triangular form.
3. Perform back-substitution to solve for slope $a_1$ and intercept $a_0$.

---

## 📊 Summary of Calibration Metrics

| Metric | Formula / Description | Target Value |
|---|---|---|
| **Zero Error** | $y(x=0) - y_{\text{ideal}}(0)$ | $\le \pm 0.5\%$ FSR |
| **Span Error** | $[y(x_{\max}) - y(0)] - \text{Ideal Span}$ | $\le \pm 0.5\%$ FSR |
| **Linearity Error** | $\frac{\max|y_{\text{meas}} - y_{\text{fit}}|}{\text{FSR}} \times 100\%$ | $\le \pm 1.0\%$ FSR |
| **Hysteresis** | $\frac{\max|y_{\text{up}} - y_{\text{down}}|}{\text{FSR}} \times 100\%$ | $\le \pm 0.8\%$ FSR |
| **Sensitivity** | $\frac{\Delta V}{\Delta L}$ (V/cm) | $0.040 \text{ V/cm}$ (1-5V / 0-100cm) |

---

## 🛠 Hardware Specifications & Connections
- **Microcontroller:** Arduino Uno / Nano (ATmega328P)
- **Sensor:** HC-SR04 / JSN-SR04T Waterproof Ultrasonic Transducer
- **Display:** 16x2 LCD via PCF8574 I2C Backpack
- **Transmitter Interface:** PWM (Pin 3) with RC filter & Op-Amp LM358 for 4-20mA / 1-5V industrial output.

Refer to [`diagrams/circuit_diagram.txt`](file:///d:/B.Tech%20S.Y%20ICE%2026-27/3th%20semester/Project/Ultrasonic_Level_Transmitter_Calibration/diagrams/circuit_diagram.txt) for full schematic wiring.

---

## 📜 License & Authors
Developed for B.Tech ICE Semester 3 Project — Ultrasonic Level Transmitter Calibration System.
=======
# Ultrasonic Level Transmitter Calibration
## Numerical Methods Mini-Project (Arduino UNO + HC-SR04 + Gauss Elimination)

### Project Title
**Calibration of Ultrasonic Level Transmitter using Arduino UNO and Gauss Elimination Method**

### Why this project?
- Extremely simple and cheap hardware
- Easy experimental data collection (just pour water + ruler)
- Clear industrial flavour (level transmitter)
- Uses Gauss Elimination (syllabus method) meaningfully
- Full loop: Measurement → Numerical Computation → Display + Control
- Excellent error performance (RMSE ≈ 0.15 cm)

### Folder Structure
```
Ultrasonic_Level_Transmitter_Calibration/
├── README.md
├── codes/
│   ├── level_calibration_gauss.py   ← Run first (Python verification)
│   ├── level_calibration_gauss.m    ← MATLAB version
│   ├── Level_Calibration.ino        ← Arduino firmware
│   └── generate_report.py
├── diagrams/
│   └── circuit_diagram.txt
└── reports/
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.pdf
    ├── Ultrasonic_Level_Transmitter_Calibration_Report.docx
    ├── calibration_curve.png
    └── Presentation_Outline.txt
```

### Quick Start
1. Run verification:
   ```bash
   cd codes
   python3 level_calibration_gauss.py
   ```
2. Wire hardware according to `diagrams/circuit_diagram.txt`
3. Upload `Level_Calibration.ino`
4. Collect your own 5 points with ruler, update coefficients, re-upload

### Key Results (Sample Data)
- Calibration formula: **Level = 32.6081 − 0.998249 × Distance**
- Calibrated RMSE = **0.149 cm**
- Very close to ideal linear behaviour after calibration

### Hardware Required (Cheap)
- Arduino UNO
- HC-SR04 Ultrasonic sensor
- 16×2 I2C LCD
- 2 LEDs + resistors
- Breadboard, jumpers
- Plastic bottle/tank + ordinary ruler

Replace student name in the reports before submission.
>>>>>>> 79a392ae3a07bcecb962858f4711c69c548a4c4c
