;;; schmu-mode.el --- Defines a major mode for Schmu -*- lexical-binding: t; -*-

;; Copyright (c) 2019 Adam Schwalm / Tobias Mock

;; Author: Adam Schwalm <adamschwalm@gmail.com>
;; Modified: Tobias Mock
;; Version: 0.1.0
;; URL: https://github.com/ALSchwalm/janet-mode
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Code

(require 'cl-lib)

(defgroup schmu nil
  "A mode for Schmu"
  :group 'languages)

(defvar schmu-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; Comments start with a '#' and end with a newline
    (modify-syntax-entry ?- "_. 12" table)
    (modify-syntax-entry ?\n ">" table)

    ;; For keywords, make the ':' part of the symbol class
    (modify-syntax-entry ?: "_" table)
    (modify-syntax-entry ?# "_" table)

    ;; Backtick is a string delimiter
    (modify-syntax-entry ?` "\"" table)

    ;; Other chars that are allowed in symbols
    (modify-syntax-entry ?? "_" table)
    (modify-syntax-entry ?! "_" table)
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?@ "_" table)

    table))

(defconst schmu-symbol '(one-or-more (or (syntax word) (syntax symbol)))
  "Regex representation of a Schmu symbol.
A Schmu symbol is a collection of words or symbol characters as determined by
the syntax table.  This allows us to keep things like '-' in the symbol part of
the syntax table, so `forward-word' works as expected.")

(defconst schmu-start-of-sexp '("(" (zero-or-more (or space "\n"))))

(defconst schmu-macro-decl-forms '("defmacro" "defmacro-"))

(defconst schmu-normal-function-decl-forms '("defn"))

(defconst schmu-function-decl-forms
  `(,@schmu-normal-function-decl-forms ,@schmu-macro-decl-forms "varfn" "fn"))

(defconst schmu-function-pattern
  (rx-to-string `(sequence ,@schmu-start-of-sexp
                  (or ,@schmu-function-decl-forms)
                  (one-or-more space) (group ,schmu-symbol) symbol-end))
  "The regex to identify schmu function names.")

(defconst schmu-var-decl-forms
  '("var" "var-" "def" "def-" "defglobal" "varglobal" "default" "dyn" "type"))

(defconst schmu-variable-declaration-pattern
  (rx-to-string `(sequence ,@schmu-start-of-sexp
                  (or ,@schmu-var-decl-forms)
                  (one-or-more space) (group ,schmu-symbol)))
  "The regex to identify variable declarations.")

(defconst schmu-keyword-pattern
  (rx-to-string `(group symbol-start (or ":" "#") ,schmu-symbol)))

(defconst schmu-error-pattern
  (rx-to-string `(sequence ,@schmu-start-of-sexp (group symbol-start "error" symbol-end))))

(defconst schmu-constant-pattern
  (rx-to-string `(group symbol-start (group (or "true" "false" "nil")) symbol-end)))

(defconst schmu-imenu-generic-expression
  `((nil
     ,(rx-to-string `(sequence line-start ,@schmu-start-of-sexp
                               (or ,@schmu-normal-function-decl-forms)
                               (one-or-more space)
                               (group ,schmu-symbol)))
     1)
    ("Variables"
     ,(rx-to-string `(sequence line-start ,@schmu-start-of-sexp
                               (or ,@schmu-var-decl-forms)
                               (one-or-more space)
                               (group ,schmu-symbol)))
     1)
    ("Macros"
     ,(rx-to-string `(sequence line-start ,@schmu-start-of-sexp
                               (or ,@schmu-macro-decl-forms)
                               (one-or-more space)
                               (group ,schmu-symbol)))
     1)))

(defcustom schmu-special-forms
  `(
    ;; Not all explicitly special forms, but included for
    ;; symmetry with other lisp-modes

    "->"
    "->>"
    "do"
    "fun"
    "def"
    "defn"
    "fn"
    "let"
    "type"
    "if"
    "else"
    "external"
    "do"
    "open"
    "type"
    "match"
    "and"
    "or"
    "rec"
    "signature"

    ,@schmu-var-decl-forms
    ,@schmu-function-decl-forms)
  "List of Schmu special forms."
  :type '(repeat string)
  :group 'schmu)

(defconst schmu-special-form-pattern
  (let ((builtins (cons 'or schmu-special-forms)))
    (rx-to-string `(sequence ,@schmu-start-of-sexp (group ,builtins) symbol-end)))
  "The regex to identify builtin Schmu special forms.")

(defconst schmu-highlights
  `((,schmu-special-form-pattern . (1 font-lock-keyword-face))
    (,schmu-function-pattern . (1 font-lock-function-name-face))
    (,schmu-variable-declaration-pattern . (1 font-lock-variable-name-face))
    (,schmu-error-pattern . (1 font-lock-warning-face))
    (,schmu-constant-pattern . (1 font-lock-constant-face))
    (,schmu-keyword-pattern . (1 font-lock-constant-face))))

;; The schmu-mode indentation logic borrows heavily from
;; racket-mode and clojure-mode

(defcustom schmu-indent 2
  "The number of spaces to add per indentation level."
  :type 'integer
  :group 'schmu)

(defcustom schmu-indent-sequence-depth 1
  "To what depth should `schmu-indent-line' search.
This affects the indentation of forms like '() `() and {},
but not () or ,@().  A zero value disables, giving the normal
indent behavior of Emacs `lisp-mode' derived modes.  Setting this
to a high value can make indentation noticeably slower."
  :type 'integer
  :group 'schmu)

(defun schmu--ppss-containing-sexp (xs)
  "The start of the innermost paren grouping containing the stopping point.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 1))

(defun schmu--ppss-last-sexp (xs)
  "The character position of the start of the last complete subexpression.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 2))

(defun schmu--ppss-string-p (xs)
  "Non-nil if inside a string.
More precisely, this is the character that will terminate the
string, or t if a generic string delimiter character should
terminate it.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 3))

(defun schmu-indent-line ()
  "Indent current line as Schmu code."
  (interactive)
  (pcase (schmu--calculate-indent)
    (`()  nil)
    ;; When point is within the leading whitespace, move it past the
    ;; new indentation whitespace. Otherwise preserve its position
    ;; relative to the original text.
    (amount (let ((pos (- (point-max) (point)))
                  (beg (progn (beginning-of-line) (point))))
              (skip-chars-forward " \t")
              (unless (= amount (current-column))
                (delete-region beg (point))
                (indent-to amount))
              (when (< (point) (- (point-max) pos))
                (goto-char (- (point-max) pos)))))))

(defun schmu--calculate-indent ()
  "Calculate the appropriate indentation for the current Schmu line."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
          (state        nil))
      (schmu--plain-beginning-of-defun)
      (while (< (point) indent-point)
        (setq state (parse-partial-sexp (point) indent-point 0)))
      (let ((strp (schmu--ppss-string-p state))
            (last (schmu--ppss-last-sexp state))
            (cont (schmu--ppss-containing-sexp state)))
        (cond
         (strp                  nil)
         ((and (schmu--looking-at-keyword-p last)
               (not (schmu--line-closes-delimiter-p indent-point)))
          (goto-char (1+ cont)) (+ (current-column) schmu-indent))
         ((and state last cont) (schmu-indent-function indent-point state))
         (cont                  (goto-char (1+ cont)) (current-column))
         (t                     (current-column)))))))

