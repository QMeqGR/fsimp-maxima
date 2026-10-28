(in-package :cl-info)
(let (
(deffn-defvr-pairs '(
; CONTENT: (<INDEX TOPIC> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS> <NODE NAME>))
("fs_check" . ("fsimp.info" 5300 1792 "Functions and Variables for fsimp"))
("fsdebug" . ("fsimp.info" 4842 449 "Functions and Variables for fsimp"))
("fullsimp" . ("fsimp.info" 7181 3054 "Functions and Variables for fsimp"))
))
(section-pairs '(
; CONTENT: (<NODE NAME> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS>))
("Functions and Variables for fsimp" . ("fsimp.info" 4766 5373))
("Introduction to package fsimp" . ("fsimp.info" 751 3701))
)))
(load-info-hashtables (maxima::maxima-load-pathname-directory) deffn-defvr-pairs section-pairs))
