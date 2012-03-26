;; see http://xahlee.org/emacs/elisp_comment_handling.html
;; see also http://xahlee.org/emacs/elisp_syntax_coloring.html for testing
;; Using font locks with maching: http://www.gnu.org/software/emacs/manual/html_node/elisp/Search_002dbased-Fontification.html#Search_002dbased-Fontification
;; see also http://www.emacswiki.org/emacs/EmacsSyntaxTable for a list of syntax classes (e.g. for jumping over words, etc.)
;; for lists of name faces, see http://www.gnu.org/software/emacs/manual/html_node/elisp/Faces-for-Font-Lock.html

(setq myKeywords
 `(
   ; The first matched rule wins
   ("^ +[^<>: ].*$" . font-lock-string-face)

   ;( ,(regexp-opt '("::" "<" ">" "=" "(" ")" "@") 'word) . font-lock-function-name-face)
   ;
   ( ,(regexp-opt '("::" "<" ">") 'word) . font-lock-builtin-face)
   ( ,(regexp-opt '("task" "func" "group" "action" "branchpoint" "branch" "submitter" "package" "versioner") 'word) . font-lock-keyword-face)
   ( ,(regexp-opt '("checkout" "update" "local_version" "repo_version") 'word) . font-lock-keyword-face)
   ;( ,(regexp-opt '("Pi" "Infinity") 'word) . font-lock-constant-face)

   ;; see http://stackoverflow.com/questions/2970597/highlighting-correctly-in-an-emacs-major-mode
   ; stuff between "
   ("\"\\.\\*\\?" . font-lock-string-face)
   ("^\\[.*?\\]" . font-lock-function-name-face)

   ;(":\\|,\\|;\\|{\\|}\\|=>\\|@\\|$\\|=" . font-lock-keyword-face)
   ;( ,(regexp-opt mydsl-keywords 'words) . font-lock-builtin-face)
   ;( ,(regexp-opt mydsl-events 'words) . font-lock-constant-face)
  )
)

;; define the major mode.
(define-derived-mode ducttape-mode fundamental-mode
"ducttape workflow"

  (setq font-lock-defaults '(myKeywords))

  ;; perl style comment: "# ..." 
  (modify-syntax-entry ?# "< b" ducttape-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" ducttape-mode-syntax-table)
)

(setq auto-mode-alist (cons '("\\.tape$" . ducttape-mode) auto-mode-alist))
