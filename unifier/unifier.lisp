;; =========================================
;; ============= DATA TYPES ================
;; =========================================

(defstruct predicate
  sym) 

(defstruct constant
  sym)

(defstruct lvar 
  sym)

(defstruct (binding
             (:print-function
               (lambda (struct stream depth)
                 (declare (ignore depth))
                 (format stream "{~A / ~A}" 
                         (print-expr (binding-term struct))
                         (print-expr (binding-lvar struct)))))) 
  term lvar)

(defstruct (fail
             (:print-function
               (lambda (struct stream depth)
                 (declare (ignore struct))
                 (declare (ignore depth))
                (format stream "FAIL")))))

;; =========================================
;; ============= TOP LEVEL FUNCTION ========
;; =========================================

; takes two expressions and returns
; and MGU
(defun Unify (E1 E2 &optional visual)
  (format t "FINAL SUBST: ~%~A~%" 
          (unify1 E1 E2 nil visual)))

; takes two expressions and tries to unify
; crossponding elements
(defun unify1 (E1 E2 mu &optional visual)
  (visualise-expr E1 E2 visual)
  (if (and (null E1)
           (null E2))
    (return-from unify1 mu))
  (if (or (null E1)
          (null E2))
    (return-from unify1 (make-fail)))
  (if (fail-p mu)
    (return-from unify1 mu))
  (if (equalp E1 E2)
    (return-from unify1 mu))
  (if (lvar-p E1)
    (return-from unify1 (unify-var E1 E2 mu visual)))
  (if (lvar-p E2)
    (return-from unify1 (unify-var E2 E1 mu visual)))
  (if (or (atomp E1)
          (atomp E2))
    (return-from unify1 (make-fail)))
  (if (not (equalp (length E1)
                   (length E2)))
    (return-from unify1 (make-fail)))
  (unify1 (cdr E1) (cdr E2) (unify1 (car E1) (car E2) mu visual) visual))

; called when a variable is encountered
; tries to bind the variable
(defun unify-var (x e mu &optional visual)
  (let ((binding (bound-p x mu)))
    (if binding 
      (unify1 (binding-term binding) e mu visual)
      (progn
        (let ((term (ground mu e)))
          (if (occurs-p x term)
            (make-fail) 
            (let ((new-mu (list (make-binding :term term :lvar x ))))
              (setf mu
                    (append (update-mu new-mu mu) new-mu))
              (visualise-mu mu visual))))))))

;; =========================================
;; ========== HELPER FUNCTIONS =============
;; =========================================

; returns true if e1 is not a variable or 
; a list
(defun atomp (E1)
  (or (predicate-p E1)
      (constant-p E1)))

; returns true if x has a binding in mu
(defun bound-p (x mu)
  (find-if #'(lambda (e)
               (equalp (binding-lvar e) x))
           mu))

; return e after applying subst mu
(defun ground (mu e)
  (if (consp e)
    (cons (ground mu (car e))
          (ground mu (cdr e)))
    (if (lvar-p e)
      (let ((binding (bound-p e mu)))
        (if binding
          (binding-term binding)
          e))
      e)))

; returns true if x occurs in term
(defun occurs-p (x term)
  (if (consp term)
    (or (occurs-p x (car term))
        (occurs-p x (cdr term)))
    (equalp x term)))

; updates the bindings in mu with the
; binding found
(defun update-mu (new-mu mu)
  (mapcar #'(lambda (binding)
              (make-binding :term (ground new-mu (binding-term binding))
                            :lvar (binding-lvar binding)))
          mu))


;; =========================================
;; ============= PRINTING ==================
;; =========================================

; prints an fol expression
(defun print-expr (expr)
  (if (consp expr)
    (if (predicate-p (car expr))
      (format nil "~A(~{~A~^, ~})" (predicate-sym (car expr))
              (mapcar #'print-expr (cdr expr)))
      (format nil "(~{~A~^, ~})"
              (mapcar #'print-expr expr)))
    (typecase expr
      (constant (format nil "~C" (constant-sym expr)))
      (lvar (format nil "~C" (lvar-sym expr)))
      (predicate (format nil "~C" (predicate-sym expr))))))

; prints mu as a list of bindings
; if visual is true
(defun visualise-mu (mu visual)
  (if visual
    (progn (format t "~A ~%" mu) 
           (read-char)))
  mu)

; prints a step in the solution as
; E1 == E2 if visual is true
(defun visualise-expr (E1 E2 visual)
  (if (and visual
           (not (and (null E1)
                     (null E2))))
    (progn (format t "~A == ~A ~%" (print-expr E1)
                   (print-expr E2)) 
           (read-char))))
