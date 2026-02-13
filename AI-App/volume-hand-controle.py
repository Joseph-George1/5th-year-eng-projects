import cv2
import time
import numpy as np
from hand.hand import HandTracker

# Try to import pycaw for Windows volume control. If not available,
# script will still show the mapped volume on-screen but won't change
# system volume.
try:
	from comtypes import CLSCTX_ALL
	from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
	import ctypes
	PYCAW_AVAILABLE = True
except Exception:
	PYCAW_AVAILABLE = False


def set_system_volume(percent: float):
	"""Set system master volume to percent (0.0-100.0) on Windows using pycaw.

	If pycaw is not available this becomes a no-op.
	"""
	if not PYCAW_AVAILABLE:
		return
	devices = AudioUtilities.GetSpeakers()
	interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
	volume = ctypes.cast(interface, ctypes.POINTER(IAudioEndpointVolume))
	# IAudioEndpointVolume uses a scalar volume in range [0.0, 1.0]
	vol = np.clip(percent / 100.0, 0.0, 1.0)
	volume.SetMasterVolumeLevelScalar(float(vol), None)


def main():
	wCam, hCam = 640, 480

	cap = cv2.VideoCapture(0)
	cap.set(3, wCam)
	cap.set(4, hCam)

	tracker = HandTracker(max_num_hands=1)

	pTime = 0

	try:
		while True:
			success, img = cap.read()
			if not success:
				break

			landmarks = tracker.process(img, return_pixel_landmarks=True)
			# landmarks is either None or a list of hands -> list of (id,cx,cy)
			vol_percent = None
			if landmarks and len(landmarks) > 0:
				hand0 = landmarks[0]
				# thumb tip is id 4, index tip is id 8
				# find their tuples if present
				coords = {lm[0]: (lm[1], lm[2]) for lm in hand0}
				if 4 in coords and 8 in coords:
					x1, y1 = coords[4]
					x2, y2 = coords[8]
					# draw points and a line between
					cv2.circle(img, (x1, y1), 8, (255, 0, 255), cv2.FILLED)
					cv2.circle(img, (x2, y2), 8, (255, 0, 255), cv2.FILLED)
					cv2.line(img, (x1, y1), (x2, y2), (255, 0, 255), 3)

					length = np.hypot(x2 - x1, y2 - y1)
					# map length range to volume percent. Tune these values as needed.
					# When fingers are close (length ~20) -> volume 0
					# When fingers are far (length ~200) -> volume 100
					vol_percent = np.interp(length, [20, 200], [0, 100])
					vol_percent = float(np.clip(vol_percent, 0.0, 100.0))

					# set system volume if available
					set_system_volume(vol_percent)

					# draw volume bar
					cv2.rectangle(img, (50, 150), (85, 400), (0, 0, 0), 2)
					bar = int(np.interp(vol_percent, [0, 100], [400, 150]))
					cv2.rectangle(img, (50, bar), (85, 400), (255, 0, 0), cv2.FILLED)
					cv2.putText(img, f'{int(vol_percent)} %', (40, 430), cv2.FONT_HERSHEY_PLAIN, 2, (255, 0, 0), 2)

			tracker.draw_landmarks(img)

			cTime = time.time()
			fps = 1 / (cTime - pTime) if pTime else 0
			pTime = cTime
			cv2.putText(img, str(int(fps)), (10, 70), cv2.FONT_HERSHEY_PLAIN, 3, (255, 0, 255), 3)

			if not PYCAW_AVAILABLE and vol_percent is not None:
				cv2.putText(img, f'pycaw not installed - Volume {int(vol_percent)}%', (100, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,0,255), 2)

			cv2.imshow("Volume Control", img)

			if cv2.waitKey(1) & 0xFF == ord('q'):
				break
	finally:
		cap.release()
		cv2.destroyAllWindows()
		tracker.close()


if __name__ == '__main__':
	main()