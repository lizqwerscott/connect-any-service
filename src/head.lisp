(defpackage connect-any-service.head
  ;; (:import-from :flexi-streams :octets-to-string)
  ;; (:import-from :flexi-streams :string-to-octets)
  (:import-from :babel :octets-to-string)
  (:import-from :babel :string-to-octets)
  (:use :cl :clack :yason :s-base64 :local-time)
  (:export

   :stream-recive-string
   :encode-str-base64

   :send-to-apple-clipboard))
(in-package :connect-any-service.head)

(defun stream-recive-string (stream length)
  (let ((result (make-array length :element-type '(unsigned-byte 8))))
    (read-sequence result stream)
    (octets-to-string result)))

(defun encode-str-base64 (str)
  (with-output-to-string (out)
    (encode-base64-bytes (string-to-octets str)
                         out)))

(defun send-to-apple-clipboard (apple-device-id data)
  (handler-case
      (dexador:get
       (quri:make-uri :defaults (format nil "https://api.day.app/~A/Clipboard/" apple-device-id)
                      :query `(("autoCopy" . 1)
                               ("copy" . ,data))))
    (error (c)
      (log:error c))))

(in-package :cl-user)
