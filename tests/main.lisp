(defpackage connect-any-service/tests/main
  (:use :cl
        :connect-any-service
        :rove))
(in-package :connect-any-service/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :connect-any-service)' in your Lisp.

(deftest test-target-1
  (testing "should (= 1 1) to be true"
    (ok (= 1 1))))
