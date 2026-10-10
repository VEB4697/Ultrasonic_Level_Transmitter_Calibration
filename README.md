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
