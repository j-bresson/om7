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

(in-package :om)

;;;===================================
;;; PLAY (MIDI)
;;; Specific actions for score-objects playback 
;;;===================================

;;; chord-seq/voice already play (from data-stream)

(defmethod play-obj? ((self multi-seq)) t)
(defmethod play-obj? ((self chord)) t)
(defmethod play-obj? ((self note)) t)

;;;===================================================
;;; PLAY-ACTIONS
;;;===================================================


(defmethod get-action-list-for-play ((c chord) interval &optional parent)
  (remove 
   nil 
   (loop for n in (notes c) append
         (let ((channel (or (chan n) 1)))
           (list 
            (when (in-interval (offset n) interval :exclude-high-bound t) 
              (list (offset n)
                    #'(lambda (note) (om-midi::midi-send-evt 
                                      (om-midi:make-midi-evt 
                                       :type :keyOn
                                       :chan channel :port 0
                                       :fields (list (truncate (midic note) 100) (vel note)))))
                    (list n)))
      
            (when (in-interval (+ (offset n) (dur n)) interval :exclude-high-bound t) 
     
   
              (list (+ (offset n) (dur n))
                    #'(lambda (note) (om-midi::midi-send-evt 
                                      (om-midi:make-midi-evt 
                                       :type :keyOff
                                       :chan channel :port 0
                                       :fields (list (truncate (midic note) 100) 0))))
                    (list n)))
            )))))

(defmethod get-action-list-for-play ((n note) interval &optional parent)
  (let ((channel (or (chan n) 1)))
    (remove 
     nil
     (list 
      (when (in-interval 0 interval :exclude-high-bound t) 
        (list (offset n)
              #'(lambda (note) (om-midi::midi-send-evt 
                                (om-midi:make-midi-evt 
                                 :type :keyOn
                                 :chan channel :port 0
                                 :fields (list (truncate (midic note) 100) (vel note)))))
              (list n)))
      
      (when (in-interval (dur n) interval :exclude-high-bound t) 
     
   
        (list (+ (offset n) (dur n))
              #'(lambda (note) (om-midi::midi-send-evt 
                                (om-midi:make-midi-evt 
                                 :type :keyOff
                                 :chan channel :port 0
                                 :fields (list (truncate (midic note) 100) 0))))
              (list n)))
      ))))



(defmethod get-action-list-for-play ((object chord-seq) interval &optional parent)
  (sort 
   (loop for c in (remove-if #'(lambda (chord) (or (< (+ (date chord) (get-obj-dur chord)) (car interval))
                                                   (> (date chord) (cadr interval))))
                             (chords object))
    
         append 
         (loop for n in (notes c) append
               (let ((channel (or (chan n) 1)))
                 (remove nil 
                         (list 
                          (if (in-interval (+ (date c) (offset n)) interval :exclude-high-bound t) 
                                  
                              (list (+ (date c) (offset n))
                                        
                                    #'(lambda (note) (om-midi::midi-send-evt 
                                                      (om-midi:make-midi-evt 
                                                       :type :keyOn
                                                       :chan channel :port 0
                                                       :fields (list (truncate (midic note) 100) (vel note)))))
                                    (list n)))

                          (if (in-interval (+ (date c) (offset n) (dur n)) interval :exclude-high-bound t)
                                
                              (list (+ (date c) (offset n) (dur n))
                                      
                                    #'(lambda (note) (om-midi::midi-send-evt 
                                                      (om-midi:make-midi-evt 
                                                       :type :keyOff
                                                       :chan channel :port 0
                                                       :fields (list (truncate (midic note) 100) 0))))
                                    (list n)))
                      
                          ))))
         )
   '< :key 'car))



(defmethod get-action-list-for-play ((object multi-seq) interval &optional parent)
  
  (loop for voice in (obj-list object)
        append (get-action-list-for-play voice interval parent))
  
  )



;;;===================================================
;;; MICROTONES
;;;===================================================

(add-preference :midi :auto-bend "Auto microtone bend" :bool t 
                "Applies 1/8th pitch-bend to MIDI channels 1-4 during playback of score-objects")

;;; split note on channels in case of microtonal setup (4 or 8)
;;; tone = 0, 1/8 = 1, 1/4 = 2, 3/8 = 3
;;; default bend channel 1 = 0, channel 2 = 25 mc, channel 3 = 50 mc, channel 4 = 75mc

(defun micro-bend-messages (&optional port)
  (loop for chan from 1 to 4
        for pb from 8192 by 1024
        collect (om-midi::make-midi-evt
                 :type :PitchBend
                 :date 0
                 :chan chan
                 :port (or port (get-pref-value :midi :out-port))
                 :fields (val2lsbmsb pb))))

(defun micro-reset-messages (&optional port)
  (loop for chan from 1 to 4
        collect (om-midi::make-midi-evt
                 :type :PitchBend
                 :date 0
                 :chan chan
                 :port (or port (get-pref-value :midi :out-port))
                 :fields (val2lsbmsb 8192))))

(defun micro-bend (&optional port)
  (loop for pb-evt in (micro-bend-messages port)
        do (om-midi:midi-send-evt pb-evt)))

(defun micro-reset (&optional port)
  (loop for pb-evt in (micro-reset-messages port)
        do (om-midi:midi-send-evt pb-evt)))



;; t / nil / list of approx where it must be applied
(defparameter *micro-channel-mode-on* '(4 8))
(defparameter *micro-channel-approx* 8)

(defun micro-channel-on (approx)
  (and 
   approx
   (if (consp *micro-channel-mode-on*) 
       (find approx *micro-channel-mode-on* :test '=)
     *micro-channel-mode-on*)))

; channel offset from midic 
(defun micro-channel (midic &optional approx)
  (if (micro-channel-on approx)
      (let ((mod (/ 200 (or *micro-channel-approx* approx))))
        (round (approx-m (mod midic 100) mod) mod))
    0))


(defmethod collec-ports-from-object ((self t))
  (remove-duplicates (mapcar #'port (get-notes self))))

;;; chord-seq and multi-seq don't work with get-notes
(defmethod collec-ports-from-object ((self chord-seq))
  (remove-duplicates 
   (loop for c in (inside self) append (collec-ports-from-object c))))

(defmethod collec-ports-from-object ((self multi-seq))
  (remove-duplicates 
   (loop for c in (inside self) append (collec-ports-from-object c))))


;;; HOOK ON PLAYER METHODS:

(defmethod player-play-object ((self scheduler) (object score-element) (caller score-editor) &key parent interval)
  
  (declare (ignore parent interval))
  
  (let ((approx (/ 200 (step-from-scale (editor-get-edit-param caller :scale)))))
    (when (and (get-pref-value :midi :auto-bend)
               (micro-channel-on approx))
      (setf (pitch-approx object) approx)
      (loop for p in (collec-ports-from-object object) do (micro-bend p))))
  
  (call-next-method))


(defmethod player-play-object ((self scheduler) (object score-element) (caller ScoreBoxEditCall) &key parent interval)
  
  (declare (ignore parent interval))
  
  (let ((approx (/ 200 (step-from-scale (get-edit-param caller :scale)))))
    (when (and (get-pref-value :midi :auto-bend)
               (micro-channel-on approx))
      (setf (pitch-approx object) approx)
      (loop for p in (collec-ports-from-object object) do (micro-bend p))
      ))
  
  (call-next-method))


(defmethod player-stop-object ((self scheduler) (object score-element))
  (om-midi::midi-all-keys-off)
  (when *micro-channel-mode-on*
    (loop for p in (collec-ports-from-object object) do (micro-reset p)))
  (call-next-method))

