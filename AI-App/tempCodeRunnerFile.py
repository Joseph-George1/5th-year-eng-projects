hile True:
			success, img = cap.read()
			if not success:
				break

			landmarks = tracker.process(img, return_pixel_landmarks=True)
			# landmarks is either None or a list of hands -> list of (id,cx,cy)
			vol_percent = None
			if landmarks and len(landmarks) > 0:
				hand0 = landmarks[0]
				# thumb tip is id 4, index tip is id 8