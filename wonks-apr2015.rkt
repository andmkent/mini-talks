#lang slideshow 
(require slideshow/code)

;; title slide
(slide #:title "" 
       (t "Enriching Typed Racket with Dependent Types")
       (t "Overview and Status Report"))

;; how is this novel?
(slide (item "We are extending Typed Racket to include refinements"
             "and integer linear constraints")
       'next
       (item (it "Q:  Haven't those things been done before?"))
       'next
       (item "Refinements and integer constraints? Absolutely!")
       'next
       (item (it "Q:  So.. what's novel?"))
       'next
       (subitem "Expressive, practical feature set +" 
                (it "sound interoperation") "with full" 
                "featured dynamically typed language")
       'next
       (subitem "Refinements + unique type system used by" 
                "Typed Racket and Typed Clojure" 
                (it "(Logical Types for Untyped Languages, ") 
                (it "Tobin-Hochstadt & Felleisen, ICFP 2010)")))

;; refresher
(slide #:title "Already Logical Types" 
       (t "A Brief Refresher on How Typed Racket Works!"))


;; Introduce the need for logical propositions
(slide #:title "Already Logical Types"
       (item "Question:  How do we type a Lisp-like language?")
       'next
       'alts
       (list (list (item "Simple example:")
                   'next
                   (subitem (code (+ 1 2)))
                   'next
                   (subitem (code +) "is of type" (code Number -> Number -> Number))
                   'next
                   (subitem (code 1) "and" (code 2) "are of type" (code Number))
                   'next
                   (subitem "therefore " (code (+ 1 2)) "is of type" (code Number)))
             (list (item "Less simple example:")
                   'next
                   (subitem (code (define (plus1 n)
                                    (if (fixnum? n)
                                        (fx+ n 1)
                                        (fl+ n 1.0)))))
                   'next
                   (subitem (code n) "starts off as" (it "either") 
                            "a" (code Fixnum) "or a" (code Flonum))
                   'next
                   (subitem "We need to reason about the conditional test"
                            (code (fixnum? n)))))
       'next
       (item "Answer: By using" (bt "logical propositions") " about types!"))


;; Walk through logical propositions on plus1
(slide #:title "Already Logical Types"
       (item "Typechecking our example:")
       (code (define (plus1 n)
               (if (fixnum? n)
                   (fx+ n 1)
                   (fl+ n 1.0))))
       'next
       'alts
       (list (list (item "Assume" (code (n -: Fixnum)) 
                         (it "or") (code (n -: Float))))
             (list (item "Assume" (code (n -: (U Fixnum Float))))))
       'next
       (item "In the" (bt "then branch") (code (n -: Fixnum)))
       'next
       (subitem (code (fx+ n 1)) "typechecks!")
       'next
       (item "In the" (bt "else branch") (code (n -! Fixnum)))
       'next
       (subitem "combined with" (code (n -: (U Fixnum Float))) 
                "implies" (code (n -: Float)))
       'next
       (subitem (code (fl+ n 1.0)) "typechecks!"))

;; Briefly show typing judgment
(slide #:title "Already Logical Types"
       (item "Typechecking our example:")
       (code (define (plus1 n)
               (if (fixnum? n)
                   (fx+ n 1)
                   (fl+ n 1.0))))
       'alts
       (list (list (item "Simple types won't cut it!")
                   'next
                   (subitem (code (Γ ⊢ (fixnum? n) 
                                     : Boolean))))
             (list (item "We need logical types!")
                   'next
                   (subitem (code (Γ ⊢ (fixnum? n) 
                                     : Boolean 
                                     \; (n -: Fixnum) when not #f
                                     \; (n -! Fixnum) when #f
                                     \; ∅)))))
       'next
       (item "Typed Racket uses logical propositions as part" 
             "of the typing judgement and in function types"))


;; refresher
(slide #:title "More Descriptive Types"
       (t "So what is the type of plus1?")
       'next
       (t "(Hint... we're going to leverage those logical propositions!)"))

