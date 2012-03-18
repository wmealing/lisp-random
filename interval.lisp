;;;; interval arithmetic
;;;; Copyright (c) 2012 Robert Smith

(defstruct (interval (:conc-name)
                     (:constructor interval (left right))
                     (:print-function interval-printer))
  left
  right)

(defun interval-printer (x stream depth)
  (declare (ignore depth))
  (format stream "[~A, ~A]" (left x) (right x)))

(defmacro with-iv (iv (a b) &body body)
  "Destructuring mechanism for intervals."
  (let ((iv-once (gensym)))
    `(let ((,iv-once ,iv))
       (let ((,a (left ,iv-once))
             (,b (right ,iv-once)))
         ,@body))))

(defconstant +unit-interval+ (interval 0 1))

(defun zero-in (iv)
  "Is zero in IV?"
  (<= (left iv) 0 (right iv)))

(defun number-to-interval (n)
  (assert (rationalp n))
  (interval n n))

(defmacro define-binary-interval-function (fn-name regular-fn)
  `(defun ,fn-name (x y)
     (with-iv x (a b)
       (with-iv y (c d)
         (let ((a@c (funcall ,regular-fn a c))
               (a@d (funcall ,regular-fn a d))
               (b@c (funcall ,regular-fn b c))
               (b@d (funcall ,regular-fn b d)))
           (interval (min a@c a@d b@c b@d)
                     (max a@c a@d b@c b@d)))))))

(define-binary-interval-function iv+ '+)
(define-binary-interval-function iv- '-)
(define-binary-interval-function iv* '*)

;;; We need to specially handle division by zero.
(defun iv/ (x y)
  (if (zero-in y)
      (error (make-condition 'division-by-zero :operation 'iv/
                                               :operands (list x y)))
      (with-iv x (a b)
        (with-iv y (c d)
          (let ((a/c (/ a c))
                (a/d (/ a d))
                (b/c (/ b c))
                (b/d (/ b d)))
            (interval (min a/c a/d b/c b/d)
                      (max a/c a/d b/c b/d)))))))

;;; Only works for integral powers, for now...
(defun iv-pow (x n)
  (assert (and (integerp n)
               (plusp n)))
  (with-iv x (a b)
    (cond
      ((oddp n) (interval (expt a n) (expt b n)))
      ((evenp n) (cond
                   ((>= a 0) (interval (expt a n) (expt b n)))
                   ((minusp b) (interval (expt b n) (expt a n)))
                   (t (interval 0 (max (expt a n) (expt b n)))))))))