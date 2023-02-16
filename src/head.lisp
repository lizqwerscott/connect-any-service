(defpackage connect-any-service.head
  (:import-from :uiop :run-program)
  (:import-from :jonathan :to-json)
  ;; (:import-from :flexi-streams :octets-to-string)
  ;; (:import-from :flexi-streams :string-to-octets)
  (:import-from :babel :octets-to-string)
  (:import-from :babel :string-to-octets)
  (:use :cl :clack :yason :s-base64 :local-time)
  (:export
   :to-json-a

   :if-return
   :when-return

   :assoc-value
   :assoc-value-l
   :assoc-v

   :stream-recive-string
   :load-json-file
   :encode-str-base64

   :run-shell
   :send-to-apple-clipboard))
(in-package :connect-any-service.head)

(setf yason:*parse-object-as* :alist)

(defun to-json-a (alist)
  (to-json alist :from :alist))

(defun run-shell (program)
  (run-program program))

(defmacro if-return (body &body (then-body))
  (let ((g (gensym)))
    `(let ((,g ,body))
      (if ,g
          ,g
          ,then-body))))

(defmacro when-return (body)
  (let ((g (gensym)))
    `(let ((,g ,body))
       (when ,g
         ,g))))

(defun assoc-value (plist keys)
  (if (listp keys)
      (if keys
          (assoc-value (cdr
                        (assoc (car keys) plist :test #'string=))
                       (cdr keys))
          plist)
      (cdr (assoc keys plist :test #'string=))))

(defun assoc-value-l (plist keys)
  (when (listp keys)
    (mapcar #'(lambda (key)
                (assoc-value plist key))
            keys)))

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

(defun send-to-apple-clipboard (apple-device-id data)
  (handler-case
      (dexador:get
       (quri:make-uri :defaults (format nil "https://api.day.app/~A/Clipboard/" apple-device-id)
                      :query `(("autoCopy" . 1)
                               ("copy" . ,data))))
    (error (c)
      (log:error c))))

(in-package :cl-user)
