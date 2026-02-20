"""
Sign Language to Voice - Local Version

Optimized for local Windows/Mac/Linux execution.
Requirements:
    pip install opencv-python mediapipe pyttsx3

Usage:
    1. Run the script
    2. Allow webcam access
    3. Make ASL signs in front of the camera
    4. Hold gestures for 1.5 seconds to register
    5. Press 'q' to quit
"""

import cv2
import time
import numpy as np
from collections import deque
import mediapipe as mp
from typing import List, Tuple, Optional
import pyttsx3
import threading


class HandTracker:
    """MediaPipe hand tracking wrapper"""
    
    def __init__(self, static_image_mode: bool = False, max_num_hands: int = 2,
                 min_detection_confidence: float = 0.3, min_tracking_confidence: float = 0.3):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=static_image_mode,
            max_num_hands=max_num_hands,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence
        )
        self.mp_drawing = mp.solutions.drawing_utils
        self.results = None

    def process(self, frame, return_pixel_landmarks: bool = False):
        """Process BGR frame and return landmarks"""
        self._last_frame_shape = frame.shape
        
        # Enhance image for better detection
        enhanced = cv2.convertScaleAbs(frame, alpha=1.1, beta=10)
        
        image_rgb = cv2.cvtColor(enhanced, cv2.COLOR_BGR2RGB)
        self.results = self.hands.process(image_rgb)
        if return_pixel_landmarks:
            return self.get_hands_landmarks()
        return self.results

    def get_hands_landmarks(self) -> Optional[List[List[Tuple[int, int, int]]]]:
        """Return landmarks as list of (id, x, y) tuples"""
        if not self.results or not self.results.multi_hand_landmarks:
            return None
        all_hands = []
        for hand_landmarks in self.results.multi_hand_landmarks:
            lm_list = []
            for idx, lm in enumerate(hand_landmarks.landmark):
                h, w, _ = self._last_frame_shape
                cx, cy = int(lm.x * w), int(lm.y * h)
                lm_list.append((idx, cx, cy))
            all_hands.append(lm_list)
        return all_hands

    def draw_landmarks(self, frame):
        """Draw hand landmarks on frame"""
        if not self.results or not self.results.multi_hand_landmarks:
            return
        for hand_landmarks in self.results.multi_hand_landmarks:
            self.mp_drawing.draw_landmarks(
                frame, hand_landmarks, self.mp_hands.HAND_CONNECTIONS
            )

    def close(self):
        """Cleanup resources"""
        if self.hands:
            self.hands.close()


class TextToSpeechEngine:
    """Non-blocking text-to-speech engine using pyttsx3"""
    
    def __init__(self):
        self.is_speaking = False
        try:
            self.engine = pyttsx3.init()
            self.engine.setProperty('rate', 150)
            self.engine.setProperty('volume', 0.9)
        except:
            print("Warning: pyttsx3 not available. Speech disabled.")
            self.engine = None
        
    def speak(self, text: str):
        """Speak text in a separate thread to avoid blocking"""
        if text.strip() and not self.is_speaking and self.engine:
            self.is_speaking = True
            thread = threading.Thread(target=self._speak_thread, args=(text,))
            thread.daemon = True
            thread.start()
    
    def _speak_thread(self, text):
        """Internal method to speak in thread"""
        try:
            engine = pyttsx3.init()
            engine.setProperty('rate', 150)
            engine.say(text)
            engine.runAndWait()
        except Exception as e:
            print(f"Speech error: {e}")
        finally:
            self.is_speaking = False


def get_finger_states(hand):
    """Return finger states: [thumb, index, middle, ring, pinky]"""
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    tips = [4, 8, 12, 16, 20]
    pips = [3, 6, 10, 14, 18]
    results = []
    
    # Thumb
    if 4 in coords and 3 in coords:
        thumb_tip_x = coords[4][0]
        thumb_pip_x = coords[3][0]
        results.append(abs(thumb_tip_x - coords[0][0]) > abs(thumb_pip_x - coords[0][0]))
    else:
        results.append(False)
    
    # Other fingers
    for i in range(1, 5):
        tip_id, pip_id = tips[i], pips[i]
        if tip_id in coords and pip_id in coords:
            results.append(coords[tip_id][1] < coords[pip_id][1])
        else:
            results.append(False)
    
    return results


