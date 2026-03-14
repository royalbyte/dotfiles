;; -------
;; basic
;; -------
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)
(global-display-line-numbers-mode 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)
(setq inhibit-startup-screen t)

;; ----------------
;; visual and QoL
;; ----------------
(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)
(setq-default c-basic-offset 8)
(setq scroll-conservatively 1337)
(setq scroll-margin 6)
(setq isearch-lazy-count t)
(setq lazy-count-prefix-format "(%s/%s)")
(setq display-line-numbers-type 'relative)
(delete-selection-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)
(fset 'yes-or-no-p 'y-or-n-p)

;; ------------------
;; custom functions
;; ------------------

;; function to ensure packages that are on list-packages
(defun ensure-package (pkg)
  (unless (package-installed-p pkg)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install pkg)))

;; funny greeting
(defun greetings ()
  (message "Welcome Aboard Captain, all systems online! System boot time: %.2fs"
           (float-time (time-since before-init-time))))

;; complete meme
(defun hello()
  (interactive)
  (message "Hello, World!"))

;; functions to locate and reload the config
(defun .dat ()
  (interactive)
  (find-file user-init-file))

(defun .datl ()
  (interactive)
  (load-file user-init-file)
  (message "Reloaded main config! All systems online"))

;; tries to load the best font in the world, oh glorious iosevka
(defun ci/define-font ()
  "Applies default font."
  (when (and (display-graphic-p)
             (find-font (font-spec :name "Iosevka Slab")))
    (set-face-attribute 'default nil :font "Iosevka Slab-13")))

;; -------
;; binds
;; -------
(global-set-key (kbd "C-c e") '.dat)
(global-set-key (kbd "C-c r") '.datl)
(global-set-key (kbd "C-c c") 'compile)
(global-set-key (kbd "C-c s") 'shell-command)

;; ----------------
;; package system
;; ----------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; ----------
;; packages
;; ----------
(ensure-package 'vertico)
(vertico-mode 1)
(ensure-package 'orderless)
(setq completion-styles '(orderless basic))
(setq completion-category-defaults nil)
(ensure-package 'marginalia)
(marginalia-mode 1)
(ensure-package 'gruber-darker-theme)
(load-theme 'gruber-darker t)

;; --------------
;; organization
;; --------------
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; ----------------
;; initialization
;; ----------------
(ci/define-font)
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (ci/define-font))))
(add-hook 'emacs-startup-hook 'greetings)
