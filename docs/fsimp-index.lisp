(in-package :cl-info)
(let (
(deffn-defvr-pairs '(
; CONTENT: (<INDEX TOPIC> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS> <NODE NAME>))
("fs_beam_width" . ("fsimp.info" 8614 551 "Functions and Variables for fsimp"))
("fs_check" . ("fsimp.info" 6322 1792 "Functions and Variables for fsimp"))
("fs_max_rounds" . ("fsimp.info" 9174 239 "Functions and Variables for fsimp"))
("fs_search" . ("fsimp.info" 8203 386 "Functions and Variables for fsimp"))
("fsdebug" . ("fsimp.info" 5764 549 "Functions and Variables for fsimp"))
("fullsimp" . ("fsimp.info" 9418 3054 "Functions and Variables for fsimp"))
))
(section-pairs '(
; CONTENT: (<NODE NAME> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS>))
("Functions and Variables for fsimp" . ("fsimp.info" 5688 6652))
("Introduction to package fsimp" . ("fsimp.info" 751 4591))
)))
(load-info-hashtables (maxima::maxima-load-pathname-directory) deffn-defvr-pairs section-pairs))
