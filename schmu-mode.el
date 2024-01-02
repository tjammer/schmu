;;; schmu-mode.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 Tobias Mock
;;
;; Homepage: https://codeberg.org/tjammer/schmu
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defconst schmu-keywords-regexp
  (rx symbol-start
      (or "fun" "type" "if" "then" "else" "elseif" "and" "or" "external"
          "match" "with" "module" "module_type" "signature")
      symbol-end)
  "Schmu language keywords.")

(defconst schmu-constants-regexp
  (rx symbol-start
      (or "true" "false")
      symbol-end)
  "Schmu language constants.")

(defconst schmu-types-regexp
  (rx symbol-start
      (or "int" "unit" "bool" "float" "i32" "u8" "f32")
      symbol-end)
  "Schmu language builtin types.")

(defconst schmu-function-pattern
  (rx symbol-start "fun" (1+ space) (group (seq (any letter ?_) (* (any word ?_))))))

(defconst schmu-variable-pattern
  (rx symbol-start (group (seq (any letter ?_) (* (any word ?_)))) (1+ space)
      (or (seq "=" (1+ space))
          (seq (\:) (* anything) "=" (1+ space)))))

(defvar schmu-font-lock-keywords
  `((,schmu-function-pattern 1 font-lock-function-name-face)
    (,schmu-variable-pattern 1 font-lock-variable-name-face)
    (,schmu-keywords-regexp . font-lock-keyword-face)
    (,schmu-constants-regexp . font-lock-constant-face)
    (,schmu-types-regexp . font-lock-type-face))
  "Schmu keywords highlighting.")

;;;###autoload
(define-derived-mode schmu-mode prog-mode "Schmu"
  "Major mode for editing Schmu."
  ;; Operators
  (dolist (i '(?+ ?- ?* ?/ ?= ?< ?>))
    (modify-syntax-entry i "." schmu-mode-syntax-table))

  ;; Strings
  (modify-syntax-entry ?\' "\"" schmu-mode-syntax-table)
  (modify-syntax-entry ?\" "\"" schmu-mode-syntax-table)
  (modify-syntax-entry ?\\ "\\" schmu-mode-syntax-table)

  ;; Comments
  (modify-syntax-entry ?#  "<" schmu-mode-syntax-table)
  (modify-syntax-entry ?\n ">"    schmu-mode-syntax-table)

  (setq font-lock-defaults '((schmu-font-lock-keywords)))

  (set (make-local-variable 'comment-start) "#"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smu\\'" . schmu-mode))

(provide 'schmu-mode)
;;; schmu-mode.el ends here