def recognize_asl_letter(hand):
    """Recognize ASL letter from hand landmarks"""
    if not hand:
        return None
    
    fingers = get_finger_states(hand)
    fingers_up = sum(fingers)
    
    # Special gestures
    if fingers_up == 0:
        return "SPACE"
    if fingers_up == 5 and all(fingers):
        return "SPEAK"
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "DELETE"
    
    # Letters
    if not any(fingers[1:]) and fingers[0]:
        return "A"
    if all(fingers[1:]) and not fingers[0]:
        return "B"
    if fingers[1] and not fingers[2] and not fingers[3] and not fingers[4]:
        return "D"
    if fingers[4] and not fingers[1] and not fingers[2] and not fingers[3]:
        return "I"
    if fingers[0] and fingers[1] and not fingers[2] and not fingers[3] and not fingers[4]:
        return "L"
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "V"
    if fingers[1] and fingers[2] and fingers[3] and not fingers[4]:
        return "W"
    if fingers[0] and fingers[4] and not fingers[1] and not fingers[2] and not fingers[3]:
        return "Y"
    
    return None


class SignLanguageProcessor:
    """Process sign language and build text"""
    
    def __init__(self):
        self.accumulated_text = ""
        self.current_letter = None
        self.letter_hold_time = 0
        self.letter_confirmed = False
        self.letter_history = deque(maxlen=10)
        self.hold_duration = 1.2
        self.space_hold_duration = 1.8
        self.speak_hold_duration = 1.8
        
    def process_detection(self, letter):
        """Process detected letter"""
        current_time = time.time()
        
        if letter:
            self.letter_history.append(letter)
            
            if len(self.letter_history) >= 5:
                most_common = max(set(self.letter_history), key=self.letter_history.count)
                
                if most_common != self.current_letter:
                    self.current_letter = most_common
                    self.letter_hold_time = current_time
                    self.letter_confirmed = False
                
                elif not self.letter_confirmed:
                    hold_time = current_time - self.letter_hold_time
                    
                    if self.current_letter == "SPACE" and hold_time >= self.space_hold_duration:
                        if self.accumulated_text and not self.accumulated_text.endswith(" "):
                            self.accumulated_text += " "
                        self.letter_confirmed = True
                        return "SPACE_ADDED"
                    
                    elif self.current_letter == "SPEAK" and hold_time >= self.speak_hold_duration:
                        self.letter_confirmed = True
                        return "SPEAK_NOW"
                    
                    elif self.current_letter == "DELETE" and hold_time >= self.hold_duration:
                        if self.accumulated_text:
                            self.accumulated_text = self.accumulated_text[:-1]
                        self.letter_confirmed = True
                        return "DELETED"
                    
                    elif self.current_letter not in ["SPACE", "SPEAK", "DELETE"] and hold_time >= self.hold_duration:
                        self.accumulated_text += self.current_letter
                        self.letter_confirmed = True
                        return "LETTER_ADDED"
        
        return None
    
    def get_current_letter(self):
        return self.current_letter if self.current_letter else ""
    
    def get_hold_progress(self):
        if not self.current_letter or self.letter_confirmed:
            return 0
        hold_time = time.time() - self.letter_hold_time
        threshold = self.hold_duration
        if self.current_letter == "SPACE":
            threshold = self.space_hold_duration
        elif self.current_letter == "SPEAK":
            threshold = self.speak_hold_duration
        return min(hold_time / threshold, 1.0)
    
    def clear(self):
        self.accumulated_text = ""
        self.current_letter = None
        self.letter_confirmed = False
        self.letter_history.clear()


