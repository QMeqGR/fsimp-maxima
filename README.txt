Package fsimp
*************

1 Package fsimp
***************

1.1 Introduction to package fsimp
=================================

Documentation is under construction!

   The ‘fsimp’ package provides a 'fullsimp' simplification function for
expressions.  It uses the simplification routines in core Maxima, but
combines them with an algorithm that allows expressions to grow and
shrink while trying different simplification routines.  It always
chooses the smallest expression as the most simple.  The user has some
control over the algorithm and routines.

1.2 Functions and Variables for fsimp
=====================================

 -- Variable: fsdebug
     Setting the variable ‘fsdebug’ to 1 will allow the user to see the
     fsimp function operations, list selection of simplification
     routines, etc.

 -- Function: fsimp (expr,[simp1,simp2,...])
     The ‘fullsimp’ function takes an input expression ‘expr’ and
     attempts to find a simpler form using the builtin simplification
     routines in core Maxima.  These include: ‘[resimplify, expand,
     combine, radcan, ratsimp, rootscontract, xthru, multthru, factor,
     sqrtdenest, triglist,exptlist, loglist]’.  Additional trigonometric
     simplifications are applied as well.

     ‘fullsimp’ tries to find the smallest equivalent expression based
     on the Common Lisp ‘conssize’ of the expression.

     The option arguments to ‘fullsimp’ are simplification routines the
     user wants excluded from the list above.

     (%i1) load("fsimp.mac");
     (%o1)      /home/ehm/math/Maxima/share/ehm/fullsimp-maxima/fsimp.mac
     (%i2) fullsimp((1+cos(t))/sin(t));
                                             t
     (%o2)                               cot(-)
                                             2
     (%i3) fullsimp(cos(x)+%i*sin(x));
                                           %i x
     (%o3)                               %e

   If you wish to exclude trigonometric simplifications,

     (%i1) load("fsimp.mac");
     (%o1)      /home/ehm/math/Maxima/share/ehm/fullsimp-maxima/fsimp.mac
     (%i2) fullsimp((1+cos(t))/sin(t),fstrigsimp);
     (%o2)                         (cos(t) + 1) csc(t)

Appendix A Function and Variable index
**************************************

* Menu:

* fsimp:                                 Functions and Variables for fsimp.
                                                               (line 26)

* Menu:

* fsdebug:                               Functions and Variables for fsimp.
                                                               (line 21)

