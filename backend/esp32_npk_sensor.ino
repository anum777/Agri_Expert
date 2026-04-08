#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Backend API URL
const char* serverUrl = "http://YOUR_BACKEND_IP:8000/sensor/npk/update";

// Modbus RS-485 pins
#define RX_PIN 16
#define TX_PIN 17
#define RE_PIN 4  // Read Enable
#define DE_PIN 5  // Driver Enable

// NPN sensor values (from Modbus registers)
float nitrogen = 0;
float phosphorus = 0;
float potassium = 0;

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);  // Modbus RS-485
  
  pinMode(DE_PIN, OUTPUT);
  pinMode(RE_PIN, OUTPUT);
  digitalWrite(DE_PIN, LOW);
  digitalWrite(RE_PIN, HIGH);
  
  // Connect to WiFi
  connectToWiFi();
}

void loop() {
  // Read NPK values from sensor via Modbus RS-485
  readNPKSensor();
  
  // Send data to backend every 10 seconds
  sendDataToBackend();
  
  delay(10000);
}

void connectToWiFi() {
  Serial.println("\nConnecting to WiFi...");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.println("IP address: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nFailed to connect to WiFi");
  }
}

void readNPKSensor() {
  // Read Nitrogen (Register 0x001A)
  nitrogen = readModbusRegister(0x01, 0x001A, 1) / 10.0;
  delay(100);
  
  // Read Phosphorus (Register 0x001B)
  phosphorus = readModbusRegister(0x01, 0x001B, 1) / 10.0;
  delay(100);
  
  // Read Potassium (Register 0x001C)
  potassium = readModbusRegister(0x01, 0x001C, 1) / 10.0;
  
  Serial.print("N: ");
  Serial.print(nitrogen);
  Serial.print(" | P: ");
  Serial.print(phosphorus);
  Serial.print(" | K: ");
  Serial.println(potassium);
}

// Read single Modbus register
float readModbusRegister(byte slaveID, int startAddr, int numRegs) {
  byte request[] = {slaveID, 0x03, 0x00, 0x00, 0x00, numRegs, 0x00, 0x00};
  
  // Set address in request
  request[2] = (startAddr >> 8) & 0xFF;
  request[3] = startAddr & 0xFF;
  
  // Calculate CRC
  uint16_t crc = calculateCRC(request, 6);
  request[6] = crc & 0xFF;
  request[7] = (crc >> 8) & 0xFF;
  
  // Send request
  digitalWrite(DE_PIN, HIGH);
  digitalWrite(RE_PIN, LOW);
  Serial2.write(request, 8);
  Serial2.flush();
  digitalWrite(DE_PIN, LOW);
  digitalWrite(RE_PIN, HIGH);
  
  // Wait for response
  delay(100);
  
  // Read response
  byte response[7];
  if (Serial2.readBytes(response, 7) == 7) {
    // Extract value from response
    int value = (response[3] << 8) | response[4];
    return (float)value;
  }
  
  return 0.0;
}

// Calculate Modbus CRC
uint16_t calculateCRC(byte* data, int length) {
  uint16_t crc = 0xFFFF;
  for (int i = 0; i < length; i++) {
    crc ^= data[i];
    for (int j = 0; j < 8; j++) {
      if (crc & 1) {
        crc = (crc >> 1) ^ 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

void sendDataToBackend() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    // Create JSON payload
    StaticJsonDocument<200> jsonDoc;
    jsonDoc["nitrogen"] = nitrogen;
    jsonDoc["phosphorus"] = phosphorus;
    jsonDoc["potassium"] = potassium;
    jsonDoc["timestamp"] = millis();
    
    String jsonString;
    serializeJson(jsonDoc, jsonString);
    
    Serial.println("Sending: " + jsonString);
    
    // Send POST request
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    
    int httpCode = http.POST(jsonString);
    
    if (httpCode == 200) {
      Serial.println("Data sent successfully!");
    } else {
      Serial.print("Error: ");
      Serial.println(httpCode);
    }
    
    http.end();
  } else {
    Serial.println("WiFi not connected");
      connectToWiFi();
  }
}
