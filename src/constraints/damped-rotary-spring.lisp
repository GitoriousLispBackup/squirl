;;;; -*- Mode: Lisp; indent-tabs-mode: nil -*-
(in-package :squirl)

(defstruct (damped-rotary-spring
             (:include spring)
             (:constructor make-damped-rotary-spring
                           (body-a body-b rest-angle stiffness damping)))
  rest-angle damping target-wrn i-sum)

(defmethod spring-torque ((spring damped-rotary-spring) relative-angle)
  (* (- relative-angle (damped-rotary-spring-rest-angle spring))
     (damped-rotary-spring-stiffness spring)))

(defmethod pre-step ((spring damped-rotary-spring) dt dt-inverse)
  (declare (ignore dt-inverse))
  (let ((body-a (constraint-body-a spring))
        (body-b (constraint-body-b spring)))
    (setf (damped-rotary-spring-i-sum spring) (/ (+ (body-inverse-inertia body-a)
                                                    (body-inverse-inertia body-b)))
          (damped-rotary-spring-dt spring) dt
          (damped-rotary-spring-target-wrn spring) 0d0)

    ;; Applying spring torque
    (let ((j-spring (* dt (spring-torque spring (- (body-angle body-a) (body-angle body-b))))))
      (decf (body-angular-velocity body-a) (* j-spring (body-inverse-inertia body-a)))
      (incf (body-angular-velocity body-b) (* j-spring (body-inverse-inertia body-b)))))
  (values))

(defmethod apply-impulse ((spring damped-rotary-spring))
  (let* ((body-a (constraint-body-a spring))
         (body-b (constraint-body-b spring))
         (wrn (- (body-angular-velocity body-a)
                 (body-angular-velocity body-b)))
         (angular-velocity-damp
          (* wrn (- 1d0 (exp (- (/ (* (damped-rotary-spring-damping spring)
                                      (damped-rotary-spring-dt spring))
                                   (damped-rotary-spring-i-sum spring))))))))
    (setf (damped-rotary-spring-target-wrn spring) (- wrn angular-velocity-damp))
    (let ((j-damp (* angular-velocity-damp (damped-rotary-spring-i-sum spring))))
      (decf (body-angular-velocity body-a) (* j-damp (body-inverse-inertia body-a)))
      (incf (body-angular-velocity body-b) (* j-damp (body-inverse-inertia body-b)))))
  (values))
