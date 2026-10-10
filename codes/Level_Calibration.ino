/*
 * ============================================================
 *  Ultrasonic Level Transmitter Calibration System
 *  Arduino UNO Firmware
 * ============================================================
 *  Project : Calibration of Ultrasonic Level Transmitter
 *            using Arduino UNO and Gauss Elimination Method
 *  Course  : B.Tech ICE -- Numerical Methods (Semester 3)
 *
 *  Hardware:
 *    - Arduino UNO (ATmega328P)
 *    - HC-SR04 Ultrasonic Distance Sensor
 *    - 5V Relay Module (Water Pump Control)
 *    - GREEN LED  -- Normal / LOW Level indicator
 *    - RED LED    -- HIGH Level / Pump ON indicator
 *
 *  Serial Output Format (115200 baud, CSV for MATLAB/Web):
 *    DIST,<dist_cm>,LEVEL,<level_cm>,PCT,<pct>,RELAY,<0|1>
 *
 *  Gauss Elimination Coefficients (update from MATLAB output):
 *    Level (cm) = COEFF_A0 + COEFF_A1 * Distance (cm)
 * ============================================================
 */

// -----------------------------------------------------------
// Pin Definitions
// -----------------------------------------------------------
#define TRIG_PIN      9    // HC-SR04 Trigger
#define ECHO_PIN      8    // HC-SR04 Echo
#define RELAY_PIN     7    // Relay module IN pin (active-LOW)
#define LED_GREEN     6    // Green LED -- level OK
#define LED_RED       5    // Red LED  -- HIGH level / pump active

// -----------------------------------------------------------
// System Parameters
// -----------------------------------------------------------
const float TANK_HEIGHT_CM  = 30.0f;   // Tank inner height (cm)
const float LEVEL_HIGH_CM   = 22.0f;   // HIGH level threshold -> pump ON
const float LEVEL_LOW_CM    = 8.0f;    // LOW  level threshold -> pump OFF
const int   N_SAMPLES       = 7;       // Moving-median filter sample count
const unsigned long LOOP_MS = 500UL;   // Sampling interval (500 ms = 2 Hz)

// -----------------------------------------------------------
// Gauss Elimination Calibration Coefficients
// Level (cm) = COEFF_A0 + COEFF_A1 * Distance (cm)
// Update after running MATLAB level_calibration_gauss.m
// -----------------------------------------------------------
const float COEFF_A0 = 32.6081f;
const float COEFF_A1 = -0.9982f;

// -----------------------------------------------------------
// Globals
// -----------------------------------------------------------
float   samples[N_SAMPLES];
bool    pump_on = false;

// -----------------------------------------------------------
// Forward declarations
// -----------------------------------------------------------
float measureDistanceCm();
float movingMedian(float* arr, int n);

// -----------------------------------------------------------
void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN,  OUTPUT);
  pinMode(ECHO_PIN,  INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_RED,   OUTPUT);

  // Safe initial state -- relay OFF (HIGH = coil de-energised for active-LOW module)
  digitalWrite(RELAY_PIN, HIGH);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED,   LOW);

  // Warm-up: fill the sample buffer
  for (int i = 0; i < N_SAMPLES; i++) {
    samples[i] = measureDistanceCm();
    delay(60);
  }

  // Header line -- helps MATLAB/Python identify start of data stream
  Serial.println(F("# ULTRASONIC LEVEL TRANSMITTER -- Gauss Elimination Calibration"));
  Serial.println(F("# Format: DIST,<cm>,LEVEL,<cm>,PCT,<%>,RELAY,<0|1>"));
  Serial.println(F("# -------------------------------------------------------"));
}

// -----------------------------------------------------------
void loop() {
  static unsigned long last_ms = 0;
  unsigned long now = millis();
  if (now - last_ms < LOOP_MS) return;
  last_ms = now;

  // 1. Raw distance measurement
  float new_dist = measureDistanceCm();

  // Shift ring buffer and insert new sample
  for (int i = 0; i < N_SAMPLES - 1; i++) samples[i] = samples[i + 1];
  samples[N_SAMPLES - 1] = new_dist;

  float dist_cm = movingMedian(samples, N_SAMPLES);

  // 2. Apply Gauss Elimination calibration model
  float level_cm = COEFF_A0 + COEFF_A1 * dist_cm;
  level_cm = constrain(level_cm, 0.0f, TANK_HEIGHT_CM);

  // 3. Compute percentage fill
  float pct = (level_cm / TANK_HEIGHT_CM) * 100.0f;

  // 4. Hysteresis pump control via relay
  if (!pump_on && level_cm >= LEVEL_HIGH_CM) {
    pump_on = true;
    digitalWrite(RELAY_PIN, LOW);   // Energise relay (active-LOW) -> Pump ON
  } else if (pump_on && level_cm <= LEVEL_LOW_CM) {
    pump_on = false;
    digitalWrite(RELAY_PIN, HIGH);  // De-energise relay -> Pump OFF
  }

  // 5. LED indicators
  digitalWrite(LED_RED,   pump_on ? HIGH : LOW);
  digitalWrite(LED_GREEN, pump_on ? LOW  : HIGH);

  // 6. Transmit structured CSV over Serial
  Serial.print(F("DIST,"));
  Serial.print(dist_cm, 2);
  Serial.print(F(",LEVEL,"));
  Serial.print(level_cm, 2);
  Serial.print(F(",PCT,"));
  Serial.print(pct, 1);
  Serial.print(F(",RELAY,"));
  Serial.println(pump_on ? 1 : 0);
}

// -----------------------------------------------------------
// Measure single raw distance via HC-SR04 ToF
// Returns distance in centimetres, or TANK_HEIGHT_CM on timeout
// -----------------------------------------------------------
float measureDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(4);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration_us = pulseIn(ECHO_PIN, HIGH, 30000UL);
  if (duration_us == 0) return TANK_HEIGHT_CM;   // Timeout fallback

  // d = (v_sound x t) / 2  at ~25 deg C  -> v_sound ~ 0.03435 cm/us
  return duration_us * 0.03435f;
}

// -----------------------------------------------------------
// Moving Median via insertion sort on a copy of the buffer
// -----------------------------------------------------------
float movingMedian(float* arr, int n) {
  float tmp[7];   // N_SAMPLES max = 7
  for (int i = 0; i < n; i++) tmp[i] = arr[i];

  for (int i = 1; i < n; i++) {
    float key = tmp[i];
    int j = i - 1;
    while (j >= 0 && tmp[j] > key) { tmp[j + 1] = tmp[j]; j--; }
    tmp[j + 1] = key;
  }

  if (n % 2 == 0) return (tmp[n / 2 - 1] + tmp[n / 2]) / 2.0f;
  return tmp[n / 2];
}
