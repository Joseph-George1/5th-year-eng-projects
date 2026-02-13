import cv2
import mediapipe as mp
import time
from typing import List, Tuple, Optional


"""Hand tracking utility module.

This module exposes a HandTracker class that wraps MediaPipe's hand
solution and provides simple methods to process frames and retrieve
landmarks. The original demo behaviour is preserved under the
__main__ guard so the file can still be executed as a script.

Usage from other scripts:
    from hand.hande_t import HandTracker
    tracker = HandTracker(max_num_hands=2)
    success, frame = cap.read()
    results = tracker.process(frame)
    hands = tracker.get_hands_landmarks()
"""


class HandTracker:
    """Wraps MediaPipe Hands for easier reuse.

    Constructor parameters mirror some of MediaPipe's Hands options.

    Methods:
    - process(frame): process a BGR OpenCV frame and return results
    - get_hands_landmarks(): returns list of landmarks per detected hand
    - draw_landmarks(frame): draw landmarks on a frame in-place
    - close(): release any resources (if using an internal VideoCapture)
    """

    def __init__(self, static_image_mode: bool = False, max_num_hands: int = 2,
                 min_detection_confidence: float = 0.5, min_tracking_confidence: float = 0.5):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(static_image_mode=static_image_mode,
                                         max_num_hands=max_num_hands,
                                         min_detection_confidence=min_detection_confidence,
                                         min_tracking_confidence=min_tracking_confidence)
        self.results = None

    def process(self, frame, return_pixel_landmarks: bool = False):
        """Process a BGR OpenCV frame and store results.

        If return_pixel_landmarks is True, also return the same structure as
        get_hands_landmarks() (list of hands -> list of (x,y) tuples) so callers
        can get coordinates in a single call.

        Returns the MediaPipe results object or the pixel landmarks when
        return_pixel_landmarks is True.
        """
        # keep the last frame shape so landmark pixel coordinates can be computed
        self._last_frame_shape = frame.shape
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        self.results = self.hands.process(image_rgb)
        if return_pixel_landmarks:
            return self.get_hands_landmarks()
        return self.results

    def get_hands_landmarks(self) -> Optional[List[List[Tuple[int, int, int]]]]:
        """Return landmarks for each detected hand as list of (id, x, y) pixel tuples.

        Each hand is a list of 21 tuples: (id, cx, cy). Returns None if no hands
        detected.
        """
        if not self.results or not self.results.multi_hand_landmarks:
            return None
        all_hands = []
        for hand_landmarks in self.results.multi_hand_landmarks:
            lm_list = []
            for idx, lm in enumerate(hand_landmarks.landmark):
                # Use the last processed frame shape to convert normalized
                # landmarks to pixel coordinates. If process() wasn't called
                # with a frame first, this will raise an AttributeError.
                h, w, _ = self._last_frame_shape
                cx, cy = int(lm.x * w), int(lm.y * h)
                lm_list.append((idx, cx, cy))
            all_hands.append(lm_list)
        return all_hands

    def get_simple_landmarks(self) -> Optional[List[List[Tuple[int, int, int]]]]:
        """Alias for get_hands_landmarks with the simplified (id, cx, cy) format.

        Kept for callers expecting the 'simple' naming. Returns None if no hands.
        """
        return self.get_hands_landmarks()

    def draw_landmarks(self, frame):
        """Draw detected hand landmarks onto the provided BGR frame in-place.

        Also updates an internal last-frame shape used by get_hands_landmarks.
        """
        self._last_frame_shape = frame.shape
        if not self.results or not self.results.multi_hand_landmarks:
            return
        for hand_landmarks in self.results.multi_hand_landmarks:
            for idx, lm in enumerate(hand_landmarks.landmark):
                h, w, _ = frame.shape
                cx, cy = int(lm.x * w), int(lm.y * h)
                
                cv2.circle(frame, (cx, cy), 9, (25, 255, 255), cv2.FILLED)
            mp.solutions.drawing_utils.draw_landmarks(frame, hand_landmarks, self.mp_hands.HAND_CONNECTIONS)

    def close(self):
        """Close/cleanup resources held by the tracker."""
        if self.hands:
            self.hands.close()


def _demo_camera_loop(source: int = 0):
    """Run the original demo using HandTracker and a webcam.

    Press 'q' to quit.
    """
    cap = cv2.VideoCapture(source)
    tracker = HandTracker()

    pTime = 0
    try:
        while True:
            success, img = cap.read()
            if not success:
                break
            landmarks = tracker.process(img, return_pixel_landmarks=True)
            # print/emit landmarks so the demo demonstrates the API
            if landmarks:
                print(f"Detected {len(landmarks)} hand(s): first hand {landmarks[0][:5]} ...")
            tracker.draw_landmarks(img)

            cTime = time.time()
            fps = 1 / (cTime - pTime) if pTime else 0
            pTime = cTime
            cv2.putText(img, str(int(fps)), (10, 70), cv2.FONT_HERSHEY_PLAIN, 3, (255, 0, 255), 3)

            cv2.imshow("Image", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()
        tracker.close()


if __name__ == "__main__":
    _demo_camera_loop()