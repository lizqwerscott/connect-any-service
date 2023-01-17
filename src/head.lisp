(defpackage connect-any-service.head
  (:import-from :jonathan :to-json)
  (:import-from :flexi-streams :octets-to-string)
  (:import-from :flexi-streams :string-to-octets)
  (:use :cl :clack :yason :s-base64 :local-time)
  (:export
   :to-json-a
   :assoc-value
   :stream-recive-string
   :load-json-file
   :encode-str-base64))
(in-package :connect-any-service.head)

(setf yason:*parse-object-as* :alist)

(defun to-json-a (alist)
  (to-json alist :from :alist))

(defun assoc-value (plist key)
  (cdr (assoc key plist :test #'string=)))

(defun stream-recive-string (stream length)
  (let ((result (make-array length :element-type '(unsigned-byte 8))))
    (read-sequence result stream)
    (octets-to-string result)))

(defun load-json-file (path)
  (with-open-file (in path :direction :input :if-does-not-exist :error)
    (multiple-value-bind (s) (make-string (file-length in))
      (read-sequence s in)
      (parse s))))

(defun encode-str-base64 (str)
  (with-output-to-string (out)
    (encode-base64-bytes (string-to-octets str)
                         out)))

(in-package :cl-user)
