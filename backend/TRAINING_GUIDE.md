# ML Model Training Guide

## Step-by-Step Setup

### 1. **Download the Dataset**
   - Visit [Kaggle - Crop Recommendation Dataset](https://www.kaggle.com/datasets/atharvaingle/crop-recommendation-dataset)
   - Login/signup to Kaggle (if not already done)
   - Click **Download**
   - Extract the CSV file and place it in the `backend/data/` folder
   - Rename it to `Crop_recommendation.csv` (if needed)

### 2. **Set Up Python Environment**
   - Open PowerShell or Command Prompt
   - Navigate to the backend folder:
     ```bash
     cd C:\Users\anushka\Agri_Expert\backend
     ```

   - Create a virtual environment:
     ```bash
     python -m venv venv
     ```

   - Activate the virtual environment:
     ```bash
     .\venv\Scripts\Activate.ps1
     ```
     (If you get a PowerShell error, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`)

   - Install dependencies:
     ```bash
     pip install -r requirements.txt
     ```

### 3. **Train the Model**
   - Run the training script:
     ```bash
     python train_model.py
     ```

   - The script will:
     ✓ Load and explore the dataset
     ✓ Preprocess and scale features
     ✓ Split data into 80% train, 20% test
     ✓ Train a RandomForestClassifier
     ✓ Print accuracy, classification report, and confusion matrix
     ✓ Save the trained model as `models/crop_model.pkl`
     ✓ Save the scaler as `models/scaler.pkl`

### 4. **Expected Output**
   - The training script prints:
     - Dataset shape and statistics
     - Training and test accuracy (expect ~99% accuracy)
     - Classification report for each crop
     - Feature importance rankings
     - Saved model location

### 5. **Next Steps**
   - Once training is complete, proceed to FastAPI setup (`app.py`)
   - The trained model will be used for prediction endpoints

## Folder Structure
```
backend/
├── data/
│   └── Crop_recommendation.csv       # Dataset (download from Kaggle)
├── models/
│   ├── crop_model.pkl                # Trained model (generated after training)
│   └── scaler.pkl                    # Feature scaler (generated after training)
├── train_model.py                    # Training script
├── requirements.txt                  # Python dependencies
└── app.py                            # FastAPI server (next step)
```

## Troubleshooting

**"No such file or directory: 'data/Crop_recommendation.csv'"**
- Solution: Download the dataset from Kaggle and place it in the `data/` folder

**"ModuleNotFoundError: No module named 'pandas'"**
- Solution: Run `pip install -r requirements.txt` in the virtual environment

**"Virtual environment not activating"**
- Solution: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` first

## Dataset Details
- **Source**: Kaggle - Crop Recommendation Dataset
- **Rows**: 2,200
- **Features**: 7 (N, P, K, temperature, humidity, ph, rainfall)
- **Target**: 22 crop labels
- **Format**: CSV
