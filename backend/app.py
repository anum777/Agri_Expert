from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import os
import numpy as np
from datetime import datetime

# Initialize FastAPI app
app = FastAPI(
    title="Agri Expert API",
    description="Smart Crop Recommendation System",
    version="1.0.0"
)

# Global variable to store latest NPK sensor data
latest_npk_data = {
    "nitrogen": 50,
    "phosphorus": 40,
    "potassium": 30,
    "timestamp": datetime.now().isoformat()
}

# Add CORS middleware to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the trained models (Random Forest + XGBoost Ensemble)
models_dir = os.path.join(os.path.dirname(__file__), "models")
rf_model_path = os.path.join(models_dir, "rf_model.pkl")
xgb_model_path = os.path.join(models_dir, "xgb_model.pkl")
encoder_path = os.path.join(models_dir, "label_encoder.pkl")

if not os.path.exists(rf_model_path) or not os.path.exists(xgb_model_path):
    raise FileNotFoundError(
        f"Models not found. Please run train_model.py first in the backend directory."
    )

rf_model = joblib.load(rf_model_path)
xgb_model = joblib.load(xgb_model_path)
label_encoder = joblib.load(encoder_path) if os.path.exists(encoder_path) else None

# Input validation schema
class CropPredictionInput(BaseModel):
    nitrogen: float = Field(..., gt=0, description="Nitrogen content in soil (N)")
    phosphorus: float = Field(..., gt=0, description="Phosphorus content in soil (P)")
    potassium: float = Field(..., gt=0, description="Potassium content in soil (K)")
    temperature: float = Field(..., description="Temperature in Celsius")
    humidity: float = Field(..., ge=0, le=100, description="Humidity percentage (0-100)")
    rainfall: float = Field(..., ge=0, description="Rainfall in mm")

# NPK Sensor Input Schema
class NPKSensorInput(BaseModel):
    nitrogen: float = Field(..., ge=0, description="Nitrogen value from sensor")
    phosphorus: float = Field(..., ge=0, description="Phosphorus value from sensor")
    potassium: float = Field(..., ge=0, description="Potassium value from sensor")
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())

# Response schema
class CropPredictionResponse(BaseModel):
    recommended_crop: str
    confidence: float
    reasoning: str
    input_summary: dict

# Ensemble prediction function
def predict_ensemble(features):
    """Predict crop using Random Forest + XGBoost ensemble with soft voting"""
    # Random Forest predictions
    rf_proba = rf_model.predict_proba(features)
    rf_classes = rf_model.classes_
    
    # XGBoost predictions (with label encoding)
    xgb_proba_encoded = xgb_model.predict_proba(features)
    xgb_pred_encoded = xgb_model.predict(features)
    
    # Map XGBoost predictions (encoded) to RF classes
    xgb_proba = np.zeros((len(features), len(rf_classes)))
    
    for sample_idx, encoded_pred in enumerate(xgb_pred_encoded):
        for class_idx, rf_class in enumerate(rf_classes):
            # Get the encoded value for this RF class
            encoded_class = label_encoder.transform([rf_class])[0]
            if encoded_class == encoded_pred:
                xgb_proba[sample_idx, class_idx] = xgb_proba_encoded[sample_idx, encoded_pred]
    
    # Soft voting: average probabilities
    ensemble_proba = (rf_proba + xgb_proba) / 2
    
    # Get prediction and confidence
    best_idx = np.argmax(ensemble_proba[0])
    prediction = rf_classes[best_idx]
    confidence = float(ensemble_proba[0, best_idx])
    
    return prediction, confidence

# Health check endpoint
@app.get("/")
def read_root():
    return {
        "message": "Agri Expert API is running",
        "endpoints": {
            "/docs": "API documentation",
            "/predict": "POST - Get crop recommendation"
        }
    }

