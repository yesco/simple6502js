99
(set 'foo 45)
88
foo
77
111
(set 'sub (lambda (- (+ (* (/ a 2) 3) 4) 5)))
222
(set 'bench (lambda
    (if (< a 1000)
        (loop (+ a 1))
        (sub a)
        'done)))
333
;(bench 0)

; EVAL dies as 30 deep. LOL
444
(bench 970)
555






