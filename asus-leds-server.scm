;; Small daemon that controls keyboard brightness on Asus Zenbook UX31A
;; Copyright (C) 2015 Jan Synáček
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

;; Known bugs:
;; - The 'signal-handler' doesn't work well. It doesn't terminate the
;;   process, which makes it unusable when run from the service manager
;;   as a system service.
;;
;; Code:

(use-modules (rnrs bytevectors)
	     (rnrs io ports))

(define sys      "/sys/class/leds/asus::kbd_backlight/brightness")
(define sockpath "/run/asus/asus-leds.socket")
(define sock     -1)


(define (brightness-get)
  "Read the brightness value from the sys file and return it as a number."
  (call-with-input-file sys
    (lambda (port)
      (string->number (get-string-n port 1)))))

(define (brightness-up)
  "Increase brightness by 1."
  (call-with-output-file sys
    (lambda (port)
      (put-string port (number->string (1+ (brightness-get)))))))

(define (brightness-down)
  "Decrease brightness by 1."
  (call-with-output-file sys
    (lambda (port)
      (let ((b (1- (brightness-get))))
	(put-string port (number->string (if (negative? b)
					     0
					     b)))))))

(define (server-loop sock)
  "Main server loop."
  (let loop ()
    (let ((buf (make-bytevector 8)))
      (recvfrom! sock buf)
      (let ((bufstr (utf8->string buf)))
	(cond
	 ((string=? (string-take bufstr 2) "up")
	  (brightness-up))
	 ((string=? (string-take bufstr 4) "down")
	  (brightness-down))
	 ;; for fun
	 (else
	  (display (string-length bufstr))))
	(loop)))))

(define (create-run-dir d)
  "Create a directory where the server keeps its socket.
If the directory already exists, do nothing. Otherwise, an error is thrown."
  (catch 'system-error
    (lambda ()
      (mkdir d #o755))
    (lambda (key x y msg errno)
      (unless (= (car errno) EEXIST)
	(throw 'system-error (format "mkdir: ~A" msg))))))

(define (signal-handler sig)
  "Clean-up signal handler."
  (close-port sock)
  (delete-file sockpath)
  (exit 0))

(define (main)
  (let ((s (socket PF_UNIX SOCK_DGRAM 0)))
    (when (access? sockpath F_OK)
      (begin
	(display "Socket file already exists. Is the server already running?\n")
	(close-port s)
	(exit 1)))
    (set! sock s)
    (sigaction SIGTERM signal-handler)
    (sigaction SIGINT  signal-handler)
    (create-run-dir "/run/asus")
    (bind sock AF_UNIX sockpath)
    (chmod sockpath #o777)
    (server-loop sock)))

(main)