def run_sign_language_local():
    """Run sign language recognition using local webcam"""
    
    print("="*60)
    print("SIGN LANGUAGE TO VOICE - LOCAL VERSION")
    print("="*60)
    print("\nControls:")
    print("  - Hold ASL letters for 1.2 seconds")
    print("  - Closed fist (1.8s) = ADD SPACE")
    print("  - Open palm (1.8s) = SPEAK text")
    print("  - Peace sign (1.2s) = DELETE last character")
    print("  - Press 'q' to quit")
    print("  - Press 'c' to clear text")
    print("="*60 + "\n")
    
    # Initialize webcam
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 960)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 540)
    cap.set(cv2.CAP_PROP_FPS, 30)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    
    if not cap.isOpened():
        print("❌ Cannot access webcam!")
        return
    
    # Initialize components
    tracker = HandTracker(max_num_hands=1)
    processor = SignLanguageProcessor()
    tts_engine = TextToSpeechEngine()
    
    print("✅ Webcam initialized")
    print("📷 Starting sign language recognition...\n")
    
    frame_count = 0
    hand_detect_count = 0
    pTime = 0
    
    try:
        while True:
            success, img = cap.read()
            if not success:
                print("Failed to read frame")
                break
            
            frame_count += 1
            img = cv2.flip(img, 1)  # Mirror for natural interaction
            
            # Process hand landmarks
            landmarks = tracker.process(img, return_pixel_landmarks=True)
            
            detected_letter = None
            if landmarks and len(landmarks) > 0:
                hand_detect_count += 1
                hand0 = landmarks[0]
                detected_letter = recognize_asl_letter(hand0)
                tracker.draw_landmarks(img)
            
            # Process detection
            action = processor.process_detection(detected_letter)
            
            # Handle actions
            if action == "SPEAK_NOW":
                text_to_speak = processor.accumulated_text.strip()
                if text_to_speak:
                    print(f"🔊 Speaking: {text_to_speak}")
                    tts_engine.speak(text_to_speak)
                    processor.clear()
            elif action in ["LETTER_ADDED", "SPACE_ADDED", "DELETED"]:
                print(f"✓ {action}: '{processor.accumulated_text}'")
            
            # Draw UI
            h, w = img.shape[:2]
            
            # Semi-transparent overlay
            overlay = img.copy()
            cv2.rectangle(overlay, (10, 10), (w-10, 180), (0, 0, 0), -1)
            cv2.addWeighted(overlay, 0.5, img, 0.5, 0, img)
            
            # Hand detection status
            if landmarks and len(landmarks) > 0:
                status_text = "✓ HAND DETECTED"
                status_color = (0, 255, 0)
                cv2.circle(img, (w-50, 40), 15, (0, 255, 0), -1)
            else:
                status_text = "✗ NO HAND"
                status_color = (0, 0, 255)
                cv2.circle(img, (w-50, 40), 15, (0, 0, 255), -1)
            
            cv2.putText(img, status_text, (w-200, 45), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, status_color, 2)
            
            # Display accumulated text
            text_display = processor.accumulated_text if processor.accumulated_text else "[Empty]"
            cv2.putText(img, f"Text: {text_display}", (20, 40), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            
            # Display current letter being held
            current_letter = processor.get_current_letter()
            progress = processor.get_hold_progress()
            if current_letter:
                color = (0, 255, 0) if progress >= 1.0 else (0, 255, 255)
                cv2.putText(img, f"Detecting: {current_letter}", (20, 80), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
                
                # Progress bar
                bar_width = int(300 * progress)
                cv2.rectangle(img, (20, 100), (320, 120), (50, 50, 50), -1)
                cv2.rectangle(img, (20, 100), (20 + bar_width, 120), color, -1)
                cv2.putText(img, f"{int(progress*100)}%", (330, 115), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                
                # Status text
                if progress >= 1.0:
                    cv2.putText(img, "✓ CONFIRMED", (20, 145), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                else:
                    cv2.putText(img, "⏳ HOLD...", (20, 145), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
            
            # FPS counter
            cTime = time.time()
            fps = 1 / (cTime - pTime) if pTime else 0
            pTime = cTime
            cv2.putText(img, f"FPS: {int(fps)}", (20, h-60), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
            
            # Statistics
            detection_rate = int(hand_detect_count/frame_count*100) if frame_count > 0 else 0
            cv2.putText(img, f"Frames: {frame_count} | Detection: {detection_rate}%", (20, h-30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)
            
            # Instructions
            cv2.putText(img, "Press 'q' to quit | 'c' to clear", (20, h-5), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (150, 150, 150), 1)
            
            cv2.imshow("Sign Language to Voice", img)
            
            key = cv2.waitKey(5) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('c'):
                processor.clear()
                print("Text cleared")
                
    except KeyboardInterrupt:
        print("\n⚠️ Interrupted by user")
    finally:
        cap.release()
        cv2.destroyAllWindows()
        tracker.close()
        
        print("\n" + "="*60)
        print("✅ SESSION COMPLETE!")
        print("="*60)
        print(f"📊 Statistics:")
        print(f"   Total frames: {frame_count}")
        print(f"   Hands detected: {hand_detect_count} frames ({int(hand_detect_count/max(frame_count,1)*100)}%)")
        print(f"   Final text: '{processor.accumulated_text}'")
        print("="*60)


if __name__ == "__main__":
    run_sign_language_local()
