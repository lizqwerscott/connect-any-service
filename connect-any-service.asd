(defsystem "connect-any-service"
  :version "0.1.0"
  :author "lizqwer scott"
  :license "GPL"
  :depends-on ("clack" "local-time" "yason" "jonathan" "str" "s-base64" "flexi-streams" "log4cl" "mito" "alexandria" "dexador" "quri")
  :components ((:module "src"
                :components
                ((:file "head")
                 (:file "dbo")
                 (:file "server")
                 (:file "main"))))
  :description ""
  :in-order-to ((test-op (test-op "connect-any-service/tests"))))

(defsystem "connect-any-service/tests"
  :author ""
  :license ""
  :depends-on ("connect-any-service"
               "rove")
  :components ((:module "tests"
                :components
                ((:file "main"))))
  :description "Test system for connect-any-service"
  :perform (test-op (op c) (symbol-call :rove :run c)))
