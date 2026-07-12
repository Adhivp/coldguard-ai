<p align="center">
  <img src="arduino/cg..png" width="120" alt="ColdGuard AI Logo"/>
</p>

<h1 align="center">ColdGuard AI</h1>
<p align="center"><strong>Smart Cold Chain Monitoring — Certified. Intelligent. Real-time.</strong></p>
<p align="center"><em>Every degree matters. Every second counts. Every product deserves a certificate.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/Arduino-00979D?style=for-the-badge&logo=arduino&logoColor=white" alt="Arduino"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white" alt="scikit-learn"/>
  <img src="https://img.shields.io/badge/Qualcomm_AI_Hub-3253DC?style=for-the-badge&logo=qualcomm&logoColor=white" alt="Qualcomm AI Hub"/>
  <img src="https://img.shields.io/badge/Gemma_4_E2B-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemma 4 E2B"/>
  <img src="https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white" alt="Render"/>
</p>

<p align="center">
<em>2,150 cord blood units destroyed in Singapore. Thousands of COVID vaccines discarded globally. A Zepto warehouse shut down in Mumbai. A worm found in sealed curd on Vande Bharat. All preventable.</em>
</p>

---

## What is ColdGuard AI?

ColdGuard AI is an end-to-end cold chain monitoring system for food, pharma, vaccines, and blood logistics. We are a **third-party certification agency** — companies that deploy ColdGuard hardware and maintain compliance earn the **ColdGuard AI Certified** badge, verifiable by scanning the QR code on any product.

Cold chain failures cost the global pharma industry $35B/year and cause 25% of food waste in transit. Every spoiled vaccine, contaminated blood sample, and thawed frozen shipment is a ColdGuard failure we prevent.

**Supported products:**

| Product | Safe Range | Max Breach |
|---|---|---|
| COVID-19 mRNA Vaccine | -25°C to -15°C | 5 min |
| Hepatitis B Vaccine | 2°C to 8°C | 30 min |
| Insulin | 2°C to 8°C | 20 min |
| Blood Sample | 1°C to 6°C | 10 min |
| Frozen Chicken | -18°C to -15°C | 5 min |
| Frozen Atlantic Salmon | -18°C to -15°C | 2 min |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SMART CRATE (Edge)                          │
│                                                                     │
│  ┌──────────────┐   SPI   ┌──────────────┐   I2C  ┌─────────────┐  │
│  │ MFRC522 RFID │────────▶│ Arduino Uno Q│───────▶│Modulino     │  │
│  │ Reader       │         │ (Zephyr RTOS)│        │Thermo+Buzzer│  │
│  └──────────────┘         └──────┬───────┘        └─────────────┘  │
│    RFID tag on every product     │ Bridge RPC (USB)                 │
│                                  ▼                                  │
│                       ┌──────────────────┐                         │
│                       │ Python Host App  │  sklearn MLP inference  │
│                       │ (Arduino App Lab)│  every second           │
│                       └────────┬─────────┘                         │
└────────────────────────────────│────────────────────────────────────┘
                                 │ HTTPS + HMAC-SHA256
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     BACKEND (Render + Supabase)                     │
│                                                                     │
│  FastAPI ──▶ /telemetry  ──▶ sensor_readings table                  │
│           ──▶ /scan/{id}  ──▶ product health summary                │
│           ──▶ /product/{id}/graph?zoom=day|hour|minute|second       │
│           ──▶ /model/version + /model/anomaly.joblib                │
│                                                                     │
│  APScheduler (every Sunday 02:00 UTC)                               │
│    └─▶ ml/train.py  ──▶  anomaly.joblib + breach.joblib             │
│         fetches all sensor_readings, trains MLP, exports model      │
└────────────────────────────┬────────────────────────────────────────┘
                             │ REST API
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                FLUTTER APP (Android — OnePlus 14)                   │
│                 Snapdragon 8 Elite / 3 AI backends                  │
│                                                                     │
│  QR Scan ──▶ /scan endpoint ──▶ product health screen              │
│  Graph   ──▶ drill-down day→hour→minute→second                      │
│  AI Chat ──▶ Gemma 4 E2B (2.4 GB, on-device LiteRT)               │
│           ──▶ real-time supply chain context injected per query     │
│  AI Scan ──▶ 5 cold-chain reports per product (on-device)          │
│           1. Compliance verdict (PASS/FAIL/WARNING)                 │
│           2. Risk assessment (LOW–CRITICAL)                         │
│           3. Predictive shelf life                                  │
│           4. Recommended actions                                    │
│           5. Executive summary                                      │
│                                                                     │
│  Hardware backends (runtime selectable):                            │
│    GPU  ──▶ OpenCL / libOpenCL.so                                  │
│    NPU  ──▶ Qualcomm QNN DSP delegate                              │
│    CPU  ──▶ fallback                                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Three Components

