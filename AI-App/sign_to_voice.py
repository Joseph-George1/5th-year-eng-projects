import cv2
import time
import pyttsx3
from hand.hand import HandTracker
import numpy as np
import threading
from collections import deque

"""
Advanced Sign Language to Voice Converter

This system recognizes ASL (American Sign Language) letters, builds words and sentences,
and converts them to speech. It includes:
- ASL alphabet recognition (A-Z)
- Word building with space gesture
- Sentence accumulation
- Automatic speech when signing stops
- Delete gesture for corrections

Controls:
- Show closed fist for 2 seconds: Add SPACE (word separator)
- Show open palm (all fingers up) for 2 seconds: SPEAK accumulated text
- Peace sign (index + middle up): DELETE last character
- No hands detected for 3 seconds: Auto-speak accumulated text
- Press 'q' to quit
- Press 'c' to clear accumulated text
"""


class TextToSpeechEngine:
    """Non-blocking text-to-speech engine"""
    def __init__(self):
        self.engine = pyttsx3.init()
        self.engine.setProperty('rate', 150)  # Speed of speech
        self.engine.setProperty('volume', 0.9)
        self.is_speaking = False
        
    def speak(self, text: str):
        """Speak text in a separate thread to avoid blocking"""
        if text.strip() and not self.is_speaking:
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
    """
    Return finger states for gesture recognition.
    Returns: [thumb_up, index_up, middle_up, ring_up, pinky_up]
    """
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    
    # Fingertip and joint landmarks
    tips = [4, 8, 12, 16, 20]
    pips = [3, 6, 10, 14, 18]
    
    results = []
    
    # Check thumb (horizontal comparison)
    if 4 in coords and 3 in coords:
        thumb_tip_x = coords[4][0]
        thumb_pip_x = coords[3][0]
        # Check if thumb is extended (tip further from palm)
        results.append(abs(thumb_tip_x - coords[0][0]) > abs(thumb_pip_x - coords[0][0]))
    else:
        results.append(False)
    
    # Check other fingers (vertical comparison)
    for i in range(1, 5):
        tip_id = tips[i]
        pip_id = pips[i]
        if tip_id in coords and pip_id in coords:
            tip_y = coords[tip_id][1]
            pip_y = coords[pip_id][1]
            results.append(tip_y < pip_y)  # finger is up if tip is above pip
        else:
            results.append(False)
    
    return results


def get_hand_angles(hand):
    """Calculate angles between fingers for better recognition"""
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    angles = []
    
    # Calculate angle between fingers
    finger_tips = [4, 8, 12, 16, 20]
    for i in range(len(finger_tips) - 1):
        if finger_tips[i] in coords and finger_tips[i+1] in coords and 0 in coords:
            p1 = np.array(coords[finger_tips[i]])
            p2 = np.array(coords[finger_tips[i+1]])
            palm = np.array(coords[0])
            
            v1 = p1 - palm
            v2 = p2 - palm
            
            # Calculate angle
            cos_angle = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2) + 1e-6)
            angle = np.arccos(np.clip(cos_angle, -1.0, 1.0))
            angles.append(np.degrees(angle))
    
    return angles


def recognize_asl_letter(hand):
    """
    Recognize ASL letters from hand landmarks.
    Returns a letter A-Z or special commands.
    """
    if not hand:
        return None
    
    fingers = get_finger_states(hand)
    coords = {lm[0]: (lm[1], lm[2]) for lm in hand}
    
    # Get finger counts
    fingers_up_count = sum(fingers)
    
    # Special gestures
    # SPACE: Closed fist (no fingers up)
    if fingers_up_count == 0:
        return "SPACE"
    
    # SPEAK: Open palm (all 5 fingers up)
    if fingers_up_count == 5 and all(fingers):
        return "SPEAK"
    
    # DELETE: Peace sign (index and middle up only)
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "DELETE"
    
    # Letter recognition based on finger patterns
    
    # A: Fist with thumb to side
    if not any(fingers[1:]) and fingers[0]:
        return "A"
    
    # B: All fingers up, thumb tucked
    if all(fingers[1:]) and not fingers[0]:
        return "B"
    
    # C: Curved hand (approximate)
    if fingers_up_count >= 4:
        angles = get_hand_angles(hand)
        if angles and np.mean(angles) < 45:
            return "C"
    
    # D: Index up, thumb touching middle
    if fingers[1] and not fingers[2] and not fingers[3] and not fingers[4]:
        return "D"
    
    # E: All fingers down (similar to fist)
    if fingers_up_count == 0:
        return "E"
    
    # F: Three fingers up (middle, ring, pinky), index touching thumb
    if not fingers[1] and fingers[2] and fingers[3] and fingers[4]:
        return "F"
    
    # G: Index and thumb horizontal
    if fingers[1] and fingers[0] and not fingers[2] and not fingers[3] and not fingers[4]:
        return "G"
    
    # H: Index and middle extended horizontally
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "H"
    
    # I: Pinky up only
    if fingers[4] and not fingers[1] and not fingers[2] and not fingers[3]:
        return "I"
    
    # L: Thumb and index up (L shape)
    if fingers[0] and fingers[1] and not fingers[2] and not fingers[3] and not fingers[4]:
        return "L"
    
    # O: All fingers forming circle (approximate with all down)
    if fingers_up_count == 0:
        return "O"
    
    # R: Index and middle crossed
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "R"
    
    # U: Index and middle up together
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "U"
    
    # V: Index and middle up separated (peace sign)
    if fingers[1] and fingers[2] and not fingers[3] and not fingers[4]:
        return "V"
    
    # W: Three fingers up (index, middle, ring)
    if fingers[1] and fingers[2] and fingers[3] and not fingers[4]:
        return "W"
    
    # Y: Thumb and pinky out
    if fingers[0] and fingers[4] and not fingers[1] and not fingers[2] and not fingers[3]:
        return "Y"
    
    # Default: Try to map to common patterns
    if fingers_up_count == 1:
        if fingers[1]:
            return "D"
        elif fingers[4]:
            return "I"
    elif fingers_up_count == 2:
        if fingers[1] and fingers[2]:
            return "V"
        elif fingers[0] and fingers[1]:
            return "L"
    elif fingers_up_count == 3:
        if fingers[1] and fingers[2] and fingers[3]:
            return "W"
    
    return None


