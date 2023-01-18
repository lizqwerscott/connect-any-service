(defpackage connect-any-service.dbo
  (:use :cl :mito :sxql :connect-any-service.head)
  (:export
   ;; User
   :register-user
   :logout-user
   ;; Device
   :register-device
   :delete-device
   ))
(in-package :connect-any-service.dbo)

(defvar *db*
  (connect-toplevel :mysql
                    :database-name "connectany"
                    :host "124.222.100.66"
                    :username "connectany"
                    :password "12138"))

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
(ensure-table-exists 'user)
(ensure-table-exists 'device)

(defun search-user (name)
  (find-dao 'user :name name))

(defun register-user (name)
  (if-return (search-user name)
    (create-dao 'user :name name)))

(defmethod logout-user ((user user))
  ;; 注销用户, 同时要注销用户的所有设备
  (delete-by-values 'device :user user)
  (delete-dao user))

(defun search-device (gid)
  (find-dao 'device :gid gid))

(defmethod register-device (gid type name (user user))
  (if-return (search-device gid)
    (create-dao 'device :gid gid :type type :name name :user user)))

(defmethod delete-device ((device device))
  (delete-dao device))

(defun test ()
  (register-device "haha-sadas-asdasd" "Android" "meizu" (search-user "lizqwer"))
  (register-device "babab-ads-adsad-adsad" "Window" "lzb-dsad" (search-user "lizqwer")))

(in-package :cl-user)
