;;; Do not edit; automatically generated via build-html-index.lisp


(in-package :cl-info)
(let ((html-index
       '(("fsdebug"
          "fsimp_html/index.html"
          "index-fsdebug")
         ("fs_search"
          "fsimp_html/index.html"
          "index-fs_005fsearch")
         ("fs_max_rounds"
          "fsimp_html/index.html"
          "index-fs_005fmax_005frounds")
         ("fs_check"
          "fsimp_html/index.html"
          "index-fs_005fcheck")
         ("fs_beam_width"
          "fsimp_html/index.html"
          "index-fs_005fbeam_005fwidth")
         ("fullsimp"
          "fsimp_html/index.html"
          "index-fullsimp"))))
  (let ((dir (maxima::maxima-load-pathname-directory))) (dolist (entry html-index) (destructuring-bind (item path id) entry (setf (gethash item *html-index*) (cons (namestring (merge-pathnames path dir)) id))))))