### 1. `arduino/` — Smart Crate Edge Device

**Hardware:** Arduino Uno Q + Modulino Thermo + MFRC522 RFID + Modulino Buzzer

- Every product in the crate carries an RFID tag (+₹5–10/product). The reader continuously confirms presence/absence of each SKU.
- Sensor reads every second. Python host app batches 60 readings/min and sends to backend.
- **On-device ML inference** every second — downloads `anomaly.joblib` + `breach.joblib` from backend on startup, auto-updates weekly.
- Buzzer driven by ML scores: intermittent beep on breach warning, 10-second ambulance siren on confirmed anomaly.
- Every request signed with **HMAC-SHA256** using a per-device 256-bit secret — secret never transmitted.

### 2. `backend/` — Cloud API + Weekly ML Retraining

Live docs: **[coldguard-ai.onrender.com/docs](https://coldguard-ai.onrender.com/docs)**

- Authenticated telemetry ingestion with nonce-based replay attack prevention.
- **Zoom-level graph API** — single endpoint drills `day → hour → minute → second`, serving every individual sensor reading.
- **Two ML models** trained on real `sensor_readings`:
  - **Anomaly Detector** — 60-reading window MLP, detects spikes and slow drift
  - **Breach Predictor** — 10-reading trend MLP, forecasts breach before it happens
- **Weekly automated retraining** via APScheduler — models improve every week as real data accumulates.
- Fake data generator (`fake_data.py`) seeds 43,200 rows per product for cold-start training.

### 3. `flutter_app/` — Mobile App (OnePlus 14, Snapdragon 8 Elite)

- QR scan → instant product health, graph, timeline, life estimate from real sensor data.
- **Gemma 4 E2B** (2.4 GB) runs fully on-device via `flutter_gemma` + Google LiteRT.
  - Supports extended chain-of-thought thinking (reasoning shown in collapsible UI block).
  - Supports function calling for structured cold-chain queries.
  - Context injection: live supply chain data from backend prepended to every query automatically.
- **AI Product Analysis** — 5 cold-chain reports generated on-device per QR scan (compliance, risk, shelf life, actions, summary).
- Three inference backends selectable at runtime: GPU (OpenCL), NPU (Qualcomm QNN/DSP), CPU fallback.
- Model sideloadable via ADB for offline deployment: `adb push model.litertlm`.

---

## Certification Model

Companies integrate ColdGuard hardware into their supply chain. Our backend scores cold chain compliance continuously. Products that maintain temperature integrity earn the **ColdGuard AI Certified** seal — scannable by consumers, verifiable by regulators.

This mirrors how SSL certificates work for HTTPS — we are the trusted third party that validates cold chain integrity, not the company selling the product.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Edge firmware | C++ / Arduino Uno Q / Zephyr RTOS |
| Edge intelligence | Python 3.13 / sklearn MLP / HMAC-SHA256 |
| Backend | FastAPI / Supabase PostgreSQL / Render |
| ML training | scikit-learn MLP pipeline / APScheduler weekly |
| Mobile | Flutter / Dart / BLoC / Clean Architecture |
| On-device LLM | Gemma 4 E2B / Google LiteRT / flutter_gemma |
| NPU acceleration | Qualcomm QNN DSP delegate / OpenCL GPU |
| Auth | Per-device 256-bit HMAC secret provisioning |

---

## Roadmap

- **Inventory Management Web App** — fleet view, per-product timeline, excursion audit logs, certification dashboard
- **Multi-crate fleet dashboard** — single view across entire warehouse or transit network
- **LLM-powered proactive alerts** — "PROD-003 will breach in ~8 min based on current trend"
- **Regulatory PDF export** — one-click FSSAI / WHO / GDP cold chain audit trail
- **Blockchain anchoring** — immutable per-batch cold chain record for tamper-proof certification

---

## API

**[https://coldguard-ai.onrender.com/docs](https://coldguard-ai.onrender.com/docs)**

| Endpoint | Description |
|---|---|
| `GET /scan/{product_id}` | Full product health in one call |
| `GET /product/{product_id}/graph?zoom=day` | Drill-down graph |
| `GET /products` | All registered products with live status |
| `POST /telemetry` | Authenticated Arduino ingestion |
| `GET /model/version` | Latest ML model version + download URLs |
| `POST /admin/train` | Trigger model retraining |

---

## Why This Matters — Real Incidents

> These are not hypothetical risks. These happened. ColdGuard is built to prevent every one of them.

---

### 1. Zepto Warehouse Food Safety Violations — Mumbai, India (2025)

**What happened:** Maharashtra FDA conducted a surprise inspection of a Zepto dark store warehouse in Mumbai. Officials discovered expired food products still on shelves, visible fungal growth on stored items, products kept in unhygienic conditions, and cold-storage units not maintained at required temperatures. The food business operating license was immediately suspended pending corrective action.

**Scale of the problem:** Dark store warehouses operate 24/7 with high SKU turnover. Manual inspection cycles are too slow — by the time a regulator visits, the damage is done and the products have already been dispatched to consumers.

**What ColdGuard would have done:**
- RFID tags on every SKU would have flagged products approaching expiry automatically
- Per-second temperature monitoring would have detected when cold-storage units drifted out of range — hours before a human noticed
- Automated alerts sent to store managers the moment any breach began
- Full audit trail available to regulators at any point — no surprise inspections needed

---

### 2. Lulu Hypermarket Food Safety Inspection — Hyderabad, India (2026)

**What happened:** Telangana food safety officials inspected a Lulu Hypermarket outlet and found spoiled vegetables on the floor, multiple hygiene violations, pest-related concerns in the storage area, and approximately **150 kg of food** that had to be discarded on the spot due to safety issues. The store faced regulatory action and public embarrassment.

**Scale of the problem:** 150 kg of food waste from a single inspection at a single store. India has thousands of hypermarkets and cold-chain retail outlets. The aggregate waste — and public health risk — across the supply chain is enormous.

**What ColdGuard would have done:**
- Continuous cold-storage monitoring would have flagged when vegetable storage temperatures deviated, triggering restock or discard decisions before spoilage was visible
- Real-time dashboards give store managers instant visibility into every cold zone
- AI anomaly detection identifies unusual temperature patterns (e.g., a storage unit door left ajar) within seconds

---

### 3. Worm Found in Packaged Curd — Vande Bharat Express, India (2026)

**What happened:** A passenger travelling on a Vande Bharat Express found live worms inside a factory-sealed curd cup served as part of the on-board meal. The incident went viral on social media. The catering vendor was penalized, and the Indian Railways reviewed food handling and cold-chain procedures across its pantry car network.

**Scale of the problem:** Railway catering serves millions of meals per day across thousands of trains. The cold chain from food production to tray service on a moving train involves multiple handoffs — factory, logistics, railway depot, pantry car — each a point of potential temperature failure.

**What ColdGuard would have done:**
- Every packaged food item carries an RFID tag tracking its exact transit path and temperature exposure from manufacturing to service
- ColdGuard smart crates on railway pantry cars monitor temperature every second during transit
- If any crate exceeds safe range during the journey, the system flags it before the food reaches the passenger
- Complete traceability means the exact batch, factory, and transit route can be identified within seconds of any complaint

---

### 4. Cordlife Cord Blood Storage Scandal — Singapore (2023–2025)

**What happened:** Cordlife Group, one of Asia's largest private cord blood banks, failed to maintain cryogenic storage conditions across multiple tanks. Over **2,150 cord blood units** — stored for families who paid significant fees expecting stem cells preserved for future medical use — were exposed to temperatures above the required −196°C threshold. Singapore's Ministry of Health suspended Cordlife's operations, senior executives were investigated under the Private Hospitals and Medical Clinics Act, and the company faced class-action legal proceedings. Many families lost their only stored stem cell unit — irreplaceable for potential future transplants.

**Scale of the problem:** This is arguably the most catastrophic cold-chain failure of the decade. Unlike spoiled food, you cannot replace a cord blood unit. The families affected had paid for a one-time biological insurance policy that was silently destroyed.

**What ColdGuard would have done:**
- Per-second temperature monitoring on every cryogenic tank
- Immediate alert the moment any tank showed deviation from −196°C — long before the damage accumulated
- Immutable audit log of every temperature reading, timestamped and stored in Supabase — regulators could query the exact history of any tank at any time
- RFID identification of every stored unit so any affected batch could be traced and families notified instantly

---

### 5. COVID-19 Vaccine Cold Chain Failures — Global (2021–2022)

**What happened:** During the largest vaccination campaign in human history, cold-chain failures caused significant vaccine losses across multiple countries. Pfizer-BioNTech's mRNA vaccine required storage at approximately −70°C — a requirement that overwhelmed existing cold-chain infrastructure in many regions. Documented failures included freezer malfunctions at distribution centres, temperature excursions during last-mile transport, power outages at storage facilities, and doses left unrefrigerated due to miscommunication. In some cases, batches of thousands of doses were discarded only after being administered — raising concerns about efficacy for those patients.

**Scale of the problem:** WHO estimated that up to 50% of vaccines globally are wasted each year due to cold-chain failures. For COVID-19 vaccines specifically, the combination of ultra-cold requirements and unprecedented distribution urgency exposed every weakness in the existing system simultaneously.

**What ColdGuard would have done:**
- ML breach predictor forecasts temperature exceedance **before** it happens — giving operators 30–60 seconds to intervene before a single dose is compromised
- Per-second monitoring from manufacturing through last-mile delivery, with every reading stored
- Buzzer alarm on the smart crate triggers the moment a transport vehicle's cold box drifts above safe range
- ColdGuard AI Certified badge on every batch — scannable proof that the entire cold chain was maintained

---

### Summary

| Incident | Lives / Units at Risk | Root Cause | ColdGuard Prevention |
|---|---|---|---|
| Zepto Warehouse (2025) | Consumers across Mumbai | No real-time monitoring, manual inspection only | Continuous temp + RFID expiry tracking |
| Lulu Hypermarket (2026) | 150+ kg food waste, public health | Delayed detection of storage failure | AI anomaly alert within seconds |
| Vande Bharat Curd (2026) | Millions of daily rail passengers | No transit temperature traceability | Per-second crate monitoring + RFID trace |
| Cordlife Cord Blood (2023–25) | 2,150 families' stem cell units | Silent cryogenic tank failure | Per-second cryo monitoring + instant alert |
| COVID Vaccine Losses (2021–22) | Millions of vaccine doses globally | Ultra-cold infrastructure gaps | ML breach prediction before doses lost |

---

## Temperature Standards Reference

| Product | Safe Range | Excursion Tolerance | High Risk Threshold |
|---|---|---|---|
| Milk & Fresh Dairy | 2–4°C | < 30–60 min above 8°C | > 2 hours above 8°C |
| Standard Vaccines | 2–8°C | Minutes to hours (manufacturer-specific) | Freezing or prolonged > 8°C |
| mRNA Vaccines (ultra-cold) | ~−70°C | Manufacturer-specific once thawed | Repeated thaw/refreeze |
| Red Blood Cells | 2–6°C | Validated transport limits | Sustained > 6°C or freezing |
| Platelets | 20–24°C + agitation | Brief agitation loss | Cooling or loss of agitation |
| Fresh Frozen Plasma | ≤ −18°C | Remain frozen | Partial thaw |
| Cryopreserved Cord Blood | ~−196°C (liquid nitrogen) | None acceptable | Any warming excursion |
| Frozen Chicken / Salmon | −18°C to −15°C | < 5 min (salmon: 2 min) | Any sustained thaw |
