(in-package :cl-info)
(let (
(deffn-defvr-pairs '(
; CONTENT: (<INDEX TOPIC> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS> <NODE NAME>))
("fsdebug" . ("fsimp.info" 1438 179 "Functions and Variables for fsimp"))
("fsimp" . ("fsimp.info" 1622 2099 "Functions and Variables for fsimp"))
))
(section-pairs '(
; CONTENT: (<NODE NAME> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS>))
("Functions and Variables for fsimp" . ("fsimp.info" 1362 2355))
("Introduction to package fsimp" . ("fsimp.info" 751 497))
)))
(load-info-hashtables (maxima::maxima-load-pathname-directory) deffn-defvr-pairs section-pairs))
