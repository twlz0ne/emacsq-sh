# emacsq-sh

Helper script to run `emacs -Q`.
The idea from https://github.com/emacs-helm/helm/blob/master/emacs-helm.sh

# Usage

``` sh
$ ./emacsq.sh -h
Usage: emacsq.sh [SCRIPT-OPTIONS] [EMACS-OPTIONS-OR-FILENAME]

Script options:

    --path, -p EMACS_BIN    Emacs executable path [default emacs]
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
    --help, -h              Print help info and exit

Any other Emacs options (e.g. -nw, --eval...) or filename must come after.  For
more information execute ‘emacs --help’.

Example:

    emacsq.sh \
        -p emacs-27 \
        -ud .cask/27.1 \
        -L /path/to/foo-pkg \
        -L /path/to/bar-pkg \
        -P foo,bar \
        -M foo-mode,bar-mode -nw
```
