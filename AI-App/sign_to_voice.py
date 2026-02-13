import cv2
import time
import pyttsx3
from hand.hand import HandTracker
import numpy as np

"""
Simple sign-language-to-voice demo.

This script uses the existing HandTracker to detect hand landmarks and a
small rule-based recognizer to speak a handful of signs:
- open palm -> "Hello"
- thumbs up -> "Good"
- thumbs down -> "Bad"
- fist (all fingers folded) -> "Stop"

This is a demo / starting point. For real sign language recognition you
should train a model on labeled sign data.

Usage:
    python sign_to_voice.py

Press 'q' to quit.
"""


def speak(text: str):
    engine = pyttsx3.init()
    engine.say(text)
    engine.runAndWait()


def fingers_up(hand):
    """Return a list of booleans for 5 fingers (thumb...pinky) whether they are up.

    Expects `hand` to be a list of (id, x, y) tuples for 21 landmarks.
    Landmark ids follow MediaPipe's convention.
    """
    # simple geometric tests using y coordinates (smaller y == higher on image)
    # return [thumb_up, index_up, middle_up, ring_up, pinky_up]
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    tips = [4, 8, 12, 16, 20]
    pip_joints = [2, 6, 10, 14, 18]
    results = []
    for tip, pip in zip(tips, pip_joints):
        if tip in coords and pip in coords:
            tx, ty = coords[tip]
            px, py = coords[pip]
            results.append(ty < py)
        else:
            results.append(False)
    return results


def is_thumb_left_of_index(hand):
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    if 4 in coords and 8 in coords:
        tx, ty = coords[4]
        ix, iy = coords[8]
        return tx < ix
    return False


def recognize(hand):
    """Very small rule-based recognizer.

    Returns a short label or None.
    """
    if not hand:
        return None
    up = fingers_up(hand)
    # Open palm: all fingers up
    if all(up):
        return "Hello"
    # Fist: no fingers up
    if not any(up):
        return "Stop"
    # Thumbs up: thumb up, others down, thumb left/right heuristics ignored
    if up[0] and not any(up[1:]):
        # Also check thumb is to the left of index (rough heuristic for vertical thumb)
        return "Good"
    # Thumbs down: thumb down, others up (very rough)
    if (not up[0]) and any(up[1:]):
        return "Bad"
    return None


def main():
    cap = cv2.VideoCapture(0)
    tracker = HandTracker(max_num_hands=1)
    pTime = 0
    last_spoken = None
    last_spoken_time = 0
    cooldown = 1.5  # seconds between repeated speaks

    try:
        while True:
            success, img = cap.read()
            if not success:
                break
            landmarks = tracker.process(img, return_pixel_landmarks=True)
            label = None
            if landmarks and len(landmarks) > 0:
                hand0 = landmarks[0]
                label = recognize(hand0)
                if label:
                    cv2.putText(img, label, (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 2)
                    now = time.time()
                    if label != last_spoken or (now - last_spoken_time) > cooldown:
                        last_spoken = label
                        last_spoken_time = now
                        speak(label)

            tracker.draw_landmarks(img)
            cTime = time.time()
            fps = 1 / (cTime - pTime) if pTime else 0
            pTime = cTime
            cv2.putText(img, str(int(fps)), (10, 70), cv2.FONT_HERSHEY_PLAIN, 3, (255, 0, 255), 3)
            cv2.imshow("Sign to Voice", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()
        tracker.close()


if __name__ == '__main__':
    main()
