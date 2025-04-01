import os
import cv2
import dlib
import numpy as np
from imutils import face_utils
from tensorflow.keras.models import load_model
import sys

# Adjust these paths as needed
script_dir = os.path.dirname(__file__)
predictor_path = os.path.join(script_dir, "shape_predictor_68_face_landmarks.dat")
model_path_gaze = os.path.join(script_dir, "gazev3.1.h5")

# Debug: Print out the model path and check if the file exists.
print("DEBUG: Model path:", model_path_gaze)
if not os.path.exists(model_path_gaze):
    print("ERROR: Model file does not exist at this path!")
    sys.exit(1)
sys.stdout.flush()

# Load dlib detectors and Keras model once at import time
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(predictor_path)

try:
    print("DEBUG: Attempting to load model from:", model_path_gaze)
    sys.stdout.flush()
    model_gaze = load_model(model_path_gaze)
    print("DEBUG: Model loaded successfully.")
    sys.stdout.flush()
except Exception as e:
    import traceback
    traceback.print_exc()
    print("Error loading model from", model_path_gaze, ":", str(e))
    sys.stdout.flush()
    # Depending on your desired behavior, you might want to exit or assign a fallback.
    model_gaze = None

IMG_SIZE = (64, 56)  # (width, height) for your gaze model
class_labels = ['center', 'left', 'right']

def detect_gaze(eye_img):
    """Runs the loaded gaze model on a preprocessed eye image."""
    if model_gaze is None:
        return "Model not loaded"
    preds = model_gaze.predict(eye_img)
    gaze_idx = int(np.argmax(preds[0]))
    return class_labels[gaze_idx]

def crop_eye(gray, eye_points):
    """
    Crops the eye region from a grayscale face image, 
    given an array of landmark points (6 points for one eye).
    """
    x1, y1 = np.amin(eye_points, axis=0)
    x2, y2 = np.amax(eye_points, axis=0)
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2

    # Expand the bounding box slightly
    w = (x2 - x1) * 1.2
    h = w * IMG_SIZE[1] / IMG_SIZE[0]
    margin_x, margin_y = w / 2, h / 2

    min_x, min_y = int(cx - margin_x), int(cy - margin_y)
    max_x, max_y = int(cx + margin_x), int(cy + margin_y)
    eye_img = gray[min_y:max_y, min_x:max_x]
    return eye_img

def process_frame(frame):
    """
    1) Converts the frame to grayscale.
    2) Detects the first face using dlib.
    3) Extracts the left eye region (landmarks 36 to 41).
    4) Resizes and normalizes the eye image for the gaze model.
    5) Returns the detected gaze (string) or an error message.
    """
    try:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = detector(gray)
        if len(faces) == 0:
            return "No face detected"

        face = faces[0]
        shape = predictor(gray, face)
        shape_np = face_utils.shape_to_np(shape)
        
        # Debug prints to trace the type and content of shape_np.
        print("DEBUG: Type of shape_np:", type(shape_np))
        print("DEBUG: shape_np content:", shape_np)
        if hasattr(shape_np, "shape"):
            print("DEBUG: shape_np.shape:", shape_np.shape)
        sys.stdout.flush()
        
        # Attempt to slice the array for landmarks 36 to 41.
        print("DEBUG: Attempting to slice shape_np[36:42] ...")
        sliced = shape_np[36:42]
        print("DEBUG: Sliced array:", sliced)
        sys.stdout.flush()
        
        eye_img_l = crop_eye(gray, sliced)
        if eye_img_l.size == 0:
            return "Could not crop left eye"

        eye_img_l_resized = cv2.resize(eye_img_l, IMG_SIZE)
        eye_input = eye_img_l_resized.reshape((1, IMG_SIZE[1], IMG_SIZE[0], 1)).astype(np.float32) / 255.0

        gaze = detect_gaze(eye_input)
        return f"Gaze: {gaze}"
    
    except Exception as e:
        import traceback
        traceback.print_exc()
        return f"Error in process_frame: {str(e)}"

def process_straight_frame(image_bytes):
    """
    Accepts JPEG-encoded image bytes, decodes them into an OpenCV BGR frame,
    then calls process_frame() to perform gaze detection.
    """
    print("DEBUG: type(image_bytes):", type(image_bytes))
    sys.stdout.flush()
    try:
        np_arr = np.frombuffer(image_bytes, np.uint8)
    except Exception as ex:
        return f"Error in np.frombuffer: {str(ex)}"
    frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if frame is None:
        return "Error: Could not decode image"
    return process_frame(frame)
