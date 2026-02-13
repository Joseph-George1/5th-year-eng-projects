# computer-v

Small collection of hand-tracking demos using MediaPipe and OpenCV.

This repository contains:

- `hand/hand.py` - A `HandTracker` class wrapping MediaPipe Hands. It provides:
  - `process(frame, return_pixel_landmarks=False)` - process a BGR OpenCV frame. If `return_pixel_landmarks=True` returns list of hands -> list of (id, cx, cy).
  - `get_hands_landmarks()` - returns landmarks as list of (id, cx, cy) tuples per hand.
  - `draw_landmarks(frame)` - draw landmarks onto the provided frame.
  - `close()` - release resources associated with the tracker.

- `sign_to_voice.py` - Demo script that uses `HandTracker` and a tiny rule-based recognizer to map a few simple poses to speech using `pyttsx3`.

- `volume-hand-controle.py` - Demo that maps thumb-index distance to system volume. If `pycaw` is installed on Windows, it will set the system volume; otherwise it displays the mapped volume on-screen.

Requirements
-----------
Install dependencies listed in `requirements.txt` (recommended to use a virtual environment):

```powershell
python -m pip install -r requirements.txt
```

On Windows, if you want `volume-hand-controle.py` to actually change system volume install `pycaw` and its dependencies:

```powershell
python -m pip install pycaw comtypes
```

Running the demos
-----------------
- Sign to Voice demo:

```powershell
python sign_to_voice.py
```

- Volume control demo:

```powershell
python volume-hand-controle.py
```

Usage notes
-----------
- The rule-based recognizer in `sign_to_voice.py` is intentionally simple. It recognizes only a few poses and is meant as a starting point. For accurate sign language recognition you should collect labeled data and train a model (e.g., with scikit-learn, TensorFlow, or PyTorch).

- `HandTracker` outputs landmark coordinates as pixel positions when `process(..., return_pixel_landmarks=True)` is used. The format is a list of hands; each hand is a list of 21 tuples (id, cx, cy) where `id` is the MediaPipe landmark index.

Troubleshooting
---------------
- If your camera doesn't open, make sure no other application is using it and that your device index is correct.
- If TTS doesn't produce sound, try running a small `pyttsx3` example in isolation to confirm the backend works on your platform.

Contributing / next steps
-------------------------
- Improve the recognizer by collecting labeled samples and training a classifier.
- Add temporal smoothing or sequence models for signed words/phrases.
- Add unit tests for the utility functions.

License
-------
This repository contains example/demo code and is provided as-is.
