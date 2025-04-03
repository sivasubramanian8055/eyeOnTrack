import os
import cv2
import numpy as np
import base64

# ----- Configuration -----
IMG_SIZE = (64, 56)   # Expected input size for your TFLite model in Flutter

# Load Haar cascades for face and eye detection.
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
eye_cascade  = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')

def process_frame(frame):
    """
    Processes an OpenCV BGR frame:
      1. Converts the frame to grayscale.
      2. Detects the first face using Haar cascades.
      3. Detects eyes within the face region using Haar cascades.
      4. Crops each eye, resizes to IMG_SIZE, and encodes each as a JPEG.
      5. Returns a dictionary with Base64‑encoded JPEG strings for the left and right eyes.
         If detection fails, returns a dictionary with an "error" key.
    """
    # Convert frame to grayscale.
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # Detect face using Haar cascades.
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5)
    if len(faces) == 0:
        return {"error": "No face detected"}
    
    # Use the first detected face.
    (x, y, w, h) = faces[0]
    face_roi = gray[y:y+h, x:x+w]
    
    # Detect eyes within the face region.
    eyes = eye_cascade.detectMultiScale(face_roi)
    if len(eyes) == 0:
        return {"error": "No eyes detected"}
    
    eyes_absolute = []
    for (ex, ey, ew, eh) in eyes:
        eyes_absolute.append((x + ex, y + ey, ew, eh))
    
    eyes_absolute = sorted(eyes_absolute, key=lambda v: v[0])
    
    left_eye_image = None
    right_eye_image = None
    
    if len(eyes_absolute) >= 1:
        (ex, ey, ew, eh) = eyes_absolute[0]
        eye_roi = gray[ey:ey+eh, ex:ex+ew]
        try:
            eye_resized = cv2.resize(eye_roi, IMG_SIZE)
        except cv2.error:
            eye_resized = None
        if eye_resized is not None:
            ret, buffer = cv2.imencode('.jpg', eye_resized)
            if ret:
                left_eye_image = base64.b64encode(buffer).decode('utf-8')
    
    if len(eyes_absolute) >= 2:
        (ex, ey, ew, eh) = eyes_absolute[1]
        eye_roi = gray[ey:ey+eh, ex:ex+ew]
        try:
            eye_resized = cv2.resize(eye_roi, IMG_SIZE)
        except cv2.error:
            eye_resized = None
        if eye_resized is not None:
            ret, buffer = cv2.imencode('.jpg', eye_resized)
            if ret:
                right_eye_image = base64.b64encode(buffer).decode('utf-8')
    
    return {"left_eye": left_eye_image, "right_eye": right_eye_image}

def process_straight_frame(image_bytes):
    """
    Accepts JPEG-encoded image bytes, decodes them into an OpenCV BGR frame,
    then calls process_frame() to process the image and return the processed eye images.
    """
    np_arr = np.frombuffer(image_bytes, np.uint8)
    frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if frame is None:
        return {"error": "Could not decode image"}
    return process_frame(frame)
