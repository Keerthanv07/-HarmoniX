import os

def create_directories():
    dirs = [
        'ml/datasets',
        'ml/datasets/raw',
        'assets/models',
        'ml/checkpoints'
    ]
    
    for dir_path in dirs:
        os.makedirs(dir_path, exist_ok=True)
        print(f"Created directory: {dir_path}")

if __name__ == '__main__':
    create_directories()