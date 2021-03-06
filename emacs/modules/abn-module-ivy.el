;;; abn-module-ivy.el --- Ivy setup

;;; Commentary:
;;

;;; Code:

(require 'use-package)

(use-package abn-funcs-ivy
  :ensure nil ; local package
  :commands (abn/turn-on-ivy-mode)
  :bind
  (:map abn-leader-map
   ;; registers
   ("re" . abn/ivy-evil-registers)
   ("sz" . abn/counsel-zsh-history)
   ("st" . abn/counsel-tmux-words)))

(use-package counsel
  :diminish counsel-mode
  :bind
  (;; Current global keymap
   ("M-x" . counsel-M-x)

   :map abn-leader-map
   ("SPC" . counsel-M-x)

   ;; files
   ("fel" . counsel-find-library)
   ("ff" . counsel-find-file)
   ("fL" . counsel-locate)
   ("fr" . counsel-recentf)

   ;; help
   ("?"  . counsel-descbinds)
   ("hdf" . counsel-describe-function)
   ("hdm" . describe-mode)
   ("hdv" . counsel-describe-variable)
   ("hR" . spacemacs/counsel-search-docs)

   ;; register/ring
   ("ry" . counsel-yank-pop)

   ;; jumping
   ("sj" . counsel-imenu)
   ("ji" . counsel-imenu)

   ;; insert
   ("iu" . counsel-unicode-char)

   ;; search
   ("/"  . counsel-rg)
   ("sp"  . counsel-rg))
  :config
  ;; Remaps built-in commands that have a counsel replacement.
  (counsel-mode 1))

(use-package ivy
  :diminish ivy-mode
  :bind
  (:map abn-leader-map
   ("bb" . ivy-switch-buffer)
   ("rl" . ivy-resume)

   :map ivy-minibuffer-map
   ("C-j" . ivy-next-line)
   ("C-k" . ivy-previous-line)
   ("C-M-j" . ivy-scroll-up-command)
   ("C-M-k" . ivy-scroll-down-command)
   ("C-<return>" . ivy-alt-done)
   ("M-<return>" . ivy-immediate-done)
   ("C-M-n" . ivy-restrict-to-matches)
   ("C-h" . backward-delete-char-untabify)
   ("C-S-h" . help-map)
   ("C-l" . ivy-alt-done)
   ("<escape>" . minibuffer-keyboard-quit))

  :init
  ;; 15 lines in minibuffer
  (setq ivy-height 15)
  (setq ivy-count-format "(%d/%d)")
  ;; Recent files and bookmarks to `ivy-switch-buffer'
  (setq ivy-use-virtual-buffers t)
  ;; Don't show . and .. in find files.
  (setq ivy-extra-directories '())
  ;; Don't exit if we press backspace too many times.
  (setq ivy-on-del-error-function (lambda ()))

  ;; Avoid eagerly loading `ivy-mode'.
  (add-hook 'org-mode-hook #'abn/turn-on-ivy-mode))

;; Add help menu by pressing C-o in minibuffer.
(use-package ivy-hydra
  :defer t)

(use-package counsel-projectile
  :bind
  (:map abn-leader-map
   ("p SPC" . counsel-projectile)
   ("pb" . counsel-projectile-switch-to-buffer)
   ("pd" . counsel-projectile-find-dir)
   ("pp" . counsel-projectile-switch-project)
   ("pf" . counsel-projectile-find-file)
   ("pr" . projectile-recentf))
  :init
  (with-eval-after-load 'projectile
    (setq projectile-switch-project-action 'counsel-projectile-find-file)))

;; counsel-M-x will use smex if available.
(use-package smex
  :defer t
  :init
  (setq smex-save-file (concat abn-cache-dir "/smex-items")))

(use-package swiper
  :bind
  (;; Current global keymap.
   ("\C-s" . swiper)

   :map abn-leader-map
   ("ss" . swiper)
   ("sS" . spacemacs/swiper-region-or-symbol)
   ("sb" . swiper-all)
   ("sB" . spacemacs/swiper-all-region-or-symbol)))

(provide 'abn-module-ivy)
;;; abn-module-ivy.el ends here
