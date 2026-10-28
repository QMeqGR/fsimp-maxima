;; Maxima's own size measure of the internal list, under an fs_ name so the
;; package adds no generic name to the user's session.
(defmfun $fs_conssize (e) (conssize e))

;; Characters that names chosen by the user add to string(e) beyond one
;; per occurrence. These are variables, as listofvars returns them
;; (including subscripted ones such as c[1]), and calls to functions
;; Maxima has no simplifier for, such as an undefined f(x) or 'f(x). Each
;; occurrence prints once in string(e), so subtracting this from the
;; string length counts every such name as one character, whatever it is
;; called. Used by fssize.
(defun fs-user-function-op-p (x)
  (let ((o (caar x)))
    (and (symbolp o)
         (not (get o 'operators))
         (not (member 'array (car x)))
         (member (char (symbol-name o) 0) '(#\$ #\%)))))

(defmfun $fs_name_excess (e)
  (let ((vars (cdr ($listofvars e)))
        (total 0))
    (labels ((walk (x)
               (cond ((member x vars :test #'alike1)
                      (incf total (1- (length (mstring x)))))
                     ((atom x) nil)
                     ((eq (caar x) 'mrat) nil)
                     (t (when (fs-user-function-op-p x)
                          (incf total (1- (length (mstring (caar x))))))
                        (mapc #'walk (cdr x))))))
      (walk e))
    total))

;; List the user-level functions applied in E as [name, arity] pairs, in
;; order of first appearance. These are the functions fs_name_excess
;; counts: calls such as f(x) or 'f(x) to a function Maxima has no
;; simplifier for. Built-in functions and subscripted variables such as
;; c[1] are left out. Used by fscheck.mac to find functions that have no
;; numeric definition.
(defmfun $fs_function_ops (e)
  (let ((acc nil))
    (labels ((walk (x)
               (unless (or (atom x) (eq (caar x) 'mrat))
                 (let ((o (caar x)))
                   (when (fs-user-function-op-p x)
                     (pushnew (list o (length (cdr x))) acc :test #'equal)))
                 (mapc #'walk (cdr x)))))
      (walk e))
    (cons '(mlist)
          (mapcar #'(lambda (p) (list '(mlist) (first p) (second p)))
                  (reverse acc)))))

;; Deterministic hash of a symbol's name, used to give each unknown
;; function its own stand-in in fscheck.mac.
(defmfun $fs_name_hash (s)
  (let ((h 0))
    (loop for c across (symbol-name s)
          for i from 1
          do (incf h (* i (char-code c))))
    h))

;;; Test point kinds for fscheck.mac.

;; OA(16,5,4,2) over GF(4): any two columns contain every pair of symbols
;; 0..3 exactly once.
(defparameter *fs-oa16*
  #2A((0 0 0 0 0) (0 1 1 1 1) (0 2 2 2 2) (0 3 3 3 3)
      (1 0 1 2 3) (1 1 0 3 2) (1 2 3 0 1) (1 3 2 1 0)
      (2 0 2 3 1) (2 1 3 2 0) (2 2 0 1 3) (2 3 1 0 2)
      (3 0 3 1 2) (3 1 2 0 3) (3 2 1 3 0) (3 3 0 2 1)))

;; 16 rows of N kind indices 0..3 such that every pair of columns shows as
;; many of the 16 kind pairs as possible. Up to 5 columns come from the
;; orthogonal array and cover all pairs. Further columns are filled one at
;; a time: each row takes the kind that covers the most pairs not yet seen
;; against earlier columns, ties going to the first kind in a rotation by
;; row and column.
(defmfun $fs_kind_rows (n)
  (let ((rows (make-array (list 16 n) :initial-element 0))
        (covered (make-array (list n n) :initial-element 0)))
    (flet ((mark (r j)
             (dotimes (i j)
               (setf (aref covered i j)
                     (logior (aref covered i j)
                             (ash 1 (+ (* 4 (aref rows r i)) (aref rows r j))))))))
      (dotimes (j n)
        (dotimes (r 16)
          (if (< j 5)
              (setf (aref rows r j) (aref *fs-oa16* r j))
              (let ((best -1) (bestk 0))
                (dotimes (k 4)
                  (let ((kk (mod (+ k r j) 4)) (gain 0))
                    (dotimes (i j)
                      (unless (logbitp (+ (* 4 (aref rows r i)) kk) (aref covered i j))
                        (incf gain)))
                    (when (> gain best) (setf best gain bestk kk))))
                (setf (aref rows r j) bestk)))
          (mark r j))))
    (cons '(mlist)
          (loop for r below 16
                collect (cons '(mlist) (loop for j below n collect (aref rows r j)))))))

;; Operators whose principal branch has a cut. Variables inside them are
;; the ones whose joint kinds matter, see fscheck.mac.
(defparameter *fs-branch-ops*
  '(%log %asin %acos %atan %acot %asec %acsc %asinh %acosh %atanh %acoth
    %asech %acsch %atan2 %lambert_w))

;; Variables of E that appear inside an operator with a branch cut, or in a
;; power whose exponent is not an integer.
(defmfun $fs_branch_vars (e)
  (let ((acc nil))
    (labels ((walk (x)
               (unless (or (atom x) (eq (caar x) 'mrat))
                 (if (or (member (caar x) *fs-branch-ops*)
                         (and (eq (caar x) 'mexpt)
                              (not (eq (second x) '$%e))
                              (not (integerp (third x)))))
                     (dolist (v (cdr ($listofvars x)))
                       (pushnew v acc :test #'alike1))
                     (mapc #'walk (cdr x))))))
      (walk e))
    (cons '(mlist) (reverse acc))))

;;; Numeric evaluator for fscheck.mac. It works bottom-up with Common Lisp
;;; numbers, so every function receives a number and returns its principal
;;; value. Integer and rational arithmetic stays exact until a float or a
;;; transcendental function enters. Operators it does not know natively go
;;; through Maxima with numeric arguments. Failure of any kind gives NIL.

(defun fs-dbl (z)
  (if (complexp z)
      (complex (float (realpart z) 1d0) (float (imagpart z) 1d0))
      (float z 1d0)))

;; A complex value with zero imaginary part becomes real, so the sign of
;; that zero cannot select a side of a branch cut.
(defun fs-norm (z)
  (if (and (complexp z) (zerop (imagpart z))) (realpart z) z))

(defun fs-finite-p (z)
  (flet ((ok (x) (or (rationalp x)
                     (and (= x x) (< (cl:abs x) most-positive-double-float)))))
    (if (complexp z) (and (ok (realpart z)) (ok (imagpart z))) (ok z))))

(defun fs-to-maxima (z)
  (if (complexp z)
      (add (realpart z) (mul (imagpart z) '$%i))
      z))

(defun fs-from-maxima (r)
  (cond ((numberp r) r)
        ((and (consp r) (eq (caar r) 'rat)) (/ (second r) (third r)))
        (t (let ((re ($realpart r)) (im ($imagpart r)))
             (if (and (numberp re) (numberp im))
                 (fs-norm (complex re im))
                 (error "not numeric"))))))

;; Evaluate operator OP on numeric arguments ARGS through Maxima.
(defun fs-eval-maxima (op args)
  (fs-from-maxima
   ($rectform ($float (simplify (cons (list op) (mapcar #'fs-to-maxima args)))))))

(defun fs-power (b w)
  (cond ((integerp w) (cl:expt b w))
        ;; Maxima takes real roots of negative reals: (-8)^(1/3) is -2 and
        ;; (-3)^(2/3) is 3^(2/3). Following the principal branch here would
        ;; accept rewrites such as %e^(log(x)/3) to x^(1/3), which Maxima
        ;; evaluates differently for negative x.
        ((and (typep w 'ratio) (oddp (denominator w)) (realp b) (minusp b))
         (* (if (oddp (numerator w)) -1 1) (cl:expt (fs-dbl (- b)) (fs-dbl w))))
        ((eql b 0) (if (plusp (realpart w)) 0 (error "0 to a non-positive power")))
        (t (cl:expt (fs-dbl b) (fs-dbl w)))))

(defun fs-eval (e env)
  (fs-norm
   (cond ((numberp e) e)
         ((symbolp e)
          (case e
            ($%pi (float cl:pi 1d0))
            ($%e (cl:exp 1d0))
            ($%i #c(0 1))
            (t (let ((b (assoc e env)))
                 (if b (cdr b) (fs-from-maxima ($float e)))))))
         ((eq (caar e) 'rat) (/ (second e) (third e)))
         ((eq (caar e) 'bigfloat) (fs-from-maxima ($float e)))
         ;; a subscripted variable such as c[1]
         ((member 'array (cdar e))
          (let ((b (assoc e env :test #'alike1)))
            (if b (cdr b) (error "unbound subscripted variable"))))
         ((eq (caar e) 'mexpt)
          (if (eq (second e) '$%e)
              (cl:exp (fs-dbl (fs-eval (third e) env)))
              (fs-power (fs-eval (second e) env) (fs-eval (third e) env))))
         (t
          (let ((op (caar e))
                (args (mapcar #'(lambda (a) (fs-eval a env)) (cdr e))))
            (flet ((f1 (fn) (funcall fn (fs-dbl (first args)))))
              (case op
                (mplus (reduce #'+ args))
                (mtimes (reduce #'* args))
                (mminus (- (first args)))
                (mquotient (/ (first args) (second args)))
                (mabs (cl:abs (first args)))
                (%sin (f1 #'cl:sin)) (%cos (f1 #'cl:cos)) (%tan (f1 #'cl:tan))
                (%sec (/ (f1 #'cl:cos))) (%csc (/ (f1 #'cl:sin))) (%cot (/ (f1 #'cl:tan)))
                (%sinh (f1 #'cl:sinh)) (%cosh (f1 #'cl:cosh)) (%tanh (f1 #'cl:tanh))
                (%sech (/ (f1 #'cl:cosh))) (%csch (/ (f1 #'cl:sinh))) (%coth (/ (f1 #'cl:tanh)))
                (%log (f1 #'cl:log))
                (%atan (if (realp (first args)) (f1 #'cl:atan) (fs-eval-maxima op args)))
                (t (fs-eval-maxima op args)))))))))

;; Value of E at assignment A, a Maxima list of equations var = number, as
;; [realpart, imagpart] in double floats, or false.
(defmfun $fs_num_value (e a)
  ;; errormsg off: an unevaluable point, such as an unevaluated integral at
  ;; numeric arguments, is expected, and Maxima would print its error
  ;; message before handler-case sees the error.
  (let ((v (let (($errormsg nil))
             (handler-case
                 (let* ((env (mapcar #'(lambda (q) (cons (second q) (fs-eval (third q) nil)))
                                     (cdr a)))
                        (z (fs-eval e env)))
                   (and (fs-finite-p z) (fs-dbl z)))
               (error () nil)))))
    (if v
        (list '(mlist) (float (realpart v) 1d0) (float (imagpart v) 1d0))
        nil)))
