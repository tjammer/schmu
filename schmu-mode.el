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
      (or "fun" "type" "if" "then" "else" "and" "or" "external" "let"
          "match" "with" "module" "signature" "val" "functor"
          "use" "import" "mov" "mut" "bor" "rec" "main")
      symbol-end)
  "Schmu language keywords.")

(defconst schmu-constants-regexp
  (rx symbol-start
      (or "true" "false")
      symbol-end)
  "Schmu language constants.")

(defconst schmu-types-regexp
  (rx symbol-start
      (or "int" "unit" "bool" "float" "i32" "u8" "f32" "i8" "i16" "u16" "u32")
      symbol-end)
  "Schmu language builtin types.")

(defconst schmu-function-pattern
  (rx symbol-start "fun" (1+ space) (? (seq "rec" (1+ space)))
      (group (seq (any lower ?_) (* (any word ?_))))))

(defconst schmu-call-pattern
  (rx symbol-start (group (seq (any lower ?_) (* (any word ?_))))
      (* space) "("))

(defconst schmu-type-param-pattern
  (rx symbol-start (group (seq (any lower ?_) (* (any word ?_))))
      (* space) "["))

(defconst schmu-module-pattern
  (rx symbol-start (or "module" "module type" "functor" "use") (1+ space)
      (group (seq (any word ?_) (* (any word ?_))))))

(defconst schmu-path-pattern
  (rx symbol-start (group (seq (any word ?_) (* (any word ?_))) ?/)))

