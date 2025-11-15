(defmfun $conssize (x) (if (atom x) 0 (do ((x (cdr x) (cdr x)) (sz 1))
((null x) sz) (incf sz (1+ (conssize (car x)))))))