;; so what is the type of plus1?
;; Briefly show typing judgment
(slide #:title "More Descriptive Types"
       (item "The type of" (code plus1) ":")
       'next
       'alts
       (list 
        (list (item "Good")
              (code [(U Fixnum Float) -> (U Fixnum Float)])
              'next
              (item "But we'd like to know" (code (plus1 1)) "produces a" (code Fixnum)))
        (list (item "Better")
              (code (case-> [Fixnum -> Fixnum]
                            [Float -> Float]
                            [(U Fixnum Float) 
                             -> (U Fixnum Float)]))
              'next
              (item "But we don't want to forget the relation between input and output types")
              'next
              (item "e.g. we want this to typecheck:" 
                    (code (define (foo [x : (U Fixnum Float)]) : Fixnum
                            (let ([y (plus1 x)])
                              (if (fixnum? x)
                                  (fx* x y)
                                  42))))))
        (list (item "Best")
              (code (dependent-case-> 
                     [Fixnum -> Fixnum]
                     [Float -> Float]))
              'next
              'alts
              (list (list (item "Now this typechecks!"
                                (code (define (foo [x : (U Fixnum Float)]) : Fixnum
                                        (let ([y (plus1 x)])
                                          (if (fixnum? x)
                                              (fx* x y)
                                              42))))))
                    (list (item "... but how" (it "is") (code dependent-case->) "implemented?")
                          'next)))))

(slide #:title "More Descriptive Types"
       (code (dependent-case-> 
              [Fixnum -> Fixnum]
              [Float -> Float]))
       'next
       (item "Is just syntactic sugar for this:")
       (code [([x : (U Fixnum Float)])
              -> 
              (Refine [ret : (U Fixnum Float)]
                      (or (and [x   -: Fixnum]
                               [ret -: Fixnum])
                          (and [x   -: Float]
                               [ret -: Float])))])
       'next
       (item "By adding" (bt "logical refinement types")
             "we can more precisely specify types!"))

(slide #:title "More Descriptive Types"
       (item "Another example (from Q on #racket last night)")
       'next
       (item "Assume" (code (denom -: Float)) 
             "and" (code (ε -: Positive-Float)))
       'next
       (code (cond
               [(fl> (flabs denom) ε) 
                <division-exp>]
               ...))
       'next
       (item "In" (code <division-exp>) (it "we") "know" 
             (code denom) "is non-zero, but" 
             "currently in TR this fact is lost")
       'next
       (item "With a dependent refinement in the range of" 
             (code flabs) "we could track this properly!"))

(slide #:title "More Descriptive Types"
       (item "Refinements are a great, natural extension to Typed Racket!")
       'next
       (subitem "Relate the types of runtime values!")
       'next
       (subitem "Create expressive dependent functions!")
       'next
       (subitem "The logical propositions are already" 
                "part of the type system!")
       'next
       (subitem "Refinements are easily mapped to dependent contracts")
       'next
       (subitem "Implemented and working! In my development fork..."))


(slide #:title "Linear Integer Constraints"
       (t "Relating more than just 'types'!"))

(slide #:title "Linear Integer Constraints"
       (item "Types can depend on other types...")
       'next
       (item "are there other practical, decidable theories we want to reason about?")
       'next
       (item (bt "Linear integer constraints") "are a well" 
             "understood, decidable problem w/ numerous applications!"))

(slide #:title "Linear Integer Constraints"
       'alts
       (list (list (code (define (norm [v : (Vectorof Real)])
                           (sqrt (for/sum ([i (vec-len v)])
                                   (square (vector-ref v i))))))
                   'next
                   (item "Is it possible to get an out of bounds error from"
                         (code (vector-ref v i)) "?")
                   'next
                   (item "Nope!" (code ∀i (and (≤ 0 i) (< i (vec-len v))))))
             (list (code (define (norm [v : (Vectorof Real)])
                           (sqrt (for/sum ([i (vec-len v)])
                                   (square (vector-ref v i))))))
                   (item "The optimizer can replace" (code vector-ref)
                         "with" (code unsafe-vector-ref) ":")
                   'next
                   (code (define (norm [v : (Vectorof Real)])
                           (sqrt (for/sum ([i (vec-len v)])
                                   (square (unsafe-vector-ref v i)))))))))

(slide #:title "Linear Integer Constraints"
       (code (: save-vec-ref 
                (All (α) (([v : (Vectorof α)]
                           [i : Natural (< i (vec-len v))])
                          -> α)))
             (define safe-vec-ref unsafe-vector-ref))
       'next
       (item "Guaranteed safe usages of functions like" (code unsafe-vector-ref))
       'next
       (item (code safe-vector-ref) "can never have a runtime out-of-bounds error!"))

(slide #:title "Linear Integer Constraints"
       (code (define (dot-product [v1 : (Vectorof Real)]
                                  [v2 : (Vectorof Real)
                                      (= (vec-len v1)
                                         (vec-len v2))])
               (for/sum ([i (vec-len v1)])
                 (* (safe-vec-ref v1 i)
                    (safe-vec-ref v2 i)))))
       'next
       (item "No bounds errors + verified optimizations!"))

(slide #:title "Linear Integer Constraints"
       (item "What about" (code plus1) "?")
       'next
       (code (dependent-case->
              [[n : Fixnum] -> [m : Fixnum
                                  (= m (+ 1 n))]]
              [Float -> Float])))

(slide #:title "To Do"
       (t "Next Steps?"))

(slide #:title "To Do"
       (item "Finish implementing these features")
       'next
       (item "Experiment w/ new types for standard library")
       'next
       (item "Support arbitrary pure predicates in refinements")
       'next
       (t "Thanks!"))