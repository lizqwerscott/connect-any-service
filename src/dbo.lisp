(defpackage connect-any-service.dbo
  (:use :cl :mito :sxql :connect-any-service.head)
  (:export
   ;; User
   :all-users
   :register-user
   :search-user
   :logout-user
   :user-devices
   :user-name
   ;; Device
   :device-get-user
   :device-get-gid
   :register-device
   :search-device
   :delete-device))
(in-package :connect-any-service.dbo)

(defvar *config-dir* (truename #P"~/.connectanys/data/"))

(defun connect-dbi ()
  (let ((path *config-dir*))
    (ensure-directories-exist path)
    (dbi:connect-cached :sqlite3
                        :database-name (merge-pathnames "data.db"
                                                        path))))
(let ((path *config-dir*))
  (ensure-directories-exist path)
  (run-shell (format nil
                     "touch ~A"
                     (namestring
                      (merge-pathnames "data.db"
                                       path)))))
;; 定义表
(deftable user ()
  ((name :col-type (:varchar 20)))
  (:unique-keys name)
  (:conc-name user-))

(deftable device ()
  ((gid :col-type (:varchar 100))
   (type :col-type (:varchar 30))
   (name :col-type (:varchar 30))
   (user :col-type user))
  (:unique-keys gid)
  (:conc-name device-))

;; 确保表被创建
(let ((mito:*connection* (connect-dbi)))
  (ensure-table-exists 'user)
  (ensure-table-exists 'device))

(defun all-users ()
  (let ((mito:*connection* (connect-dbi)))
    (select-dao 'user)))

(defun search-user (name)
  (let ((mito:*connection* (connect-dbi)))
    (find-dao 'user :name name)))

(defun register-user (name)
  (let ((mito:*connection* (connect-dbi)))
   (if-return (search-user name)
    (create-dao 'user :name name))))

(defmethod logout-user ((user user))
  ;; 注销用户, 同时要注销用户的所有设备
  (let ((mito:*connection* (connect-dbi)))
    (delete-by-values 'device :user user)
    (delete-dao user)))

(defmethod user-devices ((user user) &optional (remove-device nil))
  (let ((mito:*connection* (connect-dbi)))
   (remove-if #'(lambda (device)
                 (string= (device-gid device)
                          (device-gid remove-device)))
             (select-dao 'device
                 (includes 'user)))))

(defun search-device (gid)
  (let ((mito:*connection* (connect-dbi)))
    (find-dao 'device :gid gid)))

(defmethod search-device-un (name (user user))
  (let ((mito:*connection* (connect-dbi)))
    (find-dao 'device :name name :user user)))

(defmethod register-device (gid type name (user user))
  (let ((mito:*connection* (connect-dbi)))
    (let ((device (search-device-un name user)))
      (when device
        (delete-device device))
      (create-dao 'device :gid gid :type type :name name :user user))))

(defmethod delete-device ((device device))
  (let ((mito:*connection* (connect-dbi)))
    (delete-dao device)))

(defmethod device-get-user ((device device))
  (let ((mito:*connection* (connect-dbi)))
    (device-user device)))

(defmethod device-get-gid ((device device))
  (let ((mito:*connection* (connect-dbi)))
    (device-gid device)))

(defun test ()
  (register-device "haha-sadas-asdasd" "Android" "meizu" (search-user "lizqwer"))
  (register-device "babab-ads-adsad-adsad" "Window" "lzb-dsad" (search-user "lizqwer")))

(in-package :cl-user)
