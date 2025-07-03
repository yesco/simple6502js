endaddr:
.byte "<AFTER"

;;; for debuggability, if no printer included
;;; include it AFTER, so it doesn't count for size

.ifndef PRINTER
print_for_debug:
        PRINTHEX=1
        .include "print.asm"
.endif

;;;               NO CODE HERE !
;;; 
;;; (this is so that start, end can be reported)
