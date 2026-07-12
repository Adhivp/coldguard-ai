#include <Arduino_RouterBridge.h>
#include <Arduino_Modulino.h>
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9
MFRC522 mfrc522(SS_PIN, RST_PIN);

ModulinoBuzzer buzzer;
ModulinoThermo thermo;

bool          rfidPresent      = false;
unsigned long lastRfidSeenAt   = 0;
const unsigned long RFID_PRESENT_TIMEOUT_MS  = 10000;

// ── Temperature alert thresholds ──────────────────────────
const float ALERT_TEMP_LOW  = 27.0;
const float ALERT_TEMP_HIGH = 30.0;

// ── Intermittent alarm (27–30°C) ──────────────────────────
const unsigned long INTERMITTENT_GAP_MS = 3000;
const unsigned long BEEP_DURATION_MS    = 300;
unsigned long lastBeepTime = 0;

// ── Siren (≥30°C, locked 10 s) ────────────────────────────
const unsigned int  SIREN_MIN_FREQ         = 600;
const unsigned int  SIREN_MAX_FREQ         = 1300;
const unsigned long SIREN_STEP_MS          = 80;
const unsigned long SIREN_SWEEP_MS         = 900;
const unsigned long SIREN_TONE_LEN_MS      = SIREN_STEP_MS + 40;
const unsigned long SIREN_LOCK_DURATION_MS = 10000;

unsigned long lastSirenStep  = 0;
bool          sirenRising    = true;
unsigned int  sirenFreq      = SIREN_MIN_FREQ;
bool          sirenLocked    = false;
unsigned long sirenLockEndsAt = 0;

// ── RFID-absent continuous buzz ────────────────────────────
const unsigned int  RFID_ABSENT_FREQ    = 440;
const unsigned long RFID_ABSENT_TONE_MS = 200;
unsigned long lastRfidBuzzTime   = 0;
unsigned long lastRfidResetAt    = 0;
const unsigned long RFID_RESET_INTERVAL_MS = 3000;

volatile float latestTemperatureC = NAN;

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
  Bridge.provide("get_temperature", rpc_get_temperature);

  SPI.begin();
  mfrc522.PCD_Init();
}

extern "C" void loop() {
  unsigned long now = millis();

  // ── RFID sensor reset every 3 s ───────────────────────────
  if (now - lastRfidResetAt >= RFID_RESET_INTERVAL_MS) {
    mfrc522.PCD_Init();
    lastRfidResetAt = now;
  }

  // ── RFID check — exact original pattern, latched for 10 s ─
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    lastRfidSeenAt = now;
    mfrc522.PICC_HaltA();
  }
  rfidPresent = (now - lastRfidSeenAt) < RFID_PRESENT_TIMEOUT_MS;
  float temperatureC = latestTemperatureC;

  // ── Siren lock (≥30°C) — highest priority, overrides everything ──
  if (!isnan(temperatureC)) {
    if (!sirenLocked && temperatureC >= ALERT_TEMP_HIGH) {
      sirenLocked    = true;
      sirenLockEndsAt = now + SIREN_LOCK_DURATION_MS;
      sirenFreq      = SIREN_MIN_FREQ;
      sirenRising    = true;
    }

    if (sirenLocked) {
      stepSiren(now);
      if (now >= sirenLockEndsAt) sirenLocked = false;
      return;
    }

    // ── Intermittent temp alert (27–30°C) ──────────────────────
    if (temperatureC >= ALERT_TEMP_LOW) {
      if (now - lastBeepTime >= INTERMITTENT_GAP_MS) {
        buzzer.tone(900, BEEP_DURATION_MS);
        lastBeepTime = now;
      }
      return;
    }
  }

  // ── RFID-absent continuous buzz (when temp is normal) ──────
  if (!rfidPresent) {
    if (now - lastRfidBuzzTime >= RFID_ABSENT_TONE_MS) {
      buzzer.tone(RFID_ABSENT_FREQ, RFID_ABSENT_TONE_MS + 20);
      lastRfidBuzzTime = now;
    }
  }
}
