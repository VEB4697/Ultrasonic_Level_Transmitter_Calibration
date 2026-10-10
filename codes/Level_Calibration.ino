/*
<<<<<<< HEAD
 * Ultrasonic Level Transmitter Firmware with Calibration Correction
 * Author: B.Tech ICE S.Y. Project Team
 * File: codes/Level_Calibration.ino
 * 
 * Hardware:
 *   - Arduino Uno / Nano (ATmega328P)
 *   - HC-SR04 or Waterproof JSN-SR04T Ultrasonic Distance Sensor
 *   - I2C LCD Display (16x2)
 *   - PWM to 4-20mA Signal Conditioning Module (Pin 3)
 */

#include <Wire.h>

// -------------------------------------------------------------
// Pin Definitions
// -------------------------------------------------------------
const int TRIG_PIN    = 9;    // Ultrasonic Trigger
const int ECHO_PIN    = 8;    // Ultrasonic Echo
const int PWM_OUT_PIN = 3;    // 4-20mA Transmitter PWM output
const int TEMP_PIN    = A0;   // LM35 Temperature Sensor (Optional)

// -------------------------------------------------------------
// Tank & Sensor Parameters
// -------------------------------------------------------------
const float TANK_HEIGHT_CM = 100.0;  // Total vessel height from sensor face to tank bottom
const int   FILTER_SAMPLES = 10;     // Number of moving average samples

// -------------------------------------------------------------
// Calibrated Coefficients (Derived from Gaussian Fitting)
// V_out = GAUSS_SLOPE * Level_cm + GAUSS_OFFSET
// -------------------------------------------------------------
float gauss_slope  = 0.03964;  // V/cm (Calibrated sensitivity)
float gauss_offset = 1.02182;  // V at 0 cm (Calibrated zero offset)

// Default ambient temperature (deg C) if temperature sensor not present
float ambient_temp_c = 25.0;

// -------------------------------------------------------------
// Setup
// -------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(PWM_OUT_PIN, OUTPUT);
  
  digitalWrite(TRIG_PIN, LOW);
  
  Serial.println(F("===================================================="));
  Serial.println(F("   ULTRASONIC LEVEL TRANSMITTER FIRMWARE READY     "));
  Serial.println(F("===================================================="));
  Serial.println(F("Commands: 'CAL_ZERO' | 'CAL_SPAN' | 'STATUS'"));
  Serial.println(F("----------------------------------------------------"));
}

// -------------------------------------------------------------
// Main Loop
// -------------------------------------------------------------
void loop() {
  // 1. Measure raw distance with moving average filter
  float raw_distance_cm = readFilteredDistanceCm(FILTER_SAMPLES);
  
  // 2. Compute liquid level (Level = Tank_Height - Distance)
  float raw_level_cm = TANK_HEIGHT_CM - raw_distance_cm;
  if (raw_level_cm < 0.0) raw_level_cm = 0.0;
  if (raw_level_cm > TANK_HEIGHT_CM) raw_level_cm = TANK_HEIGHT_CM;
  
  // 3. Apply Calibrated Correction (Transmitter Output Voltage: 1V to 5V)
  float calibrated_voltage = (gauss_slope * raw_level_cm) + gauss_offset;
  if (calibrated_voltage < 1.0) calibrated_voltage = 1.0;
  if (calibrated_voltage > 5.0) calibrated_voltage = 5.0;
  
  // 4. Calculate Industrial 4-20 mA Current Signal
  // 1.0 V = 4.0 mA, 5.0 V = 20.0 mA -> I_mA = 4.0 + (V - 1.0) * 4.0
  float current_mA = 4.0 + (calibrated_voltage - 1.0) * 4.0;
  
  // 5. Calculate Percentage Level (0 - 100 %)
  float percent_level = (raw_level_cm / TANK_HEIGHT_CM) * 100.0;

  // 6. Map to PWM Duty Cycle for 4-20mA Module (0 - 255)
  // 1V -> ~51 PWM, 5V -> 255 PWM
  int pwm_val = mapFloat(calibrated_voltage, 1.0, 5.0, 51.0, 255.0);
  analogWrite(PWM_OUT_PIN, constrain(pwm_val, 0, 255));

  // 7. Output Telemetry via Serial
  Serial.print(F("Dist: ")); Serial.print(raw_distance_cm, 1); Serial.print(F(" cm | "));
  Serial.print(F("Level: ")); Serial.print(raw_level_cm, 1); Serial.print(F(" cm ("));
  Serial.print(percent_level, 1); Serial.print(F("%) | "));
  Serial.print(F("Tx V: ")); Serial.print(calibrated_voltage, 3); Serial.print(F(" V | "));
  Serial.print(F("Loop I: ")); Serial.print(current_mA, 2); Serial.println(F(" mA"));

  // Check for incoming serial commands
  handleSerialCommands(raw_level_cm, calibrated_voltage);

  delay(500); // 2Hz Telemetry Update Rate
}

// -------------------------------------------------------------
// Helper Functions
// -------------------------------------------------------------

