/*
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
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

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