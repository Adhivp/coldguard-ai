# Thermal Sensor Dashboard

A real-time temperature monitoring dashboard built for the **Arduino UNO R4 WiFi** and **Arduino Modulino Thermo**.

The application continuously reads environmental **temperature** and **humidity** from the Modulino Thermo sensor and displays the values in a live web dashboard using Python, Flask, and Socket.IO.

Although the current implementation focuses on live monitoring, it is designed as the foundation for a **Cold Chain Monitoring System**, where temperature data can be collected, analyzed, and transmitted to cloud services to monitor the quality and shelf life of temperature-sensitive products such as milk, dairy products, vaccines, medicines, and frozen foods.

---

# Why this project?

Many perishable products require strict temperature control throughout storage and transportation.

For example, milk should ideally be stored between **0°C and 4°C**. Even temporary increases in temperature accelerate bacterial growth, reducing product quality and shortening shelf life.

Continuous monitoring allows businesses to:

- Detect refrigeration failures early
- Monitor temperature fluctuations
- Record historical environmental conditions
- Trigger automated alerts
- Estimate remaining product shelf life using Time-Temperature Integration (TTI)

This project provides the first step toward that goal by continuously collecting environmental data and making it available in real time through a web dashboard while efficiently batching readings for backend processing.

---

# Features

- 🌡️ Live temperature monitoring
- 💧 Live humidity monitoring
- ⚡ Automatic sensor polling every second
- 📡 Real-time browser updates using WebSockets (Socket.IO)
- 🌐 Celsius / Fahrenheit unit conversion
- 🟢 Connection status indicator
- 🕒 Last updated timestamp
- 📦 One-minute backend data batching
- 🚀 Asynchronous backend uploads
- 📈 Foundation for future cold-chain analytics

---

# System Architecture

The application consists of three independent layers that communicate with one another.

```
                Modulino Thermo
                       │
                  I²C (Qwiic)
                       │
             Arduino UNO R4 WiFi
                       │
              Arduino Bridge RPC
                       │
                 Python Backend
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
  Socket.IO Dashboard         Batch HTTP Upload
        │                             │
        ▼                             ▼
  Live Web Dashboard          Backend API
```

---

# How It Works

## 1. Arduino Layer

The Arduino sketch is responsible for communicating directly with the Modulino Thermo sensor.

### Responsibilities

- Initialize the Modulino Thermo
- Read temperature
- Read humidity
- Expose a `get_temperature` Bridge RPC endpoint
- Return sensor readings as JSON

Example response:

```json
{
    "temperature_c": 4.2,
    "humidity": 73.8
}
```

The Arduino is dedicated solely to sensor acquisition and does not perform any web or networking tasks beyond exposing the RPC interface.

---

## 2. Python Backend

The Python application acts as the communication bridge between the Arduino and connected web clients.

### Responsibilities

- Poll the Arduino every second
- Receive sensor readings through Bridge RPC
- Broadcast live readings using Socket.IO
- Maintain a one-minute buffer of readings
- Send one-minute batches to the backend endpoint
- Handle browser requests for immediate readings

The backend separates **real-time visualization** from **cloud communication**, allowing the dashboard to remain highly responsive even if the backend endpoint experiences delays.

---

## 3. Web Dashboard

The browser provides a live visualization of environmental conditions.

Displayed information includes:

- Current temperature
- Current humidity
- Celsius/Fahrenheit toggle
- Connection status
- Last updated timestamp

Updates are received through Socket.IO, eliminating the need for browser polling and ensuring near real-time display.

---

# Data Collection Strategy

The application separates **sensor sampling**, **dashboard updates**, and **backend transmission** into independent workflows.

## Sensor Sampling

The Modulino Thermo sensor is read every **1 second**.

Each reading contains:

- Temperature (°C)
- Relative Humidity (%)
- Timestamp

Every reading is immediately broadcast to connected browser clients.

This ensures the dashboard always displays the latest environmental conditions with minimal latency.

---

## One-Minute Batch Collection

Instead of transmitting every reading individually, the backend temporarily stores each one-second reading in an in-memory buffer.

The workflow is:

1. Read the sensor every second.
2. Store each reading in the batch buffer.
3. Continue until **60 readings** have been collected.
4. Combine all readings into a single JSON payload.
5. Send the payload to the backend using an HTTP POST request.
6. Clear the buffer.
7. Begin collecting the next one-minute batch.

Each batch therefore represents exactly **one minute of continuous sensor history**.

---

## Why Batch the Data?

Sending every reading individually would generate:

- **60 HTTP requests per minute**
- **3,600 requests per hour**
- **86,400 requests per day**

Instead, the system sends:

- **1 request per minute**
- **60 requests per hour**
- **1,440 requests per day**

while still preserving every one-second sensor measurement.

This approach provides:

- Lower network bandwidth usage
- Reduced server load
- Complete historical resolution
- Better scalability for multiple monitoring devices

---

# Real-Time vs Backend Communication

The application performs two independent tasks simultaneously.

