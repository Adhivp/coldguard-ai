#include <Arduino_RouterBridge.h>
#include <Arduino_Modulino.h>

ModulinoBuzzer buzzer;

const float ALERT_TEMP_LOW = 27.0;   // timed/intermittent alert from here
const float ALERT_TEMP_HIGH = 30.0;  // triggers a locked 10s continuous siren

// ── Intermittent alarm (26–30°C) ──────────────────────────
const unsigned long INTERMITTENT_GAP_MS = 3000;   // gap between beeps
const unsigned long BEEP_DURATION_MS = 300;       // length of each beep
unsigned long lastBeepTime = 0;

// ── Lumax ambulance-style siren (triggered once ≥30°C) ────
const unsigned int SIREN_MIN_FREQ = 600;
const unsigned int SIREN_MAX_FREQ = 1300;
const unsigned long SIREN_STEP_MS = 80;      // how often the pitch updates (slower = more reliable on the buzzer's I2C link)
const unsigned long SIREN_SWEEP_MS = 900;    // time to sweep from min to max, one direction
const unsigned long SIREN_TONE_LEN_MS = SIREN_STEP_MS + 40; // always longer than the gap so it never falls silent
const unsigned long SIREN_LOCK_DURATION_MS = 10000; // once triggered, runs uninterrupted for this long

unsigned long lastSirenStep = 0;
bool sirenRising = true;
unsigned int sirenFreq = SIREN_MIN_FREQ;

bool sirenLocked = false;          // true while the mandatory 10s run is in progress
unsigned long sirenLockEndsAt = 0; // millis() timestamp when the lock releases

volatile float latestTemperatureC = NAN;

ModulinoThermo thermo;

// Called by the Python app to fetch the latest reading.
// Only reads the sensor and reports it — the buzzer is handled in loop(),
// completely independent of how often Python polls.
String rpc_get_temperature() {
  latestTemperatureC = thermo.getTemperature();
  float humidity = thermo.getHumidity();

  char buf[96];
  snprintf(
    buf, sizeof(buf),
    "{\"temperature_c\":%.2f,\"humidity\":%.2f}",
    latestTemperatureC, humidity
  );
  return String(buf);
}

void stepSiren(unsigned long now) {
  if (now - lastSirenStep < SIREN_STEP_MS) return;

  unsigned int freqRange = SIREN_MAX_FREQ - SIREN_MIN_FREQ;
  unsigned int stepSize = (freqRange * SIREN_STEP_MS) / SIREN_SWEEP_MS;
  if (stepSize < 1) stepSize = 1;

  if (sirenRising) {
    sirenFreq += stepSize;
    if (sirenFreq >= SIREN_MAX_FREQ) { sirenFreq = SIREN_MAX_FREQ; sirenRising = false; }
  } else {
    sirenFreq -= stepSize;
    if (sirenFreq <= SIREN_MIN_FREQ) { sirenFreq = SIREN_MIN_FREQ; sirenRising = true; }
  }

  buzzer.tone(sirenFreq, SIREN_TONE_LEN_MS);
  lastSirenStep = now;
}

void setup() {
  Bridge.begin();
  Modulino.begin();
  thermo.begin();
  buzzer.begin();
  Bridge.provide("get_temperature", rpc_get_temperature);
}

void loop() {
  float temperatureC = latestTemperatureC;
  if (isnan(temperatureC)) return; // no reading yet

  unsigned long now = millis();

  // Once ≥30°C is seen even once, lock into a full 10s uninterrupted siren —
  // ignores everything else, including the temperature dropping back down,
  // until the 10 seconds are up.
  if (!sirenLocked && temperatureC >= ALERT_TEMP_HIGH) {
    sirenLocked = true;
    sirenLockEndsAt = now + SIREN_LOCK_DURATION_MS;
    sirenFreq = SIREN_MIN_FREQ;
    sirenRising = true;
  }

  if (sirenLocked) {
    stepSiren(now);
    if (now >= sirenLockEndsAt) {
      sirenLocked = false; // lock released; next loop() re-evaluates normally
      // If temperature is still ≥30°C at this point, the check above will
      // immediately re-trigger a fresh 10s lock on the very next iteration.
    }
    return; // nothing else runs while the siren is locked on
  }

  if (temperatureC >= ALERT_TEMP_LOW) {
    // Intermittent alarm: short beep every 3 seconds
    if (now - lastBeepTime >= INTERMITTENT_GAP_MS) {
      buzzer.tone(900, BEEP_DURATION_MS);
      lastBeepTime = now;
    }
  }
}