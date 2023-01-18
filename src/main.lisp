(defpackage connect-any-service
  (:import-from :mito :object-id)
  (:import-from :alexandria :if-let)
  (:use :cl :connect-any-service.head :connect-any-service.server :connect-any-service.dbo :str)
  (:export
   :start-s
   :restart-s
   :stop-s))
(in-package :connect-any-service)

(defstruct clipboard-data
  (data "")
  (need-update-device nil))

(defvar *clipboard-data* (make-hash-table :test #'equal))

(mapcar #'(lambda (user)
            (setf (gethash (object-id user) *clipboard-data*)
                  (make-clipboard-data)))
        (all-users))

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
          (if-let (data (gethash (mito:object-id user) *clipboard-data*))
            data
            (setf (gethash (object-id user) *clipboard-data*)
                  (make-clipboard-data)))
          (register-device (assoc-value device "id")
                           (assoc-value device "type")
                           (assoc-value device "name")
                           user)
          (generate-json t)))))

;; Message
(defroute "/message/addmessage"
    (lambda (data)
      (let ((gid (assoc-value data '("device" "id")))
            (message (assoc-value data "message")))
        (if-let (device (search-device gid))
          (let ((user (device-get-user device)))
            (format t "New Clipboard data: ~A~%" (assoc-value message "data"))
            ;; 更新剪切板信息
            (setf (clipboard-data-data
                   (gethash (object-id user)
                            *clipboard-data*))
                  (assoc-value message "data"))
            ;; 将需要更新的设备放入
            (setf (clipboard-data-need-update-device
                   (gethash (object-id user)
                            *clipboard-data*))
                  (mapcar #'device-get-gid
                          (user-devices user device)))
            (generate-json t))
          (generate-json :false
                         :code 403
                         :msg "此设备没有被注册")))))

(defroute "/message/updatebase"
    (lambda (data)
      (if-let (device (search-device
                       (assoc-value data '("device" "id"))))
        (let* ((clipboard-data (gethash (object-id (device-get-user device))
                                        *clipboard-data*))
               (devices (clipboard-data-need-update-device clipboard-data)))
          (if (find (device-get-gid device) devices :test #'string=)
              (progn
                (setf (clipboard-data-need-update-device clipboard-data)
                      (remove (device-get-gid device) devices :test #'string=))
                (generate-json `(("type" . "text")
                                 ("data" . ,(clipboard-data-data clipboard-data))
                                 ("date" . "114514"))))
              (generate-json `(("type" . "none")
                               ("data" . "")
                               ("date" . "114514")))))
        (generate-json `(("type" . "none")
                         ("data" . "")
                         ("date" . "114514"))))))

(defun start-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun restart-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun stop-s ()
  (server-stop))

(in-package :cl-user)
