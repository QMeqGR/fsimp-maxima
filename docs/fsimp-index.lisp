(in-package :cl-info)
(let (
(deffn-defvr-pairs '(
; CONTENT: (<INDEX TOPIC> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS> <NODE NAME>))
("fsdebug" . ("fsimp.info" 2195 179 "Functions and Variables for fsimp"))
("fullsimp" . ("fsimp.info" 2379 2520 "Functions and Variables for fsimp"))
))
(section-pairs '(
; CONTENT: (<NODE NAME> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS>))
("Functions and Variables for fsimp" . ("fsimp.info" 2119 2776))
("Introduction to package fsimp" . ("fsimp.info" 751 1242))
)))
(load-info-hashtables (maxima::maxima-load-pathname-directory) deffn-defvr-pairs section-pairs))
