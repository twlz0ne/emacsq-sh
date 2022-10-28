#!/usr/bin/env bash

## Copyright (C) 2021 Gong Qijian <gongqijian@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Commentary:
# Helper script to run `emacs -Q'.
# The idea from https://github.com/emacs-helm/helm/blob/master/emacs-helm.sh
# 

# Created: 2021-03-30
# Version: 0.1.0
# Last-Updated: 2022-10-28 08:51:22 +0800
#           By: Gong Qijian
#     Update #: 8

function usage {
    cat >&1 <<EOF
Usage: ${0##*/} [SCRIPT-OPTIONS] [EMACS-OPTIONS-OR-FILENAME]

Script options:

    --path, -p EMACS_BIN    Emacs executable path [default emacs]
    --archives, -ar FILE    File to set ‘package-archives’ (default ~/.emacs.d/elpa.el)
    --user-dir, -ud DIR     Set ‘user-emacs-directory’, if not provide, choose from:
                                - ~/.emacs.d/{EMACS-VERSION}/
                                - ~/.emacs.d/{MAJOR-VERSION}.{MINOR-VERSION}/
                                - ~/.emacs.d/
                            In addtion, ‘<tmp>’ means to create a temporary directionary
                            as the ‘user-emacs-directory’ to guarantee purity.
    --elpa-dir, -ed DIR     Set ‘package-user-dir’ (default {user-emacs-directory}/elpa)
    --directory, -L DIR     prepend DIR to ‘load-path’ (can be set multiple times)
    --packages, -P PKGS     Load specified packages (separate with ",") 
    --modes, -M MODES       Emable specified modes (separate with ",")
    --dry-run               Print what would be done instead of actually doing it.
    --help, -h              Print help info.

Any other Emacs options (e.g. -nw, --eval...) or filename must come after.  For
more information execute ‘emacs --help’.

Example:

    ${0##*/} \\
        -p emacs-27 \\
        -ud .cask/27.1 \\
        -L /path/to/foo-pkg \\
        -L /path/to/bar-pkg \\
        -P foo,bar \\
        -M foo-mode,bar-mode -nw

EOF
}

opt_user_dir=
opt_elpa_dir=
opt_load_dirs=("\".\"")
opt_load_pkgs=
opt_enable_modes=
opt_emacs_bin=$EMACS
opt_archives=~/.emacs.d/elpa.el
opt_dry_run=

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h |--help) usage; exit 1 ;;
        -p |--path) shift; opt_emacs_bin="$1"; shift;;
        -ar|--archives) shift; opt_archives="$1"; shift;;
        -ud|--user-dir) shift; opt_user_dir="$1"; shift;;
        -ed|--elpa-dir) shift; opt_elpa_dir="$1"; shift;;
        -L |--directory) shift; opt_load_dirs+=("\"$1\""); shift;;
        -P |--packages) shift; opt_load_pkgs="$1"; shift;;
        -M |--modes) shift; opt_enable_modes="$1"; shift;;
        --dry-run) opt_dry_run=echo; shift;;
        -*) break;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
done

read -r -d '' expr <<__ELISP__
(progn
  (require 'seq)
  (require 'pcase)
  (require 'subr-x)
  (setq user-emacs-directory
        (let ((dir "${opt_user_dir}"))
          (cond
           ((string-empty-p dir)
            (car (seq-filter
                  #'file-exists-p
                  (list (format "~/.emacs.d/%s/" emacs-version)
                        (format "~/.emacs.d/%s.%s/" emacs-major-version emacs-minor-version)
                        "~/.emacs.d/"))))
           ((string= dir "<tmp>") (make-temp-file "emacsq--" 'tmpdir "/"))
           (t dir))))
  (message "==> user-emacs-directory: %s" user-emacs-directory)
  (setq package-user-dir
        (if (string-empty-p "${opt_elpa_dir}")
            (expand-file-name "elpa/" user-emacs-directory)
          "${opt_elpa_dir}"))
  (condition-case _
      (load "${opt_archives}")
    (file-missing))
  (package-initialize)
  (dolist (dir '(${opt_load_dirs[@]}))
    (add-to-list 'load-path (expand-file-name dir)))
  (unless (string-empty-p "${opt_load_pkgs}")
    (dolist (pkg (mapcar #'intern (split-string "${opt_load_pkgs}" ",")))
      (condition-case err
          ;; 1. first try
          (require pkg)
        (file-missing
         (condition-case err
             ;; 2. second try
             (progn
               (package-install pkg)
               (require pkg))
           (error
            (if (string= (cadr err) (format "Package ‘%s-’ is unavailable" pkg))
                ;; 3. final try
                (progn
                  (package-refresh-contents)
                  (package-install pkg)
                  (require pkg))
              (error (cadr err)))))))))
  (unless (string-empty-p "${opt_enable_modes}")
    (dolist (mode (split-string "${opt_enable_modes}" ","))
      (funcall (intern mode)))))
__ELISP__

${opt_dry_run} ${opt_emacs_bin:-emacs} -Q --debug-init --eval "${expr}" "$@"

# emacs-q.sh ends here
