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
