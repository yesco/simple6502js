



.assert 42<7,error,"FDISHDLKFJDS"
;;; Doesn't matter if addresses are fixed
.org $700

.macro FISH
  .assert (42<7),error,"FISH"
  .assert (gurka+256)<256,error,"EGGPLANT"

        .byte (gurka+256)
.endmacro

gurka:  

FISH

.end
