--- NORMAL EVAL
      global var:  5000#   8328414c   7.943s - bar 	=> 11
     dynamic var:  5000#   6636172c   6.329s - *fie* 	=> 99
    dynamic deep:  5000#   8330550c   7.945s - *foo* 	=> 0
            cons:  5000#  20579929c  19.627s - (cons 3 4) 	=> (3 . 4)
             car:  5000#  13778302c  13.140s - (car (quote (3 4))) 	=> 3
             cdr:  5000#  13778447c  13.140s - (cdr (quote (3 4))) 	=> (4)
            null:  5000#  14349421c  13.685s - (null nil) 	=> nil
            null:  5000#  14359351c  13.694s - (null T) 	=> T
           null':  5000#  13929629c  13.284s - (null (quote nil)) 	=> nil
           null':  5000#  13939559c  13.294s - (null (quote T)) 	=> T
       * + const:  5000#  42567709c  40.596s - (* (+ 1 2) (+ 1 1 1 1) 2) 	=> 24
         * + var:  5000#  71994002c  68.659s - (* (+ one two) (+ one one one one) two) 	=> 24
       caaaddddr:  5000#  49000497c  46.731s - (car (car (car (cdr (cdr (cdr (cdr (quote (1 2 3 4 ((5 6) 7) 8))))))))) 	=> 5

--- AL
      global var:  5000#   8411569c   8.022s - ,ýG@ 	=> 11
     dynamic var:  5000#   8412663c   8.023s - ,	H@ 	=> 0
    dynamic deep:  5000#   8413660c   8.024s - ,H@ 	=> 0
            cons:  5000#  18096695c  17.258s - 34C 	=> (3 . 4)
             car:  5000#   9589082c   9.145s - ,‡NA 	=> 3
             cdr:  5000#   9639744c   9.193s - ,‡ND 	=> (4)
            null:  5000#  10000152c   9.537s - ,!F@U 	=> T
            null:  5000#   9987709c   9.525s - ,-F@U 	=> nil
           null':  5000#   8513799c   8.119s - ,!FU 	=> T
           null':  5000#   8501852c   8.108s - ,-FU 	=> nil
       * + const:  5000#  29649368c  28.276s - 12+111+1++2** 	=> 24
ERR      * + var:  5000#    943748c   0.900s - ,iF@ 	=> 
		  ERROR
       caaaddddr:  5000#  25778936c  24.585s - ,§NDDDDAAA 	=> 5

--- AL w TOP
      global var:  5000#   8301687c   7.917s - ,1G@ 	=> 11
     dynamic var:  5000#   8303276c   7.919s - ,=G@ 	=> 0
    dynamic deep:  5000#   8305261c   7.921s - ,IG@ 	=> 0
            cons:  5000#  18277264c  17.431s - 34C 	=> (3 . 4)
             car:  5000#   8938705c   8.525s - ,»MA 	=> 3
             cdr:  5000#   8989841c   8.573s - ,»MD 	=> (4)
            null:  5000#   9829800c   9.374s - ,UE@U 	=> T
            null:  5000#   9817853c   9.363s - ,aE@U 	=> nil
           null':  5000#   8404439c   8.015s - ,UEU 	=> T
           null':  5000#   8392986c   8.004s - ,aEU 	=> nil
       * + const:  5000#  28369545c  27.055s - 12+111+1++2** 	=> 24
ERR      * + var:  5000#    944092c   0.900s - ,E@ 	=> 
		  ERROR
       caaaddddr:  5000#  21528217c  20.531s - ,ÛMDDDDAAA 	=> 5
