;============================================================================
; om#: visual programming language for computer-assisted music composition
; J. Bresson et al. (2013-2020)
; Based on OpenMusic (c) IRCAM - Music Representations Team
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
; File author: J. Bresson, D. Bouche
;============================================================================

;=========================================================================
; MAQUETTE CONTROL PATCH
;=========================================================================

(in-package :om)


;;;==========================
;;; THE CONTROL PATCH
;;;==========================
(defclass OMMaqControlPatch (OMPatchInternal) ())

;;; in principle there is only 1 reference (the maquette)
;(defmethod update-from-editor ((self OMMaqControlPatch))
;  (mapc #'(lambda (ref) (report-modifications (editor ref)))
;        (references-to self)))


(defmethod set-control-patch ((self OMSequencer) (patch OMPatch))
  (change-class patch (find-class 'OMMaqControlPatch))
  (setf (ctrlpatch self) patch)
  (setf (references-to (ctrlpatch self)) (list self)))

;;; not used... (?)
(defmethod maquette-reference ((self t)) nil)
(defmethod maquette-reference ((self OMMaqControlPatch))
  (car (references-to self))) ;;; in principle this is the only one !

(defmethod find-persistant-container ((self OMMaqControlPatch))
  (find-persistant-container (car (references-to self))))

(defmethod get-internal-elements ((self OMSequencer))
  (append (call-next-method)
          (get-internal-elements (ctrlpatch self))))


(defparameter *maquette-help-text*
  "This patch is a general controller for the maquette...

Additional inputs/outputs are accesses on the maquette box.
")

(defmethod initialize-instance :after ((self OMSequencer) &rest args)
  
  ;;; put this somewhere else ??
  (set-object-autostop self nil) ;; the maquette doesn't auto-stop when its duration is passed
  
  (unless (ctrlpatch self)
    (let* ((patch (make-instance 'OMMaqControlPatch :name "Control Patch"))
           (inbox (omng-make-special-box 'mysequence (omp 150 12)))
           (outbox (omng-make-special-box 'out (omp 150 200)))
           (connection (omng-make-new-connection (car (outputs inbox)) (car (inputs outbox))))
           (comment (omng-make-new-comment *maquette-help-text* (omp 10 40))))
      (setf (index (reference inbox)) 0
            (defval (reference inbox)) self)
      (omng-add-element patch inbox)
      (omng-add-element patch outbox)
      (omng-connect connection)
      (omng-add-element patch connection)
      (omng-resize comment (omp 120 120))
      (omng-add-element patch comment)
      (set-control-patch self patch)
      ))
  self)



;;; called when some change is made in the maquette or in the control-patch
(defmethod update-from-reference  ((self OMSequencer))
  (loop for item in (references-to self) do (update-from-reference item)))
  
(defmethod get-inputs ((self OMSequencer))
  (get-inputs (ctrlpatch self)))

(defmethod get-outputs ((self OMSequencer))
  (get-outputs (ctrlpatch self)))




;;;====================================
;;; Maquette accessor for control patch or temporal boxes
;;;====================================

(defclass OMMaqIn (OMIn) ())
(defclass OMMaqInBox (OMInBox) ())
(defmethod io-box-icon-color ((self OMMaqInBox)) (om-make-color 0.6 0.2 0.2))

(defmethod next-optional-input ((self OMMaqInBox)) nil)

(defmethod special-box-p ((name (eql 'mysequence))) t)
(defmethod get-box-class ((self OMMaqIn)) 'OMMaqInBox)
(defmethod box-symbol ((self OMMaqIn)) 'mysequence)


(defmethod related-patchbox-slot ((self OMMaqInBox)) nil)
(defmethod allow-text-input ((self OMMaqInBox)) nil)

(defmethod omNG-make-special-box ((reference (eql 'mysequence)) pos &optional init-args)
  (omNG-make-new-boxcall 
   (make-instance 'OMMaqIn :name "CONTAINER-SEQUENCE")
   pos init-args))

(defmethod register-patch-io ((self OMPatch) (elem OMMaqIn))
  (setf (index elem) 0)
  (setf (defval elem) nil))

(defmethod unregister-patch-io ((self OMPatch) (elem OMMaqIn)) nil)


;;; FOR THE META INPUTS
;;; if there are several references (maquetteFile) we assume that the first in the list is the current caller
(defmethod box-container ((self OMMaqControlPatch))  (car (references-to (car (references-to self)))))

;;; check the container: can be a patch, a controlpatch or a maquette
(defmethod maquette-container ((self OMBox)) (maquette-container (container self)))
;;; the references-to a control patch is just the maquette
(defmethod maquette-container ((self OMMaqControlPatch)) (car (references-to self)))
(defmethod maquette-container ((self OMSequencer)) self)
(defmethod maquette-container ((self OMPatch)) (maquette-container (car (box-references-to self))))
(defmethod maquette-container ((self t)) nil)


;;; BOX VALUE
(defmethod omNG-box-value ((self OMMaqInBox) &optional (numout 0)) 
  (set-value self (list (maquette-container self)))
  (return-value self numout))

(defmethod gen-code ((self OMMaqInBox) &optional (numout 0))
  (set-value self (list (maquette-container self)))
  (nth numout (value self)))

(defmethod current-box-value ((self OMMaqInBox) &optional (numout nil))
  (if numout (return-value self numout) (value self)))


(defmethod omng-save ((self OMMaqIn))
  `(:in
    (:type ,(type-of self)) 
    (:index ,(index self))
    (:name ,(name self))
    (:doc ,(doc self))))



#|
;;; note : maybe this is all not useful and I should set the meta just at eval

;;; TRY TO SET THE DEFVAL AS THE CONTAINER MAQUETTE
(defmethod register-patch-io ((self OMMaqControlPatch) (elem OMMaqIn))
  (call-next-method)
  ;;; For OMMaqControlPatch the only references-to is the maquette
  (setf (defval elem) (car (references-to self))))

(defmethod register-patch-io ((self OMPatchInternal) (elem OMMaqIn))
  (call-next-method)
  ;;; For OMPatchInternal the only references-to is the box
  ;;; => just check if it is in a maquette...
  (when (subtypep (type-of (container (car (references-to self)))) 'OMSequencer)
    (setf (defval elem) (container (car (references-to self))))))

(defmethod register-patch-io ((self OMPatchFile) (elem OMMaqIn))
  (call-next-method)
  ;;; For OMPatchFile the only references-to can be multiples !
  ;;; In this case, it will be set only before eval
  (if (and (= 1 (length (references-to self)))
           (subtypep (type-of (container (car (references-to self)))) 'OMSequencer))
      (setf (defval elem) (container (car (references-to self))))))
|#