```
Every 1 Second
│
├── Read Temperature & Humidity
│
├── Broadcast to Dashboard
│
└── Store Reading in Memory
        │
        ▼
After 60 Readings
        │
        ▼
Create JSON Batch
        │
        ▼
POST to Backend API
        │
        ▼
Clear Buffer
        │
        ▼
Start Next Batch
```

Because backend uploads occur in a **separate background thread**, slow network requests never interrupt:

- Sensor sampling
- Dashboard updates
- Future data collection

---

# Example Backend Payload

Every minute, the backend receives a payload similar to:

```json
{
  "readings": [
    {
      "temperature_c": 4.1,
      "humidity": 74.2,
      "timestamp": "2026-07-11T10:00:01"
    },
    {
      "temperature_c": 4.0,
      "humidity": 74.1,
      "timestamp": "2026-07-11T10:00:02"
    },
    {
      "temperature_c": 4.2,
      "humidity": 74.0,
      "timestamp": "2026-07-11T10:00:03"
    }
  ]
}
```

Each payload contains **60 individual sensor readings**, preserving complete one-second resolution while reducing network overhead.

---

# Data Flow

```
                 Modulino Thermo
                        │
                   Read Every 1 Second
                        │
                        ▼
              Arduino UNO R4 WiFi
                        │
                 Bridge RPC Call
                        │
                        ▼
               Python Application
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ▼                           ▼
 Live Socket.IO Updates      Store Reading in Buffer
          │                           │
          ▼                           ▼
 Browser Dashboard          Buffer reaches 60 readings
                                        │
                                        ▼
                              HTTP POST to Backend
                                        │
                                        ▼
                                 Clear Buffer
                                        │
                                        ▼
                               Begin Next Collection
```

---

# Time-Temperature Integration (TTI)

Food quality depends on **both temperature and exposure time**, not temperature alone.

For example:

| Temperature | Typical Impact |
|-------------|----------------|
| 0–4°C | Ideal storage conditions |
| 5–7°C | Slight shelf-life reduction over time |
| 8–10°C | Accelerated bacterial growth |
| Above 10°C | Significant quality degradation |

Future versions of the project can use this historical data to calculate:

- Maximum temperature reached
- Minimum temperature
- Average temperature
- Time spent above safe thresholds
- Temperature excursion events
- Cooling recovery time
- Remaining shelf-life estimation

---

# Technologies Used

## Hardware

- Arduino UNO R4 WiFi
- Arduino Modulino Thermo
- Qwiic / I²C Connector

---

## Arduino Libraries

- Modulino
- Wire
- Bridge

---

## Python Packages

- Flask
- Flask-SocketIO
- Arduino Bridge API
- threading
- json
- urllib.request
- urllib.error
- os
- time

---

## Frontend

- HTML5
- CSS3
- JavaScript
- Socket.IO Client

---

# Project Structure

```
thermal-sensor-dashboard/
│
├── app.yaml
│   Application configuration
│
├── sketch/
│   ├── sketch.ino
│   │   Arduino firmware
│   │   • Initializes Modulino Thermo
│   │   • Reads temperature & humidity
│   │   • Exposes Bridge RPC endpoint
│   │
│   └── sketch.yaml
│       Board configuration
│
├── python/
│   └── main.py
│       Python backend
│       • Polls Arduino every second
│       • Broadcasts live readings
│       • Buffers one-minute sensor data
│       • Sends batched HTTP requests
│       • Handles browser requests
│
├── ui/
│   ├── index.html
│   │   Dashboard layout
│   │
│   ├── styles.css
│   │   Dashboard styling
│   │
│   └── app.js
│       Socket.IO client
│       Live rendering
│       Unit conversion
│
└── README.md
```

---

# Current Capabilities

- ✅ Live temperature monitoring
- ✅ Live humidity monitoring
- ✅ Automatic one-second sensor polling
- ✅ Real-time Socket.IO dashboard updates
- ✅ Celsius/Fahrenheit conversion
- ✅ Connection status monitoring
- ✅ Timestamp display
- ✅ One-minute backend batching
- ✅ Background asynchronous HTTP uploads
- ✅ Efficient network utilization

---

# Planned Enhancements

- 📊 Historical temperature graphs
- ☁️ FastAPI backend integration
- 🗄️ Database storage
- 📈 Temperature analytics
- 🚨 Automatic alert notifications
- ❄️ Cold-chain monitoring dashboard
- 🥛 Shelf-life prediction for dairy products
- 📦 Multi-device monitoring
- 👥 User authentication
- 📄 Exportable reports
- 🤖 Predictive quality analysis using Time-Temperature Integration (TTI)

---

# Future Vision

This project serves as the first stage of a complete IoT-based cold-chain monitoring platform.

Future iterations will extend the system beyond live visualization by storing historical sensor data, analyzing temperature excursions, estimating remaining shelf life, and generating automated alerts whenever products are exposed to unsafe environmental conditions.

By combining continuous sensor monitoring with cloud-based analytics, the platform aims to help ensure that temperature-sensitive products remain within safe storage conditions throughout their lifecycle, improving product quality, reducing waste, and supporting data-driven cold-chain management.