;; Rafaes's personal configurations for terminal Emacs, because the GUI is too slow

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

;; ----------------
;; package system
;; ----------------
;; oh boy, complex custom package system here we go...

(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(defvar ci/pkg-dir (expand-file-name "pkgs/" user-emacs-directory))
(unless (file-directory-p ci/pkg-dir)
  (make-directory ci/pkg-dir t))
(add-to-list 'load-path ci/pkg-dir)

(defvar packages-registry
  '(("simpc-mode" . "https://raw.githubusercontent.com/rexim/simpc-mode/master/simpc-mode.el")))

(defun ci/pkg-download (url dest)
  (message "Downloading %s..." url)
  (with-current-buffer (url-retrieve-synchronously url t t)
    (goto-char (point-min))
    (re-search-forward "\n\n" nil 'move)
    (write-region (point) (point-max) dest nil 'silent)
    (kill-buffer))
  (message "Downloaded at %s" dest))

(defun ci/pkg-install (pkg url)
  (let* ((name (symbol-name pkg))
         (dest (expand-file-name (concat name ".el") ci/pkg-dir)))
    (unless (file-exists-p dest)
      (ci/pkg-download url dest))
    (ignore-errors
      (byte-compile-file dest))
    (add-to-list 'load-path ci/pkg-dir)
    (require pkg nil t)))

(defun ci/pkg-dns-resolver (pkg)
  (let* ((name (symbol-name pkg))
         (entry (assoc name packages-registry)))
    (when entry
      (let ((url (cdr entry)))
        (message "Using fallback to %s" name)
        (ci/pkg-install pkg url)
        t))))

(defun ensure-package (pkg)
  (if (package-installed-p pkg)
      (require pkg)
    (condition-case err
        (progn
          (unless package-archive-contents
            (package-refresh-contents))
          (package-install pkg)
          (require pkg)
          (message "Installing %s using package.el" pkg))
      (error
       (if (ci/pkg-dns-resolver pkg)
           (message "Installing %s after fallback (GitHub)" pkg)
         (error "Error while trying to install %s: %s" pkg err))))))

;; ------------------
;; custom functions
;; ------------------
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

;; tries to load the only two acceptable fonts on the planet
(defun ci/define-font ()
  "Applies default font."
  (cond
   ((find-font (font-spec :name "Iosevka Slab"))
    (set-face-attribute 'default nil :font "Iosevka Slab-13"))
   ((find-font (font-spec :name "Frutiger"))
    (set-face-attribute 'default nil :font "Frutiger-13")
    (message "Something went wrong while loading the default font, loading Frutiger"))))

;; create directory
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
(global-set-key (kbd "C-c d") 'ci/dir)
(global-set-key (kbd "C-c q") 'query-replace)

;; ----------
;; packages
;; ----------
(ensure-package 'vertico) ;; I have a feeling that I could implement this manually and it would be very lightweight, but I'm too lazy frfr
(ensure-package 'orderless) ;; useful bloat
(ensure-package 'marginalia) ;; I don't use this very often, but yk sometimes it is useful
(ensure-package 'gruber-darker-theme)
(ensure-package 'simpc-mode) ;; Emacs built-in C mode is horrible

;; ----------
;; configs
;; ----------
(vertico-mode 1)
(setq completion-styles '(orderless basic))
(setq completion-category-defaults nil)
(marginalia-mode 1)
(load-theme 'gruber-darker t)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode)) ;; black magic

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
(ci/cstyle-fmt "Kernel.org")
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (ci/define-font))))
(add-hook 'emacs-startup-hook 'greetings)
