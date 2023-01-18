(defpackage connect-any-service
  (:use :cl :connect-any-service.head :connect-any-service.server :connect-any-service.dbo :str)
  (:export
   :start-s
   :restart-s
   :stop-s))
(in-package :connect-any-service)

(defun generate-json (data &key (code 200) (msg "成功"))
  (to-json-a
   `(("code" . ,code)
     ("msg" . ,msg)
     ("data" . ,data))))

(defroute "/"
  (lambda (data)
    (declare (ignore data))
    (generate-json "Hello")))

;; User
(defroute "/user/adduser"
  (lambda (data)
    (let ((device (assoc-value data "device"))
          (user-name (assoc-value data "name")))
      (let ((user (register-user user-name)))
        (register-device (assoc-value device "id")
                         (assoc-value device "type")
                         (assoc-value device "name")
                         user)
        (generate-json t)))))

(defun start-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun restart-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun stop-s ()
  (server-stop))

(in-package :cl-user)
