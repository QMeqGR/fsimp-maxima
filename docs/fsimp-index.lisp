(in-package :cl-info)
(let (
(deffn-defvr-pairs '(
; CONTENT: (<INDEX TOPIC> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS> <NODE NAME>))
("fs_beam_width" . ("fsimp.info" 9133 551 "Functions and Variables for fsimp"))
("fs_check" . ("fsimp.info" 6841 1792 "Functions and Variables for fsimp"))
("fs_max_rounds" . ("fsimp.info" 9693 239 "Functions and Variables for fsimp"))
("fs_search" . ("fsimp.info" 8722 386 "Functions and Variables for fsimp"))
("fs_split" . ("fsimp.info" 9937 1459 "Functions and Variables for fsimp"))
("fsdebug" . ("fsimp.info" 6074 754 "Functions and Variables for fsimp"))
("fullsimp" . ("fsimp.info" 11481 3054 "Functions and Variables for fsimp"))
))
(section-pairs '(
; CONTENT: (<NODE NAME> . (<FILENAME> <BYTE OFFSET> <LENGTH IN CHARACTERS>))
("Functions and Variables for fsimp" . ("fsimp.info" 5998 8317))
("Introduction to package fsimp" . ("fsimp.info" 751 4881))
)))
(load-info-hashtables (maxima::maxima-load-pathname-directory) deffn-defvr-pairs section-pairs))
