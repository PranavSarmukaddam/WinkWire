# Blink Keyboard

A blink-controlled virtual keyboard using R Shiny and Python (OpenCV + MediaPipe).

## Features
- Single and double blink detection
- Select letters from a virtual grid
- Real-time text prediction
- R-Python integration via file bridge

## How to Run
1. Start the R app: `app.R`
2. Click "Start Blink Detection"
3. The Python script will open webcam and detect blinks.

## Python Setup
```bash
pip install opencv-python mediapipe numpy
