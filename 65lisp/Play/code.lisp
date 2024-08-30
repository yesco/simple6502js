(define (fib n)
  (if (<= n 1) n
    (* (fib (- n 1)) (fib (- n 2)))))

(define (fac n)
  (if (<= n 2) 1
    (* n (fac (- n 1)))))

