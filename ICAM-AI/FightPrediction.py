import cv2
import numpy as np
import time
import boto3
from botocore.exceptions import NoCredentialsError
import os
from datetime import datetime
from tensorflow.keras.models import load_model
import numpy as np
from tensorflow.keras.preprocessing import image
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, Flatten, Input
from tensorflow.keras.applications import ResNet152
import requests
import json
import base64

PERSON_CLASS_ID = 1  # In COCO dataset, person is class 1
CONFIDENCE_THRESHOLD = 0.2
COOLDOWN_SECONDS = 2  # Time between captures to avoid multiple uploads of the same person

# AWS S3 Configuration - Set to your specific bucket
S3_BUCKET = 'predictionoutput'
S3_IMAGE_FOLDER = 'Predictionimage/'
S3_INFO_FOLDER = 'Predictioninfo/'
S3_REGION = 'us-west-2'  # Change this if your bucket is in a different region
LAMBDA_URL = 'https://cdi5oil6zfawmf5vngqa5yn6oq0nvotj.lambda-url.us-west-2.on.aws/'

input_layer = Input(shape=(224, 224, 3))  # Same input shape as before
base_model = ResNet152(weights='imagenet', include_top=False, input_tensor=input_layer)
x = Flatten()(base_model.output)
x = Dense(1024, activation='relu')(x)
x = Dense(512, activation='relu')(x)
output = Dense(8, activation='softmax')(x)
model = Model(inputs=base_model.input, outputs=output)
model.load_weights('model1.h5')

def upload_to_s3(local_file, s3_key):
    """Upload a file to the S3 bucket"""
    s3_client = boto3.client('s3', region_name=S3_REGION)
    try:
        s3_client.upload_file(local_file, S3_BUCKET, s3_key)
        print(f"Upload Successful: s3://{S3_BUCKET}/{s3_key}")
        return True
    except FileNotFoundError:
        print("The file was not found")
        return False
    except NoCredentialsError:
        print("Credentials not available")
        return False
    except Exception as e:
        print(f"Error uploading to S3: {str(e)}")
        return False

def detect_violence(img_array):
    predictions = model.predict(img_array)
    return predictions

def get_image():    
    # Open the camera using OpenCV with /dev/video10
    cap = cv2.VideoCapture(10)  # Use 10 for /dev/video10
    
    # Set camera properties if needed
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    cap.set(cv2.CAP_PROP_FORMAT, -1)
    
    if not cap.isOpened():
        print("Error: Could not open video device /dev/video10")
        return
    
    last_upload_time = 0
    
    while cap.isOpened():
        # Capture frame from OpenCV
        ret, frame = cap.read()
        if not ret:
            print("Failed to capture image from /dev/video10")
            time.sleep(0.2)
            continue
            
        # Convert BGR to RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # # Resize the frame to 224x224
        frame_resized = cv2.resize(frame_rgb, (224, 224))

        # # Prepare input for model
        img_array = np.expand_dims(frame_resized, axis=0)
        img_array = img_array / 255.0  # Normalize pixel values (optional but recommended)
        
        # Perform detection
        detections = detect_violence(img_array)[0]
        current_time = time.time()

        # if (detections[6] + detections[7] > 0.42):
        #     print("Peaceful scene")
        # elif (detections[0]+detections[5] > 0.32):
        #     print("Armed man fight")
        # elif (detections[1] + detections[2] + detections[3] > 0.32):
        #     print("Man fight")
        # else:
        #     print("unknown")
        print(detections[6] < 0.1)
        print(detections)
        if ((detections[6] < 0.1) and (current_time - last_upload_time) > COOLDOWN_SECONDS):
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            local_image_filename = f"aggressive_action_detected_{timestamp}.jpg"
            local_info_filename = f"aggressive_action_detected_{timestamp}.txt"
            
            frame = cv2.resize(frame, (320, 240))
            _, buffer = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 100])  # quality 0-100
            img_base64 = base64.b64encode(buffer).decode('utf-8')
            data = {
                "location": "ICAM-540",
                "ts": datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"),
                "image": img_base64
            }
            print(img_base64[:100])
            res = requests.post(LAMBDA_URL, headers={'Content-Type': 'application/json'}, data=json.dumps(data))
            print(res.text)
            print('Uploaded!')
            time.sleep(3)



    # Clean up
    cap.release()
    cv2.destroyAllWindows()
    print('end program')

if __name__ == "__main__":
    get_image()

    
