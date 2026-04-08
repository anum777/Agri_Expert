// Configuration
const API_BASE_URL = 'http://localhost:8000';
const PREDICT_ENDPOINT = `${API_BASE_URL}/predict`;

// DOM Elements
const predictionForm = document.getElementById('predictionForm');
const resultSection = document.getElementById('resultSection');
const errorContainer = document.getElementById('errorContainer');
const loadingSpinner = document.getElementById('loadingSpinner');
const submitBtn = document.getElementById('submitBtn');

// Crop icons mapping
const cropIcons = {
  'rice': '🍚',
  'maize': '🌽',
  'wheat': '🌾',
  'barley': '🌾',
  'cotton': '🌫️',
  'sugarcane': '🌾',
  'chickpea': '🫘',
  'lentil': '🫘',
  'soyabean': '🌱',
  'groundnut': '🥜',
  'jute': '🌾',
  'coconut': '🥥',
  'potato': '🥔',
  'tomato': '🍅',
  'chick pea': '🫘',
};

// Event Listeners
predictionForm.addEventListener('submit', handleFormSubmit);

/**
 * Handle form submission
 */
async function handleFormSubmit(e) {
  e.preventDefault();
  
  // Clear previous errors
  clearError();
  
  // Get form values
  const formData = {
    nitrogen: parseFloat(document.getElementById('nitrogen').value),
    phosphorus: parseFloat(document.getElementById('phosphorus').value),
    potassium: parseFloat(document.getElementById('potassium').value),
    temperature: parseFloat(document.getElementById('temperature').value),
    humidity: parseFloat(document.getElementById('humidity').value),
    rainfall: parseFloat(document.getElementById('rainfall').value),
  };

  // Validate form data
  if (!validateFormData(formData)) {
    return;
  }

  // Show loading state
  showLoading(true);
  submitBtn.disabled = true;

  try {
    const response = await fetch(PREDICT_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Prediction failed. Please try again.');
    }

    const result = await response.json();
    
    // Display result
    displayResult(result, formData);
    
  } catch (error) {
    console.error('Error:', error);
    showError(error.message || 'Failed to get crop recommendation. Make sure the backend server is running.');
  } finally {
    showLoading(false);
    submitBtn.disabled = false;
  }
}

/**
 * Validate form data ranges
 */
function validateFormData(data) {
  const rules = {
    nitrogen: { min: 0, max: 140, name: 'Nitrogen' },
    phosphorus: { min: 0, max: 145, name: 'Phosphorus' },
    potassium: { min: 0, max: 205, name: 'Potassium' },
    temperature: { min: -8, max: 50, name: 'Temperature' },
    humidity: { min: 0, max: 100, name: 'Humidity' },
    rainfall: { min: 0, max: 300, name: 'Rainfall' },
  };

  for (const [key, rule] of Object.entries(rules)) {
    const value = data[key];
    if (value < rule.min || value > rule.max) {
      showError(`${rule.name} must be between ${rule.min} and ${rule.max}`);
      return false;
    }
  }

  return true;
}

/**
 * Display prediction result
 */
function displayResult(result, formData) {
  const cropName = result.recommended_crop.toLowerCase();
  const icon = cropIcons[cropName] || '🌾';
  const confidence = Math.round(result.confidence * 100);

  // Update result card
  document.getElementById('cropName').textContent = result.recommended_crop;
  document.querySelector('.crop-icon').textContent = icon;
  document.getElementById('confidenceText').textContent = `${confidence}%`;
  document.getElementById('confidenceBar').style.width = `${confidence}%`;

  // Update parameter display
  document.getElementById('resultN').textContent = `${formData.nitrogen} mg/kg`;
  document.getElementById('resultP').textContent = `${formData.phosphorus} mg/kg`;
  document.getElementById('resultK').textContent = `${formData.potassium} mg/kg`;
  document.getElementById('resultTemp').textContent = `${formData.temperature}°C`;
  document.getElementById('resultHum').textContent = `${formData.humidity}%`;
  document.getElementById('resultRain').textContent = `${formData.rainfall} mm`;

  // Show result section
  resultSection.classList.remove('hidden');
  
  // Scroll to result
  resultSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/**
 * Show error message
 */
function showError(message) {
  const errorDiv = document.createElement('div');
  errorDiv.className = 'alert alert-error';
  errorDiv.innerHTML = `
    <strong>Error:</strong> ${message}
    <button type="button" class="close-btn" onclick="this.parentElement.remove()">×</button>
  `;
  errorContainer.innerHTML = '';
  errorContainer.appendChild(errorDiv);
  errorContainer.scrollIntoView({ behavior: 'smooth' });
}

/**
 * Clear error messages
 */
function clearError() {
  errorContainer.innerHTML = '';
}

/**
 * Show/hide loading spinner
 */
function showLoading(show) {
  if (show) {
    loadingSpinner.classList.remove('hidden');
  } else {
    loadingSpinner.classList.add('hidden');
  }
}

/**
 * Reset form and hide result
 */
function resetForm() {
  predictionForm.reset();
  resultSection.classList.add('hidden');
  clearError();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Log initialization
console.log('Agri Expert frontend loaded successfully');
console.log(`API connected to: ${API_BASE_URL}`);
