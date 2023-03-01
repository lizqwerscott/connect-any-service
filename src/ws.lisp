(defpackage connect-any-service.ws
  (:import-from :babel :octets-to-string)
  (:use :cl :connect-any-service.head :lzputils.json :connect-any-service.dbo)
  (:export
   :broadcast-clipboard))
(in-package :connect-any-service.ws)

(defun send-to-add-clipboard (data)
  (handler-case
      (multiple-value-bind (body status respone-headers uri stream)
          (dexador:post "http://127.0.0.1:8685/addmessage"
                    :headers '(("Content-Type" . "application/json"))
                    :content (to-json-a data))
        (declare (ignorable status uri stream))
        (let ((res body))
          (when (not (stringp res))
            (setf res (octets-to-string res)))
          (parse res)))
    (error (c)
      (log:error "~A post error: ~A" url c)
      nil)))

(defun broadcast-clipboard (device data)
  (send-to-add-clipboard
   `(("ids" . ,(mapcar #'device-get-gid
                       (user-devices (device-get-user device)
                                     device)))
     ("data" . ,data))))

(in-package :cl-user)
