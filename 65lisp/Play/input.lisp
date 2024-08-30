(defun prompt-read (prompt)
  (format *query-io* "~%~a: " prompt)  
  (force-output *query-io*)
  (read-line *query-io*))

(defun hello ()
  (format t "~&Hello ~a!~%" (prompt-read "What's your name")))

(defmacro with-input ((input) &body body)
  `(let ((*query-io* (make-two-way-stream (make-string-input-stream ,input)
                                          (make-string-output-stream))))
     ,@body))

(defun test ()
  (with-input ("jkiiski")
    (hello))
  (with-input ("rnso")
    (hello)))
(test)
; Hello jkiiski!
; Hello rnso!
