(defpackage #:squirl-demo-2
  (:use :cl :squirl))
(in-package :squirl-demo-2)

(defparameter *world-x-offset* 0)
(defparameter *world-y-offset* 0)
(defparameter *body-radius* 1) ;;for visualisation

(defun world-box (a1 b1 a2 b2 a3 b3 a4 b4 space static-body)
  (let ((shape (make-segment static-body a1 b1 1.0)))
    (setf (shape-elasticity shape) 1.0)
    (setf (shape-friction shape) 1.0)

    (world-add-static-shape space shape)

    (setf shape (make-segment static-body a2 b2 1.0))
    (setf (shape-elasticity shape) 1.0)
    (setf (shape-friction shape) 1.0)
    (world-add-static-shape space shape)

    (setf shape ( make-segment static-body a3 b3 1.0))
    (setf (shape-elasticity shape) 1.0)
    (setf (shape-friction shape) 1.0)
    (world-add-static-shape space shape)

    (setf shape (make-segment static-body a4 b4 1.0))
    (setf (shape-elasticity shape) 1.0)
    (setf (shape-friction shape) 1.0)
    (world-add-static-shape space shape)))

(defun init-world ()
  (reset-shape-id-counter)
  (let* ((static-body (make-body most-positive-short-float most-positive-short-float 0 0))
	 (world (make-world :iterations 10))
	 (body (make-body 100.0 10000.0 0 1 1))
	 (shape (make-segment body (vec -75 0) (vec 75 0) 5)))
    (world-box (vec -320 -240) (vec -320 240) (vec 320 -240) (vec 320 240)
	       (vec -320 -240) (vec 320 -240)
	       (vec -320 240) (vec 320 240)
	       world static-body)
    (world-add-body world body)
    (setf (shape-elasticity shape) 1.0)
    (setf (shape-friction shape) 1.0)
    (world-add-shape world shape)
    (world-add-constraint world (make-pivot-joint body static-body (vec 0 0) (vec 0 0)))
    (return-from init-world world)))

(defun update (ticks world)
  (let* ((steps 3)
         (dt (/ 1.0 60.0 steps)))
    (dotimes (count steps)
      (world-step world dt))))

(defun add-circle (world)
  (let* ((size 10.0)
	 (mass 1.0)
	 (radius (vec-length (vec size size))))
    (let ((body (make-body mass (moment-for-circle mass 1.0 size) 0 0)))
      (setf (body-position body) (vec (- (* (/ 1.0 (+ (random 10) 1)) (- 640 (* 2 radius))) (- 320 radius)) (- (* (/ 1.0 (+ (random 10)1)) (- 400 (* 2 radius))) (- 240 radius))))
      (setf (body-velocity body) (vec* (vec (- (* 2 (/ 1.0 (+ 1 (random 10)))) 1) (- (* 2 (/ 1.0 (+ (random 10) 1))) 1)) 200))
      (world-add-body world body)
      (let ((shape (make-circle body size)))
	(setf (shape-elasticity shape) 1.0)
	(setf (shape-friction shape) 1.0)
	(world-add-shape world shape)))))

(defun add-box (world)
  (let* ((size 10.0)
	(mass 1.0)
	(verts (make-array 4))
	(radius (vec-length (vec size size))))
    (setf (elt verts 0) (vec (- size) (- size)))
    (setf (elt verts 1) (vec (- size) size))
    (setf (elt verts 2) (vec size size))
    (setf (elt verts 3) (vec size (- size)))
    (let ((body (make-body mass (moment-for-poly mass 4 verts) 0 0)))
      (setf (body-position body) (vec (- (* (/ 1.0 (+ (random 10) 1)) (- 640 (* 2 radius))) (- 320 radius)) (- (* (/ 1.0 (+ (random 10)1)) (- 400 (* 2 radius))) (- 240 radius))))
      (setf (body-velocity body) (vec* (vec (- (* 2 (/ 1.0 (+ 1 (random 10)))) 1) (- (* 2 (/ 1.0 (+ (random 10) 1))) 1)) 200))
      (world-add-body world body)
      (let ((shape (make-poly body verts)))
	(setf (shape-elasticity shape) 1.0)
	(setf (shape-friction shape) 1.0)
	(world-add-shape world shape)))))

