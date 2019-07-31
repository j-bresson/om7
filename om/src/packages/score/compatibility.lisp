;============================================================================
; om7: visual programming language for computer-aided music composition
; Copyright (c) 2013-2017 J. Bresson et al., IRCAM.
; - based on OpenMusic (c) IRCAM 1997-2017 by G. Assayag, C. Agon, J. Bresson
;============================================================================
;
;   This program is free software. For information on usage 
;   and redistribution, see the "LICENSE" file in this distribution.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
;
;============================================================================
; File author: J. Bresson
;============================================================================

;;; LOAD OBJECTS AND CODE FROM OM6


(in-package :om)


;;; compat API:
(defmethod update-arg-names ((reference (eql 'chord-seq)))
  '(("legato" "llegato")))

;;; Note/ToDo: CHORD-SEQ LEGATO IS NO LONGER % but a simple factor

;;; Redefinitions of OM6 load utilities
(defun load-obj-list-from-save (list)
  (loop for item in list collect (eval item)))

;;; SCORE OBJECTS
;;; => TODO
(defmethod set-patch-pairs ((self t) list) )
(defmethod load-port-info ((self t) port) )
(defmethod init-mus-color ((self t) color) )
(defmethod set-extra-pairs ((self t) extras) )
(defmethod set-tonalite ((self t) tonalite) )
(defmethod set-object-analysis ((self t) analyse) )

;;; SCORE EDITOR PARAMS
;;; => hack / to(re)do when score editors are operational
(defclass edition-values () 
  ((paper-size :accessor paper-size)
   (top-margin :accessor top-margin)
   (left-margin :accessor left-margin)
   (right-margin :accessor right-margin)
   (bottom-margin :accessor bottom-margin)
   (orientation :accessor orientation)
   (scale :accessor scale)
   (system-space :accessor system-space)
   (system-color :accessor system-color)
   (line-space :accessor line-space)
   (title :accessor title)
   (show-title? :accessor show-title?)
   (show-page? :accessor show-page?)
   (sheet-id :accessor sheet-id)
   (page-mode :accessor page-mode)))
   


