import pandas as pd
import numpy as np
import os

# Remove the folder if it exists
import shutil
folder_path = os.path.join(os.path.dirname(__file__), "data", "Crop_recommendation.csv")
if os.path.isdir(folder_path):
    shutil.rmtree(folder_path)
    print(f"✓ Removed directory: {folder_path}")

# Create sample dataset
np.random.seed(42)

crops = [
    'rice', 'maize', 'chickpea', 'kidneybeans', 'pigeonpeas', 'mothbeans',
    'mungbean', 'blackgram', 'lentil', 'pomegranate', 'banana', 'mango',
    'grapes', 'watermelon', 'muskmelon', 'apple', 'orange', 'papaya',
    'coconut', 'cotton', 'sugarcane', 'tobacco'
]

n_samples = 2200

data = {
    'N': np.random.randint(0, 140, n_samples),
    'P': np.random.randint(5, 145, n_samples),
    'K': np.random.randint(5, 205, n_samples),
    'temperature': np.random.uniform(8, 43, n_samples),
    'humidity': np.random.uniform(14, 99, n_samples),
    'ph': np.random.uniform(4.5, 9.5, n_samples),
    'rainfall': np.random.uniform(20, 225, n_samples),
    'label': np.random.choice(crops, n_samples)
}

df = pd.DataFrame(data)

# Save dataset
data_dir = os.path.join(os.path.dirname(__file__), "data")
os.makedirs(data_dir, exist_ok=True)
csv_path = os.path.join(data_dir, "Crop_recommendation.csv")
df.to_csv(csv_path, index=False)

print(f"✓ Sample dataset created: {csv_path}")
print(f"  Rows: {len(df)}")
print(f"  Crops: {df['label'].nunique()}")
print(f"  Shape: {df.shape}")
