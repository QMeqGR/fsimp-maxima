;;; Do not edit; automatically generated via build-html-index.lisp


(in-package :cl-info)
(let ((html-index
       '(("fsdebug"
          "fsimp_html/index.html"
          "index-fsdebug")
         ("fs_check"
          "fsimp_html/index.html"
          "index-fs_005fcheck")
         ("fullsimp"
          "fsimp_html/index.html"
          "index-fullsimp"))))
  (let ((dir (maxima::maxima-load-pathname-directory))) (dolist (entry html-index) (destructuring-bind (item path id) entry (setf (gethash item *html-index*) (cons (namestring (merge-pathnames path dir)) id))))))