(defun schmu--looking-at-keyword-p (point)
  "Is the given POINT the start of a keyword?"
  (when point
    (save-excursion
      (goto-char point)
      (looking-at (rx-to-string `(group ":" ,schmu-symbol))))))

(defun schmu--plain-beginning-of-defun ()
  "Quickly move to the start of the function containing the point."
  (when (re-search-backward (rx bol (syntax open-parenthesis))
                            nil
                            'move)
    (goto-char (1- (match-end 0)))))

(defun schmu--get-indent-function-method (symbol)
  "Retrieve the indent function for a given SYMBOL."
  (let ((sym (intern-soft symbol)))
    (get sym 'schmu-indent-function)))

(defun schmu-indent-function (indent-point state)
  "Called by `schmu--calculate-indent' to get indent column.
INDENT-POINT is the position at which the line being indented begins.
STATE is the `parse-partial-sexp' state for that position.
There is special handling for:
  - Common Schmu special forms
  - [], @[], {}, and @{} forms"
  (goto-char (schmu--ppss-containing-sexp state))
  (let ((body-indent (+ (current-column) schmu-indent)))
    (forward-char 1)
    (if (schmu--data-sequence-p)
        (progn
          (backward-prefix-chars)
          ;; Don't indent the end of a data list
          (when (schmu--line-closes-delimiter-p indent-point)
            (backward-char 1))
          (current-column))
      (let* ((head   (buffer-substring (point) (progn (forward-sexp 1) (point))))
             (method (schmu--get-indent-function-method head)))
        (cond ((integerp method)
               (schmu--indent-special-form method indent-point state))
              ((eq method 'defun)
               body-indent)
              (method
               (funcall method indent-point state))
              ((string-match (rx bos (or "val" "let" "type" "with-")) head)
               body-indent) ;just like 'defun
              (t
               (schmu--normal-indent state)))))))

(defun schmu--line-closes-delimiter-p (point)
  "Is the line at POINT ending an expression?"
  (save-excursion
    (goto-char point)
    (looking-at (rx (zero-or-more space) (syntax close-parenthesis)))))

(defun schmu--data-sequence-p ()
  "Is the point in a data squence?
Data sequences consist of '(), {}, @{}, [], and @[]."
  (and (< 0 schmu-indent-sequence-depth)
       (save-excursion
         (ignore-errors
           (let ((answer 'unknown)
                 (depth schmu-indent-sequence-depth))
             (while (and (eq answer 'unknown)
                         (< 0 depth))
               (backward-up-list)
               (cl-decf depth)
               (cond ((or
                       ;; a quoted '( ) or quasiquoted `( ) list
                       (and (memq (char-before (point)) '(?\' ?\`))
                            (eq (char-after (point)) ?\())
                       ;; [ ]
                       (eq (char-after (point)) ?\[)
                       ;; { }
                       (eq (char-after (point)) ?{))
                      (setq answer t))
                     (;; unquote or unquote-splicing
                      (and (or (eq (char-before (point)) ?,)
                               (and (eq (char-before (1- (point))) ?,)
                                    (eq (char-before (point))      ?@)))
                           (eq (char-after (point)) ?\())
                      (setq answer nil))))
             (eq answer t))))))

(defun schmu--normal-indent (state)
  "Calculate the correct indentation for a 'normal' Schmu form.
STATE is the `parse-partial-sexp' state for that position."
  (goto-char (schmu--ppss-last-sexp state))
  (backward-prefix-chars)
  (let ((last-sexp nil))
    (if (ignore-errors
          ;; `backward-sexp' until we reach the start of a sexp that is the
          ;; first of its line (the start of the enclosing sexp).
          (while (string-match (rx (not blank))
                               (buffer-substring (line-beginning-position)
                                                 (point)))
            (setq last-sexp (prog1 (point)
                              (forward-sexp -1))))
          t)
        ;; Here we've found an arg before the arg we're indenting
        ;; which is at the start of a line.
        (current-column)
      ;; Here we've reached the start of the enclosing sexp (point is
      ;; now at the function name), so the behavior depends on whether
      ;; there's also an argument on this line.
      (when (and last-sexp
                 (< last-sexp (line-end-position)))
        ;; There's an arg after the function name, so align with it.
        (goto-char last-sexp))
      (current-column))))

