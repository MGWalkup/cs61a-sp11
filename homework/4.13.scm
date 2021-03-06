(load "mceval")

(define (make-unbound! var frame)
  (define (scan vars vals)
    (cond ((null? vars) (error "Cannot unbind var " var))
          ((eq? var (car vars))
           (set-car! vars (cdr vars))
           (set-car! vals (cdr vals)))
          (else (scan (cdr vars) (cdr vals)))))
  (scan (frame-variables frame) (frame-values frame)))

(define (unbind? exp)
  (tagged-list? exp 'make-unbound!))

(define (unbind-var exp) (cadr exp))

(define (eval-unbind exp env)
  (make-unbound! (unbind-var exp) (first-frame env)))


(define (mc-eval exp env)
  (cond ((self-evaluating? exp) exp)
	((variable? exp) (lookup-variable-value exp env))
	((quoted? exp) (text-of-quotation exp))
	((assignment? exp) (eval-assignment exp env))
	((definition? exp) (eval-definition exp env))
	((if? exp) (eval-if exp env))
	((lambda? exp)
	 (make-procedure (lambda-parameters exp)
			 (lambda-body exp)
			 env))
	((begin? exp) 
	 (eval-sequence (begin-actions exp) env))
	((cond? exp) (mc-eval (cond->if exp) env))
  ((unbind? exp) (eval-unbind exp env))
	((application? exp)
	 (mc-apply (mc-eval (operator exp) env)
		   (list-of-values (operands exp) env)))
	(else
	 (error "Unknown expression type -- EVAL" exp))))
