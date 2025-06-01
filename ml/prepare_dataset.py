import os
import shutil
import requests
from pathlib import Path
from tqdm import tqdm

DATASET_URLS = {
    'Yaman': 'https://example.com/dataset/yaman.zip',  # Replace with actual URLs
    'Bhairavi': 'https://example.com/dataset/bhairavi.zip',
    'Bhupali': 'https://example.com/dataset/bhupali.zip',
    # Add more raga URLs
}

def download_file(url, dest_path):
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    with open(dest_path, 'wb') as file, tqdm(
        desc=dest_path,
        total=total_size,
        unit='iB',
        unit_scale=True
    ) as pbar:
        for data in response.iter_content(chunk_size=1024):
            size = file.write(data)
            pbar.update(size)

def prepare_dataset():
    dataset_dir = Path('ml/datasets/raw')
    dataset_dir.mkdir(parents=True, exist_ok=True)
    
    for raga_name, url in DATASET_URLS.items():
        raga_dir = dataset_dir / raga_name
        raga_dir.mkdir(exist_ok=True)
        
        zip_path = dataset_dir / f"{raga_name}.zip"
        
        print(f"Downloading {raga_name} dataset...")
        download_file(url, zip_path)
        
        print(f"Extracting {raga_name} dataset...")
        shutil.unpack_archive(zip_path, raga_dir)
        zip_path.unlink()  # Remove zip file after extraction

if __name__ == '__main__':
    prepare_dataset()