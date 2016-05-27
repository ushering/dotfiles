;;; my-org.el --- customization for org-mode

;;; Commentary:

;;; Code:

(eval-when-compile (require 'cl))

(require 'core-keybindings)
(require 'dash)
(require 'org)
(require 'org-agenda)
(require 'org-capture)
(require 'org-clock)
(require 'org-habit)
(require 'org-drill)
(require 's)

;; Custom bindings
(spacemacs/set-leader-keys
  "aoj" 'org-clock-goto)

(setq org-directory "~/Dropbox/org")

(setq org-default-notes-file "~/Dropbox/org/refile.org")

(setq org-agenda-files '("~/Dropbox/org/"))

(setq org-log-done t)

;; Resume clocking task when emacs is restarted
(org-clock-persistence-insinuate)

;; Show lot of clocking history so it's easy to pick items off the C-F11 list
(setq org-clock-history-length 23)

;; Resume clocking task on clock-in if the clock is open
(setq org-clock-in-resume t)

;; Change tasks to NEXT when clocking in
(setq org-clock-in-switch-to-state 'bh/clock-in-to-next)

;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
(setq org-clock-out-remove-zero-time-clocks t)

;; Save the running clock and all clock history when exiting Emacs, load it on
;; startup
(setq org-clock-persist t)

;; Do not prompt to resume an active clock
(setq org-clock-persist-query-resume nil)

;; Include current clocking task in clock reports
(setq org-clock-report-include-clocking-task t)

;; We use a smarter definition for stuck projects
(setq org-stuck-projects (quote ("" nil nil "")))

(defvar bh/keep-clock-running nil)

(defun bh/find-project-task ()
  "Move point to the parent (project) task if any."
  (save-restriction
    (widen)
    (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
      (while (org-up-heading-safe)
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq parent-task (point))))
      (goto-char parent-task)
      parent-task)))

(defun bh/punch-in (arg)
  "Start continuous clocking.
ARG is the prefix argument.  One press means set the current task
as default.  Set the default task to the selected task.  If no
task is selected set the Organization task as the default task."
  (interactive "p")
  (setq bh/keep-clock-running t)
  (if (equal major-mode 'org-agenda-mode)
      ;;
      ;; We're in the agenda
      ;;
      (let* ((marker (org-get-at-bol 'org-hd-marker))
             (tags (org-with-point-at marker (org-get-tags-at))))
        (if (and (eq arg 4) tags)
            (org-agenda-clock-in '(16))
          (bh/clock-in-organization-task-as-default)))
    ;;
    ;; We are not in the agenda
    ;;
    (save-restriction
      (widen)
      ; Find the tags on the current task
      (if (and (equal major-mode 'org-mode) (not (org-before-first-heading-p)) (eq arg 4))
          ;; set it as default with 2 prefix args
          (org-clock-in '(16))
        (bh/clock-in-organization-task-as-default)))))

(defun bh/punch-out ()
  "Stop clocking for the day."
  (interactive)
  (setq bh/keep-clock-running nil)
  (when (org-clock-is-active)
    (org-clock-out))
  (org-agenda-remove-restriction-lock))

(defun bh/clock-in-default-task ()
  "Clock in at the default task."
  (save-excursion
    (org-with-point-at org-clock-default-task
      (org-clock-in))))

(defun bh/clock-in-parent-task ()
  "Move point to the parent (project) task if any and clock in."
  (let ((parent-task))
    (save-excursion
      (save-restriction
        (widen)
        (while (and (not parent-task) (org-up-heading-safe))
          (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
            (setq parent-task (point))))
        (if parent-task
            (org-with-point-at parent-task
              (org-clock-in))
          (when bh/keep-clock-running
            (bh/clock-in-default-task)))))))

(defvar bh/organization-task-id "eb155a82-92b2-4f25-a3c6-0304591af2f9")

(defun bh/clock-in-organization-task-as-default ()
  "Clock into the organization task."
  (interactive)
  (org-with-point-at (org-id-find bh/organization-task-id 'marker)
    (org-clock-in '(16))))

(defun bh/clock-out-maybe ()
  "Maybe clock out."
  (when (and bh/keep-clock-running
             (not org-clock-clocking-in)
             (marker-buffer org-clock-default-task)
             (not org-clock-resolving-clocks-due-to-idleness))
    (bh/clock-in-parent-task)))

(add-hook 'org-clock-out-hook 'bh/clock-out-maybe 'append)

;; Fontify code in code blocks
(setq org-src-fontify-natively t)


(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)"
                  "|" "DONE(d)")
        ;; The @/! means log a note when entering this state and log just
        ;; a timestamp when leaving this state
        (sequence "WAITING(w@/!)" "HOLD(h@/!)"
                  "|" "CANCELLED(c)")))

(setq org-tag-alist
      '(;; Elements of a group are mutually exclusive
        (:startgroup . nil)
        ("work" . ?w) ("home" . ?h) ("comp" . ?c) ("errand" . ?e)
        (:endgroup . nil)

        (:startgroup . nil)
        ("start" . ?s) ("mid" . ?m) ("end" . ?n)
        (:endgroup . nil)

        (:startgroup . nil)
        ("daily" . ?d) ("weekly" . ?k)
        (:endgroup . nil)

        (:startgroup . nil)
        ("waiting" . ?t) ("hold" . ?h) ("cancelled" . ?c)
        (:endgroup . nil)

        ))

;; The reason we have a waiting tag is for projects so we can identify the next
;; task.  The next task might be waiting, but if we set the todo state to
;; WAITING, then we lose information on what the next task is.
(setq org-todo-state-tags-triggers
      '(
        ;; Moving a task to CANCELLED adds a CANCELLED tag.
        ("CANCELLED" ("cancelled" . t))
        ("WAITING" ("waiting" . t))

        ;; Moving a task to HOLD removes a WAITING tag and adds a HOLD tag
        ("HOLD" ("waiting") ("hold" . t))
        ;; done means any done state, the one's after the "|" in
        ;; `org-todo-keywords'
        (done ("waiting") ("hold"))
        ("TODO" ("waiting") ("cancelled") ("hold"))
        ("NEXT" ("waiting") ("cancelled") ("hold"))
        ("DONE" ("waiting") ("cancelled") ("hold"))))

(setq org-agenda-compact-blocks t)


;; The Agenda

;; Customize my agenda.  Don't use `add-to-list' because if we re-evaluate each
;; expression, it would append it to the list.  Instead we replace entries using
;; their shortcut keystroke as the key into the alist.

(defun my:org-agenda-add (cmd)
  "Add CMD to `org-agenda-custom-commands' intelligently.
Replace CMDs that already exist by comparing the shortuct keystroke."
  (my:replace-or-add-to-alist
   'org-agenda-custom-commands
   cmd))

(my:org-agenda-add
 '("h" "Office and Home Lists"
   ((agenda)
    (tags-todo "work")
    (tags-todo "home")
    (tags-todo "comp")
    (tags-todo "read"))))

;; Daily

(my:org-agenda-add
 '("d" . "Daily"))

(my:org-agenda-add
 '("dd" "All daily"
   ((agenda "" ((org-agenda-ndays 1)))
    (tags-todo "start+mid+end"))))

(my:org-agenda-add
 '("ds" "Daily Start"
   (
    (agenda ""
            ((org-agenda-span 'day)
             (org-agenda-skip-function
              '(org-agenda-skip-entry-if 'notregexp ":start:")))))))

(my:org-agenda-add
 '("dm" "Daily Mid"
   ((tags "mid+SCHEDULED=\"<+0d>\""
          ((org-agenda-overriding-header "Daily Mid"))))))

(my:org-agenda-add
 '("dn" "Daily End"
   ((tags "end+SCHEDULED=\"<+0d>\""
          ((org-agenda-overriding-header "Daily End"))))))

;; Tasks

(my:org-agenda-add
 '("t" . "Tasks"))

(my:org-agenda-add
 '("tr" "Refile"
   ((tags "refile"
          ((org-agenda-overriding-header "Unfiled tasks")
           (org-tags-match-list-sublevels nil))))))

(my:org-agenda-add
 '("tt" "Today"
   (
    ;; Events
    (agenda ""
            ((org-agenda-entry-types '(:timestamp :sexp))
             (org-agenda-overriding-header
              (concat "CALENDAR Today "
                      (format-time-string "%a %d" (current-time))))
             (org-agenda-span 'day)))

    )))

(my:org-agenda-add
 '("ts" "Standalone Tasks"
   (
    ;; Events
    (agenda ""
            ((org-agenda-ndays 1)))

    ;; Unscheduled New Tasks
    (tags-todo "LEVEL=2"
               ((org-agenda-overriding-header "Unscheduled tasks")
                (org-agenda-files (list ,org-default-notes-file)))))))

(my:org-agenda-add
 '("rN" "Next"
   ((tags-todo "TODO<>{SDAY}")
    (org-agenda-overriding-header "List of all TODO entries with no due date (no SDAY)")
    (org-agenda-skip-function '(org-agenda-skip-entry-if 'deadline))
    (org-agenda-sorting-strategy '(priority-down)))))

(my:org-agenda-add
 '("E" "Errands" tags-todo "errand"))

;; Projects

(my:org-agenda-add
'("p" . "Projects"))

(my:org-agenda-add
 '("ps" "Stuck Project"
   ((tags-todo "/!"
               ((org-agenda-overriding-header "Stuck Projects")
                (org-agenda-skip-function 'bh/skip-non-stuck-projects))))
   )
 )

(my:org-agenda-add
 '(" " "Agenda"
   (

    ;; Start-day tasks
    (agenda ""
            ((org-agenda-span 'day)
             (org-agenda-skip-function
              '(org-agenda-skip-entry-if 'notregexp ":start:"))))

    (tags "refile"
          ((org-agenda-overriding-header "Unfiled tasks")
           (org-tags-match-list-sublevels nil)))

    (agenda ""
            ((org-agenda-span 'day)
             ;; Skip :start:, :mid: or :end: tags
             (org-agenda-skip-function
              '(org-agenda-skip-entry-if 'regexp ":start:\\|:mid:\\|:end:"))))


    (tags-todo "-CANCELLED/!"
               ((org-agenda-overriding-header "Stuck Projects")
                (org-agenda-skip-function 'bh/skip-non-stuck-projects)
                (org-agenda-sorting-strategy '(category-keep))))

    ;; Project Next Tasks
    (tags-todo "-CANCELLED/!NEXT"
               ((org-agenda-overriding-header (concat "Project Next Tasks"
                                                      (if bh/hide-scheduled-and-waiting-next-tasks
                                                          ""
                                                        " (including WAITING and SCHEDULED tasks)")))
                (org-agenda-skip-function 'bh/skip-projects-and-habits-and-single-tasks)
                (org-tags-match-list-sublevels t)
                (org-agenda-todo-ignore-scheduled 'all)
                (org-agenda-todo-ignore-deadlines 'all)
                ;; Important to enable this to ignore scheduled items
                (org-agenda-tags-todo-honor-ignore-options t)
                (org-agenda-sorting-strategy
                 '(todo-state-down effort-up category-keep))))

    ;; Standalone Tasks
    (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
               ((org-agenda-overriding-header (concat "Standalone Tasks"
                                                      (if bh/hide-scheduled-and-waiting-next-tasks
                                                          ""
                                                        " (including WAITING and SCHEDULED tasks)")))
                (org-agenda-skip-function 'bh/skip-project-tasks)
                (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                (org-agenda-sorting-strategy
                 '(category-keep))))


    ;; Mid-day tasks
    (tags "mid+SCHEDULED=\"<+0d>\""
          ((org-agenda-overriding-header "Daily Mid")))

    ;; (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
    ;;            ((org-agenda-overriding-header (concat "Project Subtasks"
    ;;                                                   (if bh/hide-scheduled-and-waiting-next-tasks
    ;;                                                       ""
    ;;                                                     " (including WAITING and SCHEDULED tasks)")))
    ;;             (org-agenda-skip-function 'bh/skip-non-project-tasks)
    ;;             (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
    ;;             (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
    ;;             (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
    ;;             (org-agenda-sorting-strategy
    ;;              '(category-keep))))


    (tags-todo "-CANCELLED+WAITING|HOLD/!"
               ((org-agenda-overriding-header (concat "Waiting and Postponed Tasks"
                                                      (if bh/hide-scheduled-and-waiting-next-tasks
                                                          ""
                                                        " (including WAITING and SCHEDULED tasks)")))
                (org-agenda-skip-function 'bh/skip-non-tasks)
                (org-tags-match-list-sublevels nil)
                (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)))

    ;; Daily-end tasks
    (tags "end+SCHEDULED=\"<+0d>\""
          ((org-agenda-overriding-header "Daily End")))


    (tags-todo "-HOLD-CANCELLED/!"
               ((org-agenda-overriding-header "Projects")
                (org-agenda-skip-function 'bh/skip-non-projects)
                (org-tags-match-list-sublevels 'indented)
                (org-agenda-sorting-strategy
                 '(category-keep))))
    )
   nil))

(setq org-capture-templates
      `(("t" "todo" entry (file ,org-default-notes-file)
         "* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)

        ("r" "respond" entry (file ,org-default-notes-file)
         "* NEXT Respond to %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n"
         :clock-in t :clock-resume t :immediate-finish t)

        ("n" "note" entry (file ,org-default-notes-file)
         "* %? :NOTE:\n%U\n%a\n" :clock-in t :clock-resume t)

        ("j" "Journal" entry (file+datetree "~/Dropbox/org/journal.org")
         "* %?\n%U\n" :clock-in t :clock-resume t)

        ("w" "org-protocol" entry (file ,org-default-notes-file)
         "* TODO Review %c\n%U\n" :immediate-finish t)

        ("m" "Meeting" entry (file ,org-default-notes-file)
         "* MEETING with %? :MEETING:\n%U" :clock-in t :clock-resume t)

        ("p" "Phone call" entry (file ,org-default-notes-file)
         "* PHONE %? :PHONE:\n%U" :clock-in t :clock-resume t)

        ("h" "Habit" entry (file ,org-default-notes-file)
         "* NEXT %?\n%U\n%a\nSCHEDULED: %(format-time-string \"%<<%Y-%m-%d %a .+1d/3d>>\")\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n")))

(defun my:remove-empty-drawer-on-clock-out ()
  "Remove empty LOGBOOK drawers on clock out."
  (interactive)
  (save-excursion
    (beginning-of-line 0)
    (org-remove-empty-drawer-at (point))))

(add-hook 'org-clock-out-hook 'my:remove-empty-drawer-on-clock-out 'append)

;; Don't do any normla logging if changing todo state with Shift-Right or
;; shift-left.  Useful for fixing incorrect todo states.
(setq org-treat-S-cursor-todo-selection-as-state-change nil)

;; (setq org-refile-targets
;;       '(("gtd.org" :maxlevel . 1)
;;         ("someday.org" :level . 2)))

(setq org-refile-targets
      '((nil :maxlevel . 9) ; nil means current buffer
        (org-agenda-files :maxlevel . 9)))

;; Allow paths for refiling like Projects/Setup Ubuntu
(setq org-refile-use-outline-path t)

;; Show all subtrees when refiling
(setq org-outline-path-complete-in-steps nil)

;; save all the agenda files after each capture and when agenda mode is
;; open
(add-hook 'org-capture-after-finalize-hook 'org-save-all-org-buffers)
(add-hook 'org-agenda-mode-hook 'org-save-all-org-buffers)
(advice-add #'org-refile :after #'org-save-all-org-buffers)

;; Add C-c C-c keybinding to exit org-edit-src to mirror Magit's commit
;; buffer.
(with-eval-after-load 'org-src
  (define-key org-src-mode-map "\C-c\C-c" 'org-edit-src-exit))

(defun swift-plaques-compile (&optional force)
  "Compile the swift-plaques project.
If FORCE is non-nil, force recompilation even if files haven't changed."
  (interactive)
  (org-publish "swift-plaques" t))






(defun my:make-org-link-cite-key-visible (&rest _)
  "Make the org-ref cite link visible in descriptive links."
  (when (string-prefix-p "cite:" (match-string 1))
    (remove-text-properties (+ (length "cite:") (match-beginning 1))
                            (match-end 1)
                            '(invisible))))

(spacemacs/set-leader-keys-for-major-mode 'org-mode
  "yk" 'org-priority-up
  "yj" 'org-priority-down)

(with-eval-after-load 'ox-latex
  (let* ((text-spacing
          (s-join
           "\n"
           '("\\ifxetex"
             "  \\newcommand{\\textls}[2][5]{%"
             "  \\begingroup\\addfontfeatures{LetterSpace=#1}#2\\endgroup"
             "}"
             "\\renewcommand{\\allcapsspacing}[1]{\\textls[15]{#1}}"
             "\\renewcommand{\\smallcapsspacing}[1]{\\textls[10]{#1}}"
             "\\renewcommand{\\allcaps}[1]{\\textls[15]{\\MakeTextUppercase{#1}}}"
             "\\renewcommand{\\smallcaps}[1]{\\smallcapsspacing{\\scshape\\MakeTextLowercase{#1}}}"
             "\\renewcommand{\\textsc}[1]{\\smallcapsspacing{\\textsmallcaps{#1}}}"
             "\\fi")))
         (multitoc "\\usepackage[toc]{multitoc}")
         (tufte-handout-class
          `("tufte-handout"
            ,(s-join "\n"
                     `("\\documentclass{tufte-handout}[notoc]"
                       "[DEFAULT-PACKAGES]"
                       "[EXTRA]"
                       ,text-spacing
                       "% http://tex.stackexchange.com/questions/200722/"
                       ,multitoc
                       "[PACKAGES]"))
            ("\\section{%s}" . "\\section*{%s}")
            ("\\subsection{%s}" . "\\subsection*{%s}")))
         (tufte-book-class
          `("tufte-book"
            ,(s-join "\n"
                     `("\\documentclass{tufte-book}"
                       "[DEFAULT-PACKAGES]"
                       "[EXTRA]"
                       ,text-spacing
                       "% http://tex.stackexchange.com/questions/200722/"
                       ,multitoc
                       "[PACKAGES]"))
            ("\\chapter{%s}" . "\\chapter*{%s}")
            ("\\section{%s}" . "\\section*{%s}")
            ("\\subsection{%s}" . "\\subsection*{%s}"))))
    (my:replace-or-add-to-alist 'org-latex-classes tufte-book-class)
    (my:replace-or-add-to-alist 'org-latex-classes tufte-handout-class)))


(defun bh/is-task-p ()
  "Any task with a todo keyword and no subtask."
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task (not has-subtask)))))

(defun bh/is-project-p ()
  "Any task with a todo keyword subtask."
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task has-subtask))))

(defun bh/is-subproject-p ()
  "Any task which is a subtask of another project."
  (let ((is-subproject)
        (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
    (save-excursion
      (while (and (not is-subproject) (org-up-heading-safe))
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq is-subproject t))))
    (and is-a-task is-subproject)))

(defun bh/clock-in-to-next (current-todo-state)
  "Set tasks TODO state to NEXT when clocking in.
If CURRENT-TODO-STATE is TODO then change to NEXT.  Skips capture
tasks, projects, and subprojects.  Sets subprojects from NEXT
back to TODO to indicate they are stuck."
  (when (not (and (boundp 'org-capture-mode) org-capture-mode))
    (cond
     ((and (member current-todo-state (list "TODO"))
           (bh/is-task-p))
      "NEXT")
     ((and (member current-todo-state (list "NEXT"))
           (bh/is-project-p))
      "TODO"))))

(defun my/org-agenda-match-tags (tags)
  "Match entries that have all TAGS."
  (let* ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
         (current-headline (or (and (org-at-heading-p)
                                    (point))
                               (save-excursion (org-back-to-heading))))
         (current-tags (org-get-tags-at current-headline)))

    (if (-any-p (lambda (tag) (not (member tag current-tags))) tags)
        next-headline
      nil)))

(defun bh/is-project-subtree-p ()
  "Any task with a todo keyword that is in a project subtree.
Callers of this function already widen the buffer view."
  (let ((task (save-excursion (org-back-to-heading 'invisible-ok)
                              (point))))
    (save-excursion
      (bh/find-project-task)
      (if (equal (point) task)
          nil
        t))))

(defun bh/list-sublevels-for-projects-indented ()
  "Set org-tags-match-list-sublevels to list all sub tasks.
Applies when restricted to a subtree we list all subtasks.  This
is normally used by skipping functions where this variable is
already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels 'indented)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defvar bh/hide-scheduled-and-waiting-next-tasks t)

(defun bh/toggle-next-task-display ()
  "Toggle the value of `bh/hide-scheduled-and-waiting-next-tasks'."
  (interactive)
  (setq bh/hide-scheduled-and-waiting-next-tasks (not bh/hide-scheduled-and-waiting-next-tasks))
  (when  (equal major-mode 'org-agenda-mode)
    (org-agenda-redo))
  (message "%s WAITING and SCHEDULED NEXT Tasks" (if bh/hide-scheduled-and-waiting-next-tasks "Hide" "Show")))

(defun bh/skip-stuck-projects ()
  "Skip trees that are stuck projects."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next ))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (unless (member "WAITING" (org-get-tags-at))
                  (setq has-next t))))
            (if has-next
                nil
              next-headline)) ; a stuck project, has subtasks but no next task
        nil))))

(defun bh/skip-non-stuck-projects ()
  "Skip trees that are not stuck projects.
A stuck project is one that does not have NEXT item."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next nil))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next)
                          (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (setq has-next t)))
            (if has-next
                next-headline
              nil)) ; a stuck project, has subtasks but no next task
        next-headline))))

(defun bh/skip-non-projects ()
  "Skip trees that are not projects."
  ;; (bh/list-sublevels-for-projects-indented)
  (if (save-excursion (bh/skip-non-stuck-projects))
      (save-restriction
        (widen)
        (let ((subtree-end (save-excursion (org-end-of-subtree t))))
          (cond
           ((bh/is-project-p)
            nil)
           ((and (bh/is-project-subtree-p) (not (bh/is-task-p)))
            nil)
           (t
            subtree-end))))
    (save-excursion (org-end-of-subtree t))))

(defun bh/skip-non-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((bh/is-task-p)
        nil)
       (t
        next-headline)))))

(defun bh/skip-project-trees-and-habits ()
  "Skip trees that are projects."
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-projects-and-habits-and-single-tasks ()
  "Skip trees that are projects, tasks that are habits, single non-project tasks."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((org-is-habit-p)
        next-headline)
       ((and bh/hide-scheduled-and-waiting-next-tasks
             (member "waiting" (org-get-tags-at)))
        next-headline)
       ((bh/is-project-p)
        next-headline)
       ((and (bh/is-task-p) (not (bh/is-project-subtree-p)))
        next-headline)
       (t
        nil)))))

(defun bh/skip-project-tasks-maybe ()
  "Show tasks related to the current restriction.
When restricted to a project, skip project and sub project tasks,
habits, NEXT tasks, and loose tasks.  When not restricted, skip
project and sub-project tasks, habits, and project related
tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max))))
           (limit-to-project (marker-buffer org-agenda-restrict-begin)))
      (cond
       ((bh/is-project-p)
        next-headline)
       ((org-is-habit-p)
        subtree-end)
       ((and (not limit-to-project)
             (bh/is-project-subtree-p))
        subtree-end)
       ((and limit-to-project
             (bh/is-project-subtree-p)
             (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
       (t
        nil)))))

(defun bh/skip-project-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       ((bh/is-project-subtree-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-non-project-tasks ()
  "Show project tasks.
Skip project and sub-project tasks, habits, and loose non-project tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((bh/is-project-p)
        next-headline)
       ((org-is-habit-p)
        subtree-end)
       ((and (bh/is-project-subtree-p)
             (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
       ((not (bh/is-project-subtree-p))
        subtree-end)
       (t
        nil)))))

(defun bh/skip-projects-and-habits ()
  "Skip trees that are projects and tasks that are habits."
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-non-subprojects ()
  "Skip trees that are not projects."
  (let ((next-headline (save-excursion (outline-next-heading))))
    (if (bh/is-subproject-p)
        nil
      next-headline)))


(defun my:replace-or-add-to-alist (alist-var elem)
  "Replace in ALIST-VAR the first entry whose `car' `equal's (car ELEM).
Replace the cdr of the found item in ALIST-VAR with ELEM.
ALIST-VAR must be a symbol.  If no \(car entry\) in ALIST-VAR
equals the `car' of ELEM, then prepend ELEM to ALIST-VAR.

\(my:replace-or-add-to-alist 'an-alist '(\"key\" \"data\")\)"
  (let ((alist (symbol-value alist-var)))
    (if (assoc (car elem) alist)
        (setcdr (assoc (car elem) alist)
                (cdr elem))
      (set alist-var (cons elem alist)))))

(provide 'my-org)
;;; my-org.el ends here
