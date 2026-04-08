# Complete Integration Guide: ESP32 + NPK Sensor + RS-485 + FastAPI + Flutter

## Architecture Overview
```
NPK Sensor (via RS-485/Modbus) 
    ↓
ESP32 (Reads sensor data via RS-485)
    ↓
FastAPI Backend (Receives NPK data)
    ↓
Flutter App (Fetches NPK + Weather, returns crop prediction)
```

---

## Hardware Setup

### **1. ESP32 Pinout Configuration**
```
ESP32 Pin  →  RS-485 Pin
GPIO16 (RX2) → RS-485 RX (Data In)
GPIO17 (TX2) → RS-485 TX (Data Out)
GPIO4  → RS-485 DE (Driver Enable)
GPIO5  → RS-485 RE (Receiver Enable)
GND    → RS-485 GND
3.3V   → RS-485 VCC
```

### **2. NPK Sensor Modbus Registers**
```
Register 0x001A = Nitrogen (N)
Register 0x001B = Phosphorus (P)
Register 0x001C = Potassium (K)
```

### **3. Wiring Diagram**
```
NPK Sensor A → RS-485 A (Data+)
NPK Sensor B → RS-485 B (Data-)
RS-485 GND   → NPK Sensor GND
```

---

## Software Setup

### **Step 1: Upload ESP32 Code**
1. Open Arduino IDE
2. Install **"ESP32 by Espressif Systems"** board
3. Install library: **"ArduinoJson"** (Sketch → Include Library → Manage Libraries)
4. Copy the code from `backend/esp32_npk_sensor.ino`
5. Update WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   const char* serverUrl = "http://YOUR_BACKEND_IP:8000/sensor/npk/update";
   ```
6. Upload to ESP32

### **Step 2: Backend Setup**
1. Navigate to backend folder:
   ```
   cd C:\Users\anushka\Agri_Expert\backend
   ```

2. Start FastAPI server:
   ```
   python app.py
   ```

3. Server runs on: `http://localhost:8000`

4. API Documentation: `http://localhost:8000/docs`

### **Step 3: Flutter Integration**
1. Update backend URL in `crop_prediction_service.dart`:
   ```dart
   static const String backendUrl = "http://YOUR_BACKEND_IP:8000";
   ```

2. Use the prediction service in your UI to:
   - Fetch NPK data from ESP32
   - Fetch weather data from OpenWeatherMap
   - Send both to backend for crop prediction

---

## API Endpoints

### **NPK Sensor Data (from ESP32)**
**GET** `/sensor/npk`
```json
Response:
{
  "nitrogen": 50.5,
  "phosphorus": 40.2,
  "potassium": 30.8,
  "timestamp": "2024-03-24T10:30:00Z"
}
```

### **Crop Prediction**
**POST** `/predict`
```json
Request:
{
  "nitrogen": 50.5,
  "phosphorus": 40.2,
  "potassium": 30.8,
  "temperature": 25.5,
  "humidity": 70,
  "rainfall": 120
}

Response:
{
  "recommended_crop": "rice",
  "confidence": 0.95
}
```

---

## Troubleshooting

### ESP32 Issues
- **No WiFi connection**: Check SSID/password in code
- **Can't read sensor**: Verify RS-485 wiring and Modbus address
- **Data not reaching backend**: Check firewall and backend IP

### Backend Issues
- **ModuleNotFoundError**: Run `pip install -r requirements.txt`
- **Port 8000 already in use**: Change port in `app.py`

### Flutter Issues
- **Backend not responding**: Ensure backend IP is correct
- **No NPK data**: Check if ESP32 is connected and sending data
- **Prediction fails**: Verify all 6 input values are provided

---

## Testing Workflow

### 1. Test ESP32 Connection
```
Serial Monitor in Arduino IDE should show:
N: 50.5 | P: 40.2 | K: 30.8
Data sent successfully!
```

### 2. Test Backend API
Visit: `http://localhost:8000/docs`
- Click **/sensor/npk** → Try it out → Get current NPK data
- Click **/predict** → Try it out → Enter sample values → Execute

### 3. Test Flutter App
- App fetches NPK from backend
- App fetches weather from OpenWeatherMap
- App displays crop prediction

---

## File Locations
```
backend/
├── app.py                    (FastAPI server)
├── esp32_npk_sensor.ino      (ESP32 code)
├── train_model.py            (Model training)
├── models/
│   └── crop_model.pkl        (Trained model)
└── data/
    └── Crop_recommendation.csv

mobile/lib/services/
├── crop_prediction_service.dart  (API calls)
├── weather_service.dart          (Weather API)
└── firebase_service.dart         (Firebase auth)
```

---

## Next Steps
1. ✓ Train ML model
2. ✓ Set up FastAPI server
3. ✓ Configure ESP32
4. → Test all integrations
5. → Deploy to production
