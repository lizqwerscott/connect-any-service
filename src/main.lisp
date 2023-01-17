(defpackage connect-any-service
  (:use :cl :connect-any-service.head :connect-any-service.server :str)
  (:export
   :start-s
   :restart-s
   :stop-s))
(in-package :connect-any-service)

(defun generate-json (data &optional (is-ok 200))
  (to-json-a
   `(("msg" . ,(if is-ok
                   200
                   400))
     ("result" . ,data))))

(defroute "/"
  (lambda (data)
    (declare (ignore data))
    (generate-json "Hello")))

;; User
(defroute "/user/adduser"
  (lambda (data)
    ()))


(defun start-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun restart-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun stop-s ()
  (server-stop))

(in-package :cl-user)
