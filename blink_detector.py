import os
import cv2
import mediapipe as mp
import math
import time

# Absolute path for blink_flag.txt
flag_file = "F:/blink-keyboard/blink_flag.txt"

# Reset blink flag file at start
with open(flag_file, "w") as f:
    f.write("0")
    f.flush()
    os.fsync(f.fileno())

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(max_num_faces=1)

# Eye landmark indices for MediaPipe
LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [263, 387, 385, 362, 380, 373]

def eye_aspect_ratio(landmarks, eye_indices):
    def dist(p1, p2):
        return math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)
    
    A = dist(landmarks[eye_indices[1]], landmarks[eye_indices[5]])
    B = dist(landmarks[eye_indices[2]], landmarks[eye_indices[4]])
    C = dist(landmarks[eye_indices[0]], landmarks[eye_indices[3]])
    ear = (A + B) / (2.0 * C)
    return ear

EAR_THRESHOLD = 0.29          # tuned for your face
CONSEC_FRAMES = 3             # blink must persist for 3 frames
blink_counter = 0

# Timing variables for blink logic
last_blink_time = 0
double_blink_time_threshold = 0.5  # seconds
pending_single_blink = False

cap = cv2.VideoCapture(0)

while True:
    success, frame = cap.read()
    if not success:
        break

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(frame_rgb)

    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0].landmark

        left_ear = eye_aspect_ratio(landmarks, LEFT_EYE)
        right_ear = eye_aspect_ratio(landmarks, RIGHT_EYE)
        avg_ear = (left_ear + right_ear) / 2.0

        if avg_ear < EAR_THRESHOLD:
            blink_counter += 1
        else:
            if blink_counter >= CONSEC_FRAMES:
                current_time = time.time()

                # Check for double blink
                if pending_single_blink and (current_time - last_blink_time) <= double_blink_time_threshold:
                    print("Double blink!")
                    with open(flag_file, "w") as f:
                        f.write("2")
                        f.flush()
                        os.fsync(f.fileno())
                    pending_single_blink = False
                else:
                    # Start waiting for second blink
                    pending_single_blink = True
                    last_blink_time = current_time

                blink_counter = 0

    # Handle confirmed single blink if second doesn't occur
    if pending_single_blink:
        if (time.time() - last_blink_time) > double_blink_time_threshold:
            print("Blink detected!")
            with open(flag_file, "w") as f:
                f.write("1")
                f.flush()
                os.fsync(f.fileno())
            pending_single_blink = False

    cv2.imshow("Blink Detection", frame)
    if cv2.waitKey(1) & 0xFF == 27:  # ESC to exit
        break

cap.release()
cv2.destroyAllWindows()