(defconst schmu-fixed-array-pattern
  (rx symbol-start (group (seq ?# (any word ?_) (* (any word ?_)))) ?\[))

(defconst schmu-upcase-pattern
  (rx symbol-start (group (seq (any upper) (* (any word ?_))))))

(defconst schmu-variable-pattern
  (rx symbol-start "let" (1+ space) (? (seq "mut" (1+ space)))
      (group (seq (any lower ?_) (* (any word ?_)) (opt (or ?& ?!))))
      (1+ space)))

;; (defgroup schmu-faces nil
;;   "Special faces for the Schmu mode."
;;   :group 'schmu)

(defface schmu-font-lock-module-face
  '((t (:inherit font-lock-type-face))); backward compatibility
  "Face description for modules and module paths.")

(defvar schmu-font-lock-keywords
  `((,schmu-keywords-regexp . font-lock-keyword-face)
    (,schmu-constants-regexp . font-lock-constant-face)
    (,schmu-module-pattern 1 font-lock-type-face)
    (,schmu-fixed-array-pattern 1 font-lock-constant-face)
    (,schmu-function-pattern 1 font-lock-function-name-face)
    (,schmu-types-regexp . font-lock-type-face)
    (,schmu-variable-pattern 1 font-lock-variable-name-face)
    (,schmu-call-pattern 1 font-lock-function-name-face)
    (,schmu-type-param-pattern 1 font-lock-type-face)
    (,schmu-upcase-pattern 1 font-lock-constant-face)
    (,schmu-path-pattern 1 'schmu-font-lock-module-face))
  "Schmu keywords highlighting.")

;; Indentation function. Adapted from zig-mode
(defconst schmu-electric-indent-chars
  '(?\; ?\, ?\) ?\] ?\}))

(defcustom schmu-indent-offset 2
  "Indent Schmu code by this number of spaces."
  :type 'integer
  :safe #'integerp)

(defun schmu-currently-in-str () (nth 3 (syntax-ppss)))
(defun schmu-start-of-current-str-or-comment () (nth 8 (syntax-ppss)))

(defun schmu-skip-backwards-past-whitespace-and-comments ()
  (while (or
          ;; If inside a comment, jump to start of comment.
          (let ((start (schmu-start-of-current-str-or-comment)))
            (and start
                 (not (schmu-currently-in-str))
                 (goto-char start)))
          ;; Skip backwards past whitespace and comment end delimiters.
          (/= 0 (skip-syntax-backward " >")))))

(defun schmu-paren-nesting-level () (nth 0 (syntax-ppss)))

(defun schmu-mode-indent-line ()
  (interactive)
  ;; First, calculate the column that this line should be indented to.
  (let ((indent-col
         (save-excursion
           (back-to-indentation)
           (let* (;; paren-level: How many sets of parens (or other delimiters)
                  ;;   we're within, except that if this line closes the
                  ;;   innermost set(s) (e.g. the line is just "}"), then we
                  ;;   don't count those set(s).
                  (paren-level
                   (save-excursion
                     (while (looking-at "[]})]") (forward-char))
                     (schmu-paren-nesting-level)))
                  ;; prev-block-indent-col: If we're within delimiters, this is
                  ;; the column to which the start of that block is indented
                  ;; (if we're not, this is just zero).
                  (prev-block-indent-col
                   (if (<= paren-level 0) 0
                     (save-excursion
                       (while (>= (schmu-paren-nesting-level) paren-level)
                         (backward-up-list)
                         (back-to-indentation))
                       (current-column))))
                  ;; base-indent-col: The column to which a complete expression
                  ;;   on this line should be indented.
                  (base-indent-col
                   (if (<= paren-level 0)
                       prev-block-indent-col
                     (or (save-excursion
                           (backward-up-list)
                           (forward-char)
                           (and (not (looking-at " *\\(//[^\n]*\\)?\n"))
                                (current-column)))
                         (+ prev-block-indent-col schmu-indent-offset))))
                  ;; is-expr-continuation: True if this line continues an
                  ;; expression from the previous line, false otherwise.
                  ;; (is-expr-continuation
                  ;;  (and
                  ;;   (not (looking-at "[]});]\\|else"))
                  ;;   (save-excursion
                  ;;     (schmu-skip-backwards-past-whitespace-and-comments)
                  ;;     (when (> (point) 1)
                  ;;       (backward-char)
                  ;;       (or (schmu-currently-in-str)
                  ;;           (not (looking-at "[,;([{}]")))))))
                  )
             ;; Now we can calculate indent-col:
             base-indent-col
             ;; (if is-expr-continuation
             ;;     (+ base-indent-col schmu-indent-offset)
             ;;   base-indent-col)
             ))))
    ;; If point is within the indentation whitespace, move it to the end of the
    ;; new indentation whitespace (which is what the indent-line-to function
    ;; always does).  Otherwise, we don't want point to move, so we use a
    ;; save-excursion.
    (if (<= (current-column) (current-indentation))
        (indent-line-to indent-col)
      (save-excursion (indent-line-to indent-col)))))

(defun schmu-indent-whole-buffer ()
  "Indent the entire buffer without affecting point or mark."
  (interactive)
  (save-excursion
    (save-restriction
      (indent-region (point-min) (point-max)))))

;;;###autoload
(define-derived-mode schmu-mode prog-mode "Schmu"
  "Major mode for editing Schmu."
  ;; Operators
  (dolist (i '(?+ ?- ?* ?/ ?= ?< ?>))
    (modify-syntax-entry i "." schmu-mode-syntax-table))

  ;; Strings
  (modify-syntax-entry ?\" "\"" schmu-mode-syntax-table)
  (modify-syntax-entry ?\\ "\\" schmu-mode-syntax-table)

  ;; Comments
  (modify-syntax-entry ?- "_. 12" schmu-mode-syntax-table)
  (modify-syntax-entry ?\n ">"    schmu-mode-syntax-table)

  (modify-syntax-entry ?# "_" schmu-mode-syntax-table)

  (setq font-lock-defaults '(schmu-font-lock-keywords))

  (set (make-local-variable 'comment-start) "--")

  (setq-local electric-indent-chars
              (append schmu-electric-indent-chars
                      (and (boundp 'electric-indent-chars)
                           electric-indent-chars)))
  (setq-local indent-line-function 'schmu-mode-indent-line)

  (add-hook 'before-save-hook #'schmu-indent-whole-buffer nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smu\\'" . schmu-mode))

(provide 'schmu-mode)
;;; schmu-mode.el ends here
