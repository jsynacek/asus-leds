;; Client for asus-leds-server.scm
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

;; Notes:
;; The server accepts either 'up', or 'down', which increases or decreases
;; keyboard brightness by 1.
;;
;; Code:

(use-modules (rnrs io ports))

(define (die msg)
  (put-string (current-error-port) msg)
  (exit 1))

(define (get-arg)
  (let ((arg (cdr (command-line))))
    (if (null? arg)
	(die "One argument (command) is expected.\n")
	(car arg))))

(let ((sock (socket PF_UNIX SOCK_DGRAM 0))
      (sockpath "/run/asus/asus-leds.socket"))
  (unless (access? sockpath R_OK)
    (die "Socket is unreadable, is the server running?\n"))
  (sendto sock (get-arg) AF_UNIX sockpath))
