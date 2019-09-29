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

(defpackage :om-midi)

(compile&load (merge-pathnames "midi-api/midi-api" *load-pathname*))
(compile&load (merge-pathnames "midi-setup" *load-pathname*))
(compile&load (merge-pathnames "tools/midi-values" *load-pathname*))
(compile&load (merge-pathnames "tools/midi-import" *load-pathname*))
(compile&load (merge-pathnames "objects/midi-event" *load-pathname*))
(compile&load (merge-pathnames "objects/midi-controllers" *load-pathname*))
(compile&load (merge-pathnames "objects/midi-track" *load-pathname*))
(compile&load (merge-pathnames "objects/midi-mix" *load-pathname*))
(compile&load (merge-pathnames "tools/midi-extract" *load-pathname*))
(compile&load (merge-pathnames "tools/midi-out" *load-pathname*))
(compile&load (merge-pathnames "compatibility" *load-pathname*))


(omNG-make-package 
 "MIDI"
 :container-pack *om-package-tree*
 :doc "MIDI tools and objects"
 :classes '(midi-track midi-note midievent)
 :functions nil
 :subpackages 
 (list (omNG-make-package 
        "Import/Convert"
        :doc "MIDI import and conversion utilities"
        :functions '(import-midi-notes import-midi-file get-midievents mf-info get-midi-notes))
       (omNG-make-package 
        "Filters"
        :doc "Tools to filter/process"
        :functions '(test-midi-type test-date test-midi-track test-midi-channel test-midi-port))
       (omNG-make-package 
        "Utils"
        :doc "Other MIDI utilities"
        :functions '(midi-type control-change gm-program gm-drumnote mc-to-pitchwheel))
       (omNG-make-package 
        "Out"
        :doc "Send MIDI events out"
        :functions '(pgmout pitchbend pitchwheel ctrlchg volume midi-reset send-midi-note))
       ))
       

 