;; configurations for terminal Emacs

;; -------
;; basic
;; -------
(menu-bar-mode -1)
(tooltip-mode -1)
(global-display-line-numbers-mode 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)
(setq inhibit-startup-screen t)

;; ----------------
;; visual and QoL
;; ----------------
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

;; create directoy
(defun ci/dir ()
  (interactive)
  (if (derived-mode-p 'dired-mode)
      (call-interactively 'dired-create-directory)
    (call-interactively 'make-directory)))

;; changes coding style, as of right now only between Linux and Xorg
(defun ci/cstyle-menu ()
  (interactive)
  (let ((option (completing-read "Choose a coding style:"
                                '("Kernel.org" "X.org"))))
    (ci/cstyle-fmt option)
    (message "Applied style: %s" option)))

(defun ci/cstyle-fmt (style)
  (if (string= style "Kernel.org")
      (progn
        (setq-local indent-tabs-mode t)
        (setq-local tab-width 8)
        (setq-local c-basic-offset 8)
        (setq-local fill-column 80))
    (progn
      (setq-local indent-tabs-mode nil)
      (setq-local tab-width 4)
      (setq-local c-basic-offset 4)
      (setq-local fill-column 78))))

;; sets a waypoint
(defun ci/waypoint (nametag)
  (interactive "sNAMETAG: ")
  (setq-local current-buffer (buffer-file-name))
  (setq-local waypoints-path (expand-file-name "waypoints.txt" user-emacs-directory))
  (unless (file-exists-p waypoints-path)
    (write-region "" nil waypoints-path))
  (append-to-file (format "{%s} %s\n" nametag current-buffer) nil waypoints-path)
  (message "File successfully added to waypoints list"))

;; jumps to waypoint
(defun ci/pointdevice ()
  (interactive)
  (let (choices)
    (with-temp-buffer
      (insert-file-contents
       (expand-file-name "waypoints.txt" user-emacs-directory))
      (dolist (line (split-string (buffer-string) "\n" t))
        (when (string-match "{\\([^}]+\\)} \\(.+\\)" line)
          (push (cons (match-string 1 line)
                      (match-string 2 line))
                choices))))
    (find-file
     (cdr (assoc (completing-read "Waypoint: " choices nil t)
                 choices)))))

;; -------
;; binds
;; -------
(global-set-key (kbd "C-c e") '.dat)
(global-set-key (kbd "C-c r") '.datl)
(global-set-key (kbd "C-c v") 'compile)
(global-set-key (kbd "C-c c") 'shell-command)
(global-set-key (kbd "C-c s") 'ci/cstyle-menu)
(global-set-key (kbd "C-c w") 'ci/waypoint)
(global-set-key (kbd "C-c p") 'ci/pointdevice)

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
(ci/cstyle-fmt "Kernel.org") ;; global/default style to linux
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (ci/define-font))))
(add-hook 'emacs-startup-hook 'greetings)
