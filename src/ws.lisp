(defpackage connect-any-service.ws
  (:use :cl :connect-any-service.head :lzputils.json :connect-any-service.dbo)
  (:export
   :broadcast-clipboard

   :start-ws
   :stop-ws))
(in-package :connect-any-service.ws)

(defvar *connections-to-device* (make-hash-table))
(defvar *device-to-connections* (make-hash-table :test #'equal))

(defun new-device-connection (socket device-id)
  (when (search-device device-id)
    (setf (gethash socket
                   *connections-to-device*)
          device-id)
    (setf (gethash device-id
                   *device-to-connections*)
          socket)))

(defun device-close-connection (socket)
  (remhash (gethash socket *connections-to-device*)
           *device-to-connections*)
  (remhash socket *connections-to-device*))

(defun broadcast-clipboard (device data)
  (mapcar #'(lambda (device-id)
              (let ((socket (gethash device-id *device-to-connections*)))
                (format t "send socket~%")
                (pws:send socket
                          (to-json-a `(("type" . "text")
                                       ("data" . ,data)
                                       ("date" . "114514"))))))
          (mapcar #'device-get-gid
                  (user-devices (device-get-user device)
                                device))))

(pws:define-resource "/clipboard"
  :open (lambda (websocket)
          (log:info "new connection"))
  :message (lambda (websocket message)
             (let ((json (parse message)))
               (when (string= "init" (assoc-value json "type"))
                 (new-device-connection websocket
                                        (assoc-value json
                                                     (list "device" "id")))
                 (format t
                         "Device: ~A send init message: ~A~%"
                         (gethash websocket *connections-to-device*)
                         message)))
             (log:info (format nil "~A recive message: ~A~%" websocket message)))
  :error (lambda (socket condition)
           ;; echo error to websocket
           (device-close-connection socket)
           (log:error (format nil "~A" condition)))
  :close (lambda (socket)
           (device-close-connection socket)
           (log:info "Socket leaving error server.")))

(setq pws:*debug-on-error* nil)

(defvar *ws-server* nil)

(defun start-ws (&optional (port 8687))
  (setf *ws-server*
        (pws:server port)))

(defun stop-ws ()
  (pws:close *ws-server*))

(in-package :cl-user)
