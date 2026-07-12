#include <Arduino_RouterBridge.h>
#include <Arduino_Modulino.h>
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN  10
#define RST_PIN  9
MFRC522 mfrc522(SS_PIN, RST_PIN);

ModulinoBuzzer buzzer;
ModulinoThermo thermo;

// ── RFID presence ──────────────────────────────────────────────────────────
bool          rfidPresent           = false;
unsigned long lastRfidSeenAt        = 0;
const unsigned long RFID_PRESENT_TIMEOUT_MS  = 10000;
const unsigned long RFID_RESET_INTERVAL_MS   = 3000;
unsigned long lastRfidResetAt       = 0;

// ── Alarm state (driven by Python ML inference via set_alarm RPC) ──────────
// "off" | "warning" | "anomaly"
String currentAlarmLevel = "off";

// ── Warning beep (intermittent, used for breach_probability > threshold) ───
const unsigned long BEEP_GAP_MS      = 3000;
const unsigned long BEEP_DURATION_MS = 300;
unsigned long lastBeepTime           = 0;

// ── Siren (used for anomaly_score > threshold, locked 10 s) ───────────────
const unsigned int  SIREN_MIN_FREQ         = 600;
const unsigned int  SIREN_MAX_FREQ         = 1300;
const unsigned long SIREN_STEP_MS          = 80;
const unsigned long SIREN_SWEEP_MS         = 900;
const unsigned long SIREN_TONE_LEN_MS      = SIREN_STEP_MS + 40;
const unsigned long SIREN_LOCK_DURATION_MS = 10000;

unsigned long lastSirenStep   = 0;
bool          sirenRising     = true;
unsigned int  sirenFreq       = SIREN_MIN_FREQ;
bool          sirenLocked     = false;
unsigned long sirenLockEndsAt = 0;

// ── RFID-absent buzz (when alarm is off and RFID not detected) ─────────────
const unsigned int  RFID_ABSENT_FREQ    = 440;
const unsigned long RFID_ABSENT_TONE_MS = 200;
unsigned long lastRfidBuzzTime = 0;

volatile float latestTemperatureC = NAN;


// ── RPC: read temperature + humidity + RFID presence ──────────────────────
String rpc_get_temperature() {
  latestTemperatureC = thermo.getTemperature();
  float humidity = thermo.getHumidity();
  char buf[128];
  snprintf(
    buf, sizeof(buf),
    "{\"temperature_c\":%.2f,\"humidity\":%.2f,\"rfid_present\":%s}",
    latestTemperatureC, humidity, rfidPresent ? "true" : "false"
  );
  return String(buf);
}

// ── RPC: set alarm level from Python ML inference ─────────────────────────
// level: "off" | "warning" | "anomaly"
String rpc_set_alarm(String level) {
  currentAlarmLevel = level;
  if (level == "off") {
    sirenLocked = false;
  } else if (level == "anomaly" && !sirenLocked) {
    sirenLocked    = true;
    sirenLockEndsAt = millis() + SIREN_LOCK_DURATION_MS;
    sirenFreq      = SIREN_MIN_FREQ;
    sirenRising    = true;
  }
  return "{\"ok\":true}";
}


// ── Siren sweep helper ─────────────────────────────────────────────────────
void stepSiren(unsigned long now) {
  if (now - lastSirenStep < SIREN_STEP_MS) return;
  unsigned int freqRange = SIREN_MAX_FREQ - SIREN_MIN_FREQ;
  unsigned int stepSize  = (freqRange * SIREN_STEP_MS) / SIREN_SWEEP_MS;
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


extern "C" void setup() {
  Bridge.begin();
  Modulino.begin();
  thermo.begin();
  buzzer.begin();

  SPI.begin();
  mfrc522.PCD_Init();

  Bridge.provide("get_temperature", rpc_get_temperature);
  Bridge.provide("set_alarm",       rpc_set_alarm);
}

extern "C" void loop() {
  unsigned long now = millis();

  // ── RFID reader periodic reset ─────────────────────────────────────────
  if (now - lastRfidResetAt >= RFID_RESET_INTERVAL_MS) {
    mfrc522.PCD_Init();
    lastRfidResetAt = now;
  }

  // ── RFID card detection ────────────────────────────────────────────────
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    lastRfidSeenAt = now;
    mfrc522.PICC_HaltA();
  }
  rfidPresent = (now - lastRfidSeenAt) < RFID_PRESENT_TIMEOUT_MS;

  // ── Siren lock: run until expired regardless of alarm level ───────────
  if (sirenLocked) {
    stepSiren(now);
    if (now >= sirenLockEndsAt) {
      sirenLocked = false;
      // Python will re-trigger if still anomalous on next inference tick
    }
    return;
  }

  // ── ML-driven alarm logic ──────────────────────────────────────────────
  if (currentAlarmLevel == "anomaly") {
    // Siren lock already set in rpc_set_alarm; nothing to do here until lock expires
    return;
  }

  if (currentAlarmLevel == "warning") {
    if (now - lastBeepTime >= BEEP_GAP_MS) {
      buzzer.tone(900, BEEP_DURATION_MS);
      lastBeepTime = now;
    }
    return;
  }

  // ── Alarm off: only buzz if RFID absent ───────────────────────────────
  if (!rfidPresent) {
    if (now - lastRfidBuzzTime >= RFID_ABSENT_TONE_MS) {
      buzzer.tone(RFID_ABSENT_FREQ, RFID_ABSENT_TONE_MS + 20);
      lastRfidBuzzTime = now;
    }
  }
}
