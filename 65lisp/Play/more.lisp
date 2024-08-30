(defun match (pat in)
  (if (null pat) 
      (null in)
    (if (eq (first pat) '*)
        (wildcard pat in)
      (if (eq (first pat) (first in))
          (match (rest pat) (rest in))
        nil))))