(defgeneric draw-shape (shape color))

(defun body-with-color (color)
  (lambda (element)
    (draw-body element color)))

(defun draw-body (body color)
  (let ((x (round (vec-x (body-position body))))
	(y (round (vec-y (body-position body)))))
    (sdl:draw-filled-circle-* (+ x *world-x-offset*) (+ y *world-y-offset*) *body-radius* :color color)))

(defun shape-with-color (color)
  (lambda (element)
    (draw-shape element color)))

(defmethod draw-shape ((shape circle) color)
  (let ((x (round (vec-x (circle-transformed-center shape))))
	(y (round (vec-y (circle-transformed-center shape)))))
    (sdl:draw-circle-* (+ x *world-x-offset*) (+ y *world-y-offset*) (round (circle-radius shape)) :color color)))

(defmethod draw-shape ((shape poly) color)
  (let ((1st-vert-x (round (vec-x (elt (poly-transformed-vertices shape) 0))))
	(1st-vert-y (round (vec-y (elt (poly-transformed-vertices shape) 0)))))
    (do ((vert1-x 0) (vert1-y 0) (vert2-x 0) (vert2-y 0)
	 (index 1 (1+ index)))
	((= index (length (poly-transformed-vertices shape)))
	   (sdl:draw-line-* (+ vert2-x *world-x-offset*) (+ vert2-y *world-y-offset*) (+ 1st-vert-x *world-x-offset*) (+ 1st-vert-y *world-y-offset*) :color color))
      (setf vert1-x (round (vec-x (elt (poly-transformed-vertices shape) (1- index)))))
      (setf vert1-y (round (vec-y (elt (poly-transformed-vertices shape) (1- index)))))
      (setf vert2-x (round (vec-x (elt (poly-transformed-vertices shape) index))))
      (setf vert2-y (round (vec-y (elt (poly-transformed-vertices shape) index))))
      (sdl:draw-line-*  (+ vert1-x *world-x-offset*) (+ vert1-y *world-y-offset*)
			(+ vert2-x *world-x-offset*) (+ vert2-y *world-y-offset*)
			:color color))))

(defmethod draw-shape ((seg segment) color)
  (let ((x1 (round (vec-x (segment-trans-a seg))))
	(y1 (round (vec-y (segment-trans-a seg))))
	(x2 (round (vec-x (segment-trans-b seg))))
	(y2 (round (vec-y (segment-trans-b seg)))))
  (sdl:draw-line-* (+ x1 *world-x-offset*)  (+ y1 *world-y-offset*) (+ x2 *world-x-offset*) (+ y2 *world-y-offset*) :color color)))

(defun render (world)
  (sdl:clear-display sdl:*black*)
  (map-world-hash (shape-with-color sdl:*green*) (world-active-shapes world))
  (map-world-hash (shape-with-color sdl:*red*) (world-static-shapes world))
  (map 'vector (body-with-color sdl:*blue*) (world-bodies world))
  (sdl:update-display))

(defun quick-and-dirty ()
  (sdl:with-init ()
    (sdl:window 800 600 :title-caption "SqirL SDL Demo" :icon-caption "SquirL")
    (setf *world-x-offset* (/ 800 2))
    (setf *world-y-offset* (/ 600 2))
    (let ((world (init-world))
          (previous-tick (sdl:sdl-get-ticks)))
      (add-box world)
      (sdl:with-events ()
	(:idle ()
          (let ((now (sdl:sdl-get-ticks)))
            (update (- now previous-tick) world)
            (setf previous-tick now))
          (render world))
	(:quit-event () t)
	(:video-expose-event ()
          (sdl:update-display))
	(:key-down-event ()
          (when (sdl:key-down-p :sdl-key-escape)
            (sdl:push-quit-event))
          (when (sdl:key-down-p :sdl-key-b)
            (add-box world))
          (when (sdl:key-down-p :sdl-key-c)
            (add-circle world)))))))