# Prediction endpoint
@app.post("/predict", response_model=CropPredictionResponse)
def predict_crop(input_data: CropPredictionInput):
    """
    Predict the best crop to grow based on soil and weather parameters.
    Uses Random Forest + XGBoost ensemble with soft voting.
    
    Parameters:
    - nitrogen: NPK sensor value (0-140)
    - phosphorus: NPK sensor value (5-145)
    - potassium: NPK sensor value (5-205)
    - temperature: Weather API value (-8 to 50°C)
    - humidity: Weather API value (0-100%)
    - rainfall: Weather API value (20-225 mm)
    
    Returns:
    - recommended_crop: Best crop for the given conditions
    - confidence: Confidence score (0-1)
    - reasoning: Explanation of why this crop is recommended
    - input_summary: Summary of input parameters
    """
    try:
        # Prepare features in the same order as training
        features = np.array([[
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.rainfall
        ]])
        
        # Make ensemble prediction
        prediction, confidence = predict_ensemble(features)
        
        # Generate reasoning based on input values
        reasoning = _generate_reasoning(
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.rainfall,
            prediction
        )
        
        # Create input summary
        input_summary = {
            "nitrogen": input_data.nitrogen,
            "phosphorus": input_data.phosphorus,
            "potassium": input_data.potassium,
            "temperature": input_data.temperature,
            "humidity": input_data.humidity,
            "rainfall": input_data.rainfall
        }
        
        return CropPredictionResponse(
            recommended_crop=prediction,
            confidence=confidence,
            reasoning=reasoning,
            input_summary=input_summary
        )
    
    except Exception as e:
        print(f"ERROR in predict_crop: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

def _generate_reasoning(n, p, k, temp, humidity, rainfall, crop):
    """Generate human-readable reasoning for crop prediction"""
    reasons = []
    
    # Nitrogen level analysis
    if n > 100:
        reasons.append(f"High Nitrogen level ({n}) is ideal")
    elif n > 50:
        reasons.append(f"Good Nitrogen level ({n})")
    else:
        reasons.append(f"Moderate Nitrogen level ({n})")
    
    # Temperature analysis
    if temp > 25:
        reasons.append(f"Warm climate ({temp}°C) favors {crop}")
    elif temp < 15:
        reasons.append(f"Cool climate ({temp}°C) suits {crop}")
    else:
        reasons.append(f"Moderate temperature ({temp}°C)")
    
    # Humidity analysis
    if humidity > 70:
        reasons.append(f"High humidity ({humidity}%) is suitable")
    elif humidity < 30:
        reasons.append(f"Low humidity ({humidity}%) is suitable")
    else:
        reasons.append(f"Moderate humidity ({humidity}%)")
    
    # Rainfall analysis
    if rainfall > 150:
        reasons.append(f"High rainfall ({rainfall}mm) is beneficial")
    elif rainfall < 50:
        reasons.append(f"Low rainfall ({rainfall}mm) is manageable")
    else:
        reasons.append(f"Moderate rainfall ({rainfall}mm)")
    
    reasoning = " • ".join(reasons)
    return reasoning

# Debug endpoint - GET top 5 predictions
@app.post("/predict-debug")
def predict_crop_debug(input_data: CropPredictionInput):
    """
    Debug endpoint that returns top 5 crop predictions with probabilities.
    """
    try:
        # Prepare features in the same order as training
        features = np.array([[
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.rainfall
        ]])
        
        # Get prediction probabilities for all classes (no scaling needed)
        probabilities = model.predict_proba(features)[0]
        classes = model.classes_
        
        # Create list of (crop, probability) and sort
        predictions = list(zip(classes, probabilities))
        predictions.sort(key=lambda x: x[1], reverse=True)
        
        # Return top 5
        top_5 = predictions[:5]
        
        return {
            "top_5_predictions": [
                {"crop": crop, "confidence": float(conf)} 
                for crop, conf in top_5
            ],
            "input_values": {
                "nitrogen": input_data.nitrogen,
                "phosphorus": input_data.phosphorus,
                "potassium": input_data.potassium,
                "temperature": input_data.temperature,
                "humidity": input_data.humidity,
                "rainfall": input_data.rainfall
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# NPK Sensor endpoint - GET latest data
@app.get("/sensor/npk")
def get_npk_sensor_data():
    """
    Get current NPK sensor data from ESP32 device.
    Returns the latest data received from the sensor.
    """
    return latest_npk_data

# NPK Sensor endpoint - POST (receives data from ESP32)
@app.post("/sensor/npk/update")
def update_npk_sensor_data(data: NPKSensorInput):
    """
    Receive NPK sensor data from ESP32 via Modbus RS-485.
    This endpoint is called by the ESP32 microcontroller every 10 seconds.
    """
    global latest_npk_data
    latest_npk_data = {
        "nitrogen": data.nitrogen,
        "phosphorus": data.phosphorus,
        "potassium": data.potassium,
        "timestamp": data.timestamp
    }
    return {
        "status": "success",
        "message": "NPK data received",
        "data": latest_npk_data
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