// Measure raw distance via Time-of-Flight (ToF)
float readSingleDistanceCm() {
  // Speed of sound in air (cm/us) with temperature compensation
  // v = 331.3 + 0.606 * T (m/s) -> divide by 10000 for cm/us
  float speed_of_sound_cm_us = (331.3 + 0.606 * ambient_temp_c) / 10000.0;

  // Trigger pulse
=======
 * Ultrasonic Level Transmitter Calibration
 * Numerical Methods Mini-Project (Arduino UNO + HC-SR04)
 * Method: Linear coefficients from Gauss Elimination on Normal Equations
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);   // change to 0x3F if needed

const int TRIG_PIN = 9;
const int ECHO_PIN = 10;
const int PIN_GREEN = 7;
const int PIN_RED   = 8;

// Coefficients obtained by Gauss Elimination
const float a0 = 32.60806594f;
const float a1 = -0.99824923f;

const float HIGH_LEVEL = 20.0f;

const int N_AVG = 5;
float distBuf[N_AVG];
int idx = 0;
float distSum = 0;

void setup() {
  Serial.begin(9600);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(PIN_GREEN, OUTPUT);
  pinMode(PIN_RED, OUTPUT);

  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Level Transmitter");
  lcd.setCursor(0, 1);
  lcd.print("Calibration NM");
  delay(2000);
  lcd.clear();

  for (int i = 0; i < N_AVG; i++) {
    distBuf[i] = readDistance();
    distSum += distBuf[i];
  }

  Serial.println(F("=== Ultrasonic Level Transmitter ==="));
  Serial.println(F("Method: Linear Fit via Gauss Elimination"));
  Serial.println(F("Dist(cm)\tLevel(cm)\tStatus"));
}

float readDistance() {
>>>>>>> 79a392ae3a07bcecb962858f4711c69c548a4c4c
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

<<<<<<< HEAD
  // Read Echo pulse duration (microseconds)
  long duration_us = pulseIn(ECHO_PIN, HIGH, 30000); // 30ms timeout (~5m max range)

  if (duration_us == 0) {
    return TANK_HEIGHT_CM; // Out of range fallback
  }

  // Distance = (Time * Speed) / 2
  float distance_cm = (duration_us * speed_of_sound_cm_us) / 2.0;
  return distance_cm;
}

// Moving Average Filtering
float readFilteredDistanceCm(int num_samples) {
  float total = 0.0;
  int valid_samples = 0;
  for (int i = 0; i < num_samples; i++) {
    float dist = readSingleDistanceCm();
    if (dist > 0 && dist <= TANK_HEIGHT_CM + 20.0) {
      total += dist;
      valid_samples++;
    }
    delay(10);
  }
  if (valid_samples == 0) return TANK_HEIGHT_CM;
  return total / valid_samples;
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void handleSerialCommands(float current_level, float current_v) {
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toUpperCase();

    if (cmd == "CAL_ZERO") {
      gauss_offset = 1.000 - (gauss_slope * current_level);
      Serial.print(F("[+] ZERO Calibrated! New Offset: "));
      Serial.println(gauss_offset, 5);
    } else if (cmd == "CAL_SPAN") {
      if (current_level > 5.0) {
        gauss_slope = (5.000 - gauss_offset) / current_level;
        Serial.print(F("[+] SPAN Calibrated! New Slope: "));
        Serial.println(gauss_slope, 5);
      } else {
        Serial.println(F("[!] ERROR: Level too low for SPAN calibration!"));
      }
    } else if (cmd == "STATUS") {
      Serial.println(F("--- CURRENT CALIBRATION COEFFICIENTS ---"));
      Serial.print(F("Slope (m)  : ")); Serial.println(gauss_slope, 5);
      Serial.print(F("Offset (c) : ")); Serial.println(gauss_offset, 5);
      Serial.println(F("---------------------------------------"));
    }
  }
}
=======
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duration == 0) return 999.0;
  return duration * 0.0343 / 2.0;   // cm
}

void loop() {
  float newDist = readDistance();
  distSum -= distBuf[idx];
  distBuf[idx] = newDist;
  distSum += newDist;
  idx = (idx + 1) % N_AVG;

  float distance = distSum / N_AVG;

  // Numerical computation (Gauss-derived formula)
  float level = a0 + a1 * distance;
  if (level < 0) level = 0;

  bool alarm = (level >= HIGH_LEVEL);
  digitalWrite(PIN_GREEN, alarm ? LOW  : HIGH);
  digitalWrite(PIN_RED,   alarm ? HIGH : LOW);

  lcd.setCursor(0, 0);
  lcd.print("Dist:");
  lcd.print(distance, 1);
  lcd.print("cm   ");

  lcd.setCursor(0, 1);
  lcd.print("Lvl:");
  lcd.print(level, 1);
  lcd.print("cm ");
  lcd.print(alarm ? "HI " : "OK ");

  Serial.print(distance, 1);
  Serial.print('\t');
  Serial.print(level, 1);
  Serial.print('\t');
  Serial.println(alarm ? "HIGH" : "OK");

  delay(400);
}
>>>>>>> 79a392ae3a07bcecb962858f4711c69c548a4c4c
