import tensorflow as tf
import librosa
import numpy as np
from pathlib import Path
import pandas as pd
from sklearn.model_selection import train_test_split
import datetime
import json

class ModelTrainer:
    def __init__(self):
        self.sample_rate = 44100
        self.duration = 30  # seconds
        self.hop_length = 512
        self.n_mels = 128
        self.n_fft = 2048
        self.num_classes = 10
        
        # Create directories if they don't exist
        self.checkpoint_dir = Path('ml/checkpoints')
        self.model_dir = Path('assets/models')
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        self.model_dir.mkdir(parents=True, exist_ok=True)

    def build_model(self):
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(self.n_mels, None, 1)),
            
            # First Conv Block
            tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Second Conv Block
            tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Third Conv Block
            tf.keras.layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Dense Layers
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dense(256, activation='relu'),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model

    def preprocess_audio(self, audio_path):
        # Load audio file
        y, sr = librosa.load(audio_path, sr=self.sample_rate)
        
        # Trim silence
        y, _ = librosa.effects.trim(y)
        
        # Ensure consistent length
        if len(y) > self.sample_rate * self.duration:
            y = y[:self.sample_rate * self.duration]
        else:
            y = np.pad(y, (0, self.sample_rate * self.duration - len(y)))
        
        # Compute mel spectrogram
        mel_spec = librosa.feature.melspectrogram(
            y=y,
            sr=self.sample_rate,
            n_fft=self.n_fft,
            hop_length=self.hop_length,
            n_mels=self.n_mels
        )
        
        # Convert to log scale
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)
        
        # Normalize
        mel_spec_norm = (mel_spec_db - mel_spec_db.mean()) / mel_spec_db.std()
        
        return mel_spec_norm

    def train(self, data_dir, epochs=50):
        # Setup logging
        current_time = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        log_dir = f'ml/logs/{current_time}'
        tensorboard_callback = tf.keras.callbacks.TensorBoard(log_dir=log_dir, histogram_freq=1)
        
        # Setup checkpointing
        checkpoint_path = self.checkpoint_dir / f"model-{current_time}.ckpt"
        checkpoint_callback = tf.keras.callbacks.ModelCheckpoint(
            filepath=str(checkpoint_path),
            save_weights_only=True,
            monitor='val_accuracy',
            mode='max',
            save_best_only=True
        )
        
        # Load and preprocess dataset
        print("Loading and preprocessing dataset...")
        X = []
        y = []
        raga_names = []
        
        for audio_path in Path(data_dir).rglob('*.wav'):
            raga_name = audio_path.parent.name
            if raga_name not in raga_names:
                raga_names.append(raga_name)
            mel_spec = self.preprocess_audio(str(audio_path))
            X.append(mel_spec)
            y.append(raga_name)
        
        # Save raga names mapping
        with open(self.model_dir / 'raga_names.json', 'w') as f:
            json.dump(raga_names, f)
        
        # Convert to numpy arrays
        X = np.array(X)
        y = pd.get_dummies(y).values
        
        print(f"Dataset shape: {X.shape}")
        print(f"Number of classes: {len(raga_names)}")
        
        # Split dataset
        X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Build and compile model
        model = self.build_model()
        model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        # Train model
        print("Starting training...")
        history = model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=epochs,
            batch_size=32,
            callbacks=[
                tf.keras.callbacks.EarlyStopping(patience=10, restore_best_weights=True),
                tf.keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=5),
                tensorboard_callback,
                checkpoint_callback
            ]
        )
        
        return model, history

    def convert_to_tflite(self, model, output_path):
        print("Converting model to TFLite format...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        output_path = Path(output_path)
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        print(f"TFLite model saved to: {output_path}")

    def build_deepsrgm_model(self):
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(128,)),  # SRGM features
            tf.keras.layers.Dense(256, activation='relu'),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(10, activation='softmax')  # 10 ragas
        ])
        return model

def main():
    # Set random seeds for reproducibility
    tf.random.set_seed(42)
    np.random.seed(42)
    
    trainer = ModelTrainer()
    
    print("Training CNN model...")
    model_cnn, history_cnn = trainer.train('ml/datasets/raw')
    
    # Save training history for CNN model
    history_path_cnn = Path('ml/logs/training_history_cnn.json')
    with open(history_path_cnn, 'w') as f:
        json.dump(history_cnn.history, f)
    print(f"Training history for CNN model saved to: {history_path_cnn}")
    
    # Convert CNN model to TFLite
    tflite_path_cnn = 'assets/models/raga_classifier_cnn.tflite'
    trainer.convert_to_tflite(model_cnn, tflite_path_cnn)

    print("Training DeepSRGM model...")
    model_deepsrgm = trainer.build_deepsrgm_model()
    # ... training code for DeepSRGM ...
    # For demonstration, we'll skip the actual training and conversion for DeepSRGM
    # You would need to implement the training loop and conversion to TFLite
    # for the DeepSRGM model, similar to what's done for the CNN model.

if __name__ == '__main__':
    main()

