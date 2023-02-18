(defpackage connect-any-service
  (:import-from :mito :object-id)
  (:import-from :alexandria :if-let)
  (:use :cl :connect-any-service.head :connect-any-service.server :connect-any-service.dbo :str)
  (:export
   :start-s
   :restart-s
   :stop-s))
(in-package :connect-any-service)

(defvar *config-apple-list* #P"~/.connectanys/data/apple.json")

(defstruct clipboard-data
  (data "")
  (need-update-device nil))

(defvar *clipboard-data* (make-hash-table :test #'equal))

(mapcar #'(lambda (user)
            (setf (gethash (object-id user) *clipboard-data*)
                  (make-clipboard-data)))
        (all-users))

;; 是一个列表, 每项都是一个新命令, 命令格式("要做的事情" "哪台设备" 其他参数)
(defvar *hostmanager* nil)

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
        (format t "add user: ~A~%" data)
        (let ((user (register-user user-name)))
          (if-return (gethash (mito:object-id user) *clipboard-data*)
            (setf (gethash (object-id user) *clipboard-data*)
                  (make-clipboard-data)))
          (register-device (assoc-value device "id")
                           (assoc-value device "type")
                           (assoc-value device "name")
                           user)
          (generate-json t)))))

(defun for-apple (message name)
  (when (string= "OxygenLost" name)
    (handler-case
        (dolist (i (assoc-value (load-json-file
                                 (truename *config-apple-list*))
                                "applelist"))
          (send-to-apple-clipboard i message))
      (error (c)
        (format t "Not have file\n")
        (log:error "Not have file")))))

;; Message
(defroute "/message/addmessage"
    (lambda (data)
      (let ((gid (assoc-value data '("device" "id")))
            (message (assoc-value data "message")))
        (format t "add message: ~A~%" data)
        (if-let (device (search-device gid))
          (let ((user (device-get-user device)))
            (format t "New Clipboard data: ~A~%" (assoc-value message "data"))
            ;; 更新剪切板信息
            (setf (clipboard-data-data
                   (gethash (object-id user)
                            *clipboard-data*))
                  (assoc-value message "data"))
            ;; 为特定苹果用户添加
            (when (not (string= "iOS" (assoc-value data '("device" "type"))))
              (for-apple (assoc-value message "data") (user-name user)))
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
              (if-let (command (find (device-get-gid device)
                                     *hostmanager*
                                     :key #'second
                                     :test #'string=))
                (progn
                  (setf *hostmanager* nil)
                  (generate-json `(("type" . "manager")
                                   ("data" . ,(format nil "~A" (first command)))
                                   ("date" . ,(format nil "~A" (third command))))))
                (generate-json `(("type" . "none")
                                 ("data" . "")
                                 ("date" . "114514"))))))
        (generate-json `(("type" . "none")
                         ("data" . "")
                         ("date" . "114514"))
                       :code 404
                       :msg "设备未找到"))))

;; Manager
(defroute "/manager/hostmanager"
  (lambda (data)
    (if-let ((device (search-device
                      (assoc-value data '("device" "id"))))
             (to-device (search-device
                         (assoc-value data '("todevice" "id")))))
      (progn
        (setf *hostmanager*
             (append *hostmanager*
                     (list
                      (list "enablehost"
                            (device-get-gid to-device)
                            (assoc-value data "state")))))
        (generate-json t))
      (generate-json nil
                     :code 404
                     :msg "设备未找到"))))

(defun start-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun restart-s (&optional (port 8686))
  (server-start :address "0.0.0.0" :port port :server :woo))

(defun stop-s ()
  (server-stop))

(in-package :cl-user)