(defun schmu--indent-special-form (method indent-point state)
  "Calculate the correct indentation for a 'special' Schmu form.
METHOD is the number of \"special\" args that get extra indent when
    not on the first line. Any additinonl args get normal indent
INDENT-POINT is the position at which the line being indented begins.
STATE is the `parse-partial-sexp' state for that position."
  (let ((containing-column (save-excursion
                             (goto-char (schmu--ppss-containing-sexp state))
                             (current-column)))
        (pos -1))
    (condition-case nil
        (while (and (<= (point) indent-point)
                    (not (eobp)))
          (forward-sexp 1)
          (cl-incf pos))
      ;; If indent-point is _after_ the last sexp in the current sexp,
      ;; we detect that by catching the `scan-error'. In that case, we
      ;; should return the indentation as if there were an extra sexp
      ;; at point.
      (scan-error (cl-incf pos)))
    (cond ((= method pos)               ;first non-distinguished arg
           (+ containing-column schmu-indent))
          ((< method pos)               ;more non-distinguished args
           (schmu--normal-indent state))
          (t                            ;distinguished args
           (+ containing-column (* 2 schmu-indent))))))

(defun schmu--set-indentation ()
  "Set indentation for various Schmu forms."
  (mapc (lambda (x)
          (put (car x) 'schmu-indent-function (cadr x)))
        '((and  0)
          (defmacro defun)
          (defmacro- defun)
          (defn defun)
          (case 1)
          (cond 0)
          (do  0)
          (each  2)
          (fn defun)
          (for 3)
          (if 1)
          (if-let 1)
          (if-not 1)
          (let 1)
          (loop 1)
          (match 1)
          (or 0)
          (reduce 0)
          (try 0)
          (unless 1)
          (varfn defun)
          (when 1)
          (when-let 1)
          (signature 0)
          (while 1))))

;;;###autoload
(define-derived-mode schmu-mode prog-mode "schmu"
  "Major mode for the Schmu language"
  :syntax-table schmu-mode-syntax-table
  (setq-local font-lock-defaults '(schmu-highlights))
  (setq-local indent-line-function #'schmu-indent-line)
  (setq-local lisp-indent-function #'schmu-indent-function)
  (setq-local comment-start "--")
  ;; (setq-local comment-start-skip "-+ *")
  (setq-local comment-use-syntax t)
  (setq-local comment-end "")
  (setq-local imenu-case-fold-search t)
  (setq-local imenu-generic-expression schmu-imenu-generic-expression)
  (schmu--set-indentation))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smu\\'" . schmu-mode))

;;;###autoload
;; (add-to-list 'interpreter-mode-alist '("schmu" . schmu-mode))

(provide 'schmu-mode)
;;; schmu-mode.el ends here