class SignLanguageProcessor:
    """Process sign language input and build sentences"""
    def __init__(self):
        self.accumulated_text = ""
        self.current_letter = None
        self.letter_hold_time = 0
        self.letter_confirmed = False
        self.last_detection_time = time.time()
        self.no_hand_start_time = None
        
        # Thresholds
        self.hold_duration = 1.5  # seconds to hold a sign to confirm
        self.space_hold_duration = 2.0  # seconds to confirm space
        self.speak_hold_duration = 2.0  # seconds to trigger speak
        self.no_hand_timeout = 3.0  # seconds without hands to auto-speak
        
        # History for smoothing
        self.letter_history = deque(maxlen=10)
        
    def process_detection(self, letter):
        """Process detected letter and update accumulated text"""
        current_time = time.time()
        
        if letter:
            self.last_detection_time = current_time
            self.no_hand_start_time = None
            self.letter_history.append(letter)
            
            # Get most common letter in recent history
            if len(self.letter_history) >= 5:
                most_common = max(set(self.letter_history), key=self.letter_history.count)
                
                # New letter detected
                if most_common != self.current_letter:
                    self.current_letter = most_common
                    self.letter_hold_time = current_time
                    self.letter_confirmed = False
                
                # Letter held long enough
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
                    
                    elif self.current_letter and self.current_letter not in ["SPACE", "SPEAK", "DELETE"] and hold_time >= self.hold_duration:
                        self.accumulated_text += self.current_letter
                        self.letter_confirmed = True
                        return "LETTER_ADDED"
        else:
            # No hand detected
            if self.no_hand_start_time is None:
                self.no_hand_start_time = current_time
            elif current_time - self.no_hand_start_time >= self.no_hand_timeout:
                if self.accumulated_text.strip():
                    return "AUTO_SPEAK"
        
        return None
    
    def get_current_letter(self):
        """Get the currently held letter"""
        return self.current_letter if self.current_letter else ""
    
    def get_hold_progress(self):
        """Get progress of holding current letter (0-1)"""
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
        """Clear accumulated text"""
        self.accumulated_text = ""
        self.current_letter = None
        self.letter_confirmed = False
        self.letter_history.clear()


def main():
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    
    tracker = HandTracker(max_num_hands=1)
    tts_engine = TextToSpeechEngine()
    processor = SignLanguageProcessor()
    
    pTime = 0

    try:
        print("\n" + "="*60)
        print("ADVANCED SIGN LANGUAGE TO VOICE CONVERTER")
        print("="*60)
        print("Controls:")
        print("  - Sign letters (A-Z) and hold for 1.5 seconds")
        print("  - Closed fist (2s) = ADD SPACE")
        print("  - Open palm (2s) = SPEAK accumulated text")
        print("  - Peace sign (1.5s) = DELETE last character")
        print("  - No hands (3s) = Auto-speak")
        print("  - Press 'q' = Quit")
        print("  - Press 'c' = Clear text")
        print("="*60 + "\n")
        
        while True:
            success, img = cap.read()
            if not success:
                break
            
            img = cv2.flip(img, 1)  # Mirror image for natural interaction
            
            # Process hand landmarks
            landmarks = tracker.process(img, return_pixel_landmarks=True)
            
            detected_letter = None
            if landmarks and len(landmarks) > 0:
                hand0 = landmarks[0]
                detected_letter = recognize_asl_letter(hand0)
                tracker.draw_landmarks(img)
            
            # Process detection
            action = processor.process_detection(detected_letter)
            
            # Handle actions
            if action == "SPEAK_NOW" or action == "AUTO_SPEAK":
                text_to_speak = processor.accumulated_text.strip()
                if text_to_speak:
                    tts_engine.speak(text_to_speak)
                    print(f"Speaking: {text_to_speak}")
                    if action == "SPEAK_NOW":
                        processor.clear()
            
            # Draw UI
            h, w = img.shape[:2]
            
            # Semi-transparent overlay for text display
            overlay = img.copy()
            cv2.rectangle(overlay, (10, 10), (w-10, 150), (0, 0, 0), -1)
            cv2.addWeighted(overlay, 0.6, img, 0.4, 0, img)
            
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
                cv2.rectangle(img, (20, 100), (320, 120), (100, 100, 100), -1)
                cv2.rectangle(img, (20, 100), (20 + bar_width, 120), color, -1)
                cv2.putText(img, f"{int(progress*100)}%", (330, 115), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            
            # FPS counter
            cTime = time.time()
            fps = 1 / (cTime - pTime) if pTime else 0
            pTime = cTime
            cv2.putText(img, f"FPS: {int(fps)}", (w-150, 40), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            
            # Instructions
            cv2.putText(img, "Press 'q' to quit, 'c' to clear", (20, h-20), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1)
            
            cv2.imshow("Sign Language to Voice", img)
            
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('c'):
                processor.clear()
                print("Text cleared")
                
    finally:
        cap.release()
        cv2.destroyAllWindows()
        tracker.close()
        print("\nApplication closed")


if __name__ == '__main__':
    main()
