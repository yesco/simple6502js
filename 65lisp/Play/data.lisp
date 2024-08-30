
(defparameter *rules*
  '(((* x hello * y) (hello. how can I help ?))
    ((* x i want * y) (what would it mean if you got y ?) (why do you want y ?))
    ((* x i wish * y) (why would it be better if y ?))
    ((* x i hate * y) (what makes you hate y ?))
    ((* x if * y)
     (do you really think it is likely that y)
     (what do you think about y))
    ((* x no * y) (why not?))
    ((* x i was * y) (why do you say x you were y ?))
    ((* x i feel * y) (do you often feel y ?))
    ((* x i felt * y) (what other feelings do you have?))
    ((* x) (you say x ?) (tell me more.))))
