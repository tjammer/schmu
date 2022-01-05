;;; schmu-mode.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Tobias Mock
;;
;; Author: Tobias Mock <https://github.com/jao2lr>
;; Maintainer: Tobias Mock <tobias.jammer@de.bosch.com>
;; Created: October 26, 2021
;; Modified: October 26, 2021
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/jao2lr/schmu-mode
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
      (or "fn" "type" "if" "then" "else" "for"
          "external" "end")
      symbol-end)
  "Schmu language keywords.")

(defconst schmu-constants-regexp
  (rx symbol-start
      (or "true" "false")
      symbol-end)
  "Schmu language constants.")

(defconst schmu-builtin-regexp
  (rx symbol-start
      (or "int" "unit" "bool")
      symbol-end)
  "Schmu language builtin types.")




(defvar schmu-font-lock-keywords
  `((,schmu-keywords-regexp . font-lock-keyword-face)
    (,schmu-constants-regexp . font-lock-constant-face)
    (,schmu-builtin-regexp . font-lock-builtin-face))
  "Schmu keywords highlighting.")

;;;###autoload
(define-derived-mode schmu-mode prog-mode "Schmu"
  "Major mode for editing Schmu."

  ;; syntax table
  (modify-syntax-entry ?- ". 12" schmu-mode-syntax-table)
  (modify-syntax-entry ?\n ">" schmu-mode-syntax-table)
  (modify-syntax-entry ?\\ "\\" schmu-mode-syntax-table)
  (modify-syntax-entry ?+ "." schmu-mode-syntax-table)
  (modify-syntax-entry ?* "." schmu-mode-syntax-table)
  (modify-syntax-entry ?/ "." schmu-mode-syntax-table)
  (modify-syntax-entry ?> "." schmu-mode-syntax-table)
  (modify-syntax-entry ?< "." schmu-mode-syntax-table)
  (modify-syntax-entry ?= "." schmu-mode-syntax-table)

  (setq font-lock-defaults '((schmu-font-lock-keywords)))

  (set (make-local-variable 'comment-start) "--"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smu\\'" . schmu-mode))

(provide 'schmu-mode)
;;; schmu-mode.el ends here
