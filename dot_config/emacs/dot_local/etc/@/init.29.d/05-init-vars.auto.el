(when (or (doom-context-p 'init) (doom-context-p 'reload)) (set-default 'load-path '("/var/home/ashahid/.config/emacs/.local/straight/build-29.3/bind-key" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/elisp-refs" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/xref" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/parent-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/shrink-path" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/fringe-helper" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/git-gutter" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/expand-region" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/embrace" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/annalist" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ht" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/epl" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pkg-info" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/package-lint" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ess/obsolete" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/popup" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ctable" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/poly-noweb" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/poly-markdown" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/auctex/" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/math-symbol-lists" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/goto-chg" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org-noter" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/tablist" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/magit-section" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/with-editor" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/async" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/f" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pythonic" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/load-env-vars" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/seq" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/transient" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/shut-up" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/s" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/dash" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/link-hint" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/drag-stuff" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/yaml-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-shell" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/py-isort" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pyimport" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/python-pytest" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/nose" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pyvenv" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pipenv" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-anaconda" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/anaconda-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pip-requirements" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ob-async" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/orgit" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org-pdftools" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-org" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org-cliplink" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/toc-org" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ox-clip" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org-yt" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/htmlize" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/avy" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org-contrib" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-markdown" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/edit-indirect" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/markdown-toc" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/markdown-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-math" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-reftex" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-auctex" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-tex" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/latex-preview-pane" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/adaptive-wrap" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/auctex" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/json-snatcher" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/json-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/poly-R" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/polymode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ess-R-data-view" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ess" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/buttercup" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/flycheck-cask" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/flycheck-package" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/elisp-demos" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/elisp-def" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/overseer" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/macrostep" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/highlight-quoted" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/saveplace-pdf-view" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pdf-tools" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/password-store-otp" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/password-store" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pass" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/makefile-executor" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/magit-todos" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/magit" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/request" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/dumb-jump" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/eros" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/quickrun" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/flycheck-popup-tip" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/flycheck" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/vterm" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/git-modes" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/git-timemachine" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/git-commit" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/browse-at-remote" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/vundo" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/undo-fu-session" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/undo-fu" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/fd-dired" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/dired-rsync" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/dired-git-info" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/diredfl" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/doom-snippets" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/auto-yasnippet" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-vimish-fold" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/vimish-fold" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/yasnippet" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-collection" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-quick-diff" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/exato" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-visualstar" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-traces" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-textobj-anyblock" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-surround" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-snipe" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-numbers" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-nerd-commenter" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-lion" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-indent-plus" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-exchange" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-escape" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-embrace" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-easymotion" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-args" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/persp-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/vi-tilde-fringe" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/git-gutter-fringe" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-goggles" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/evil-anzu" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/anzu" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/doom-modeline" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/hl-todo" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/solaire-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/doom-themes" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/consult-yasnippet" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/wgrep" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/marginalia" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/embark-consult" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/embark" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/consult-flycheck" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/consult-dir" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/consult" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/orderless" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/vertico" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company-dict" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/company" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/which-key" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/general" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/project" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/projectile" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/ws-butler" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/smartparens" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/pcre2el" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/helpful" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/dtrt-indent" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/better-jumper" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/restart-emacs" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/rainbow-delimiters" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/highlight-numbers" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/hide-mode-line" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/nerd-icons" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/straight" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/gcmh" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/compat" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/auto-minor-mode" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/use-package" "/var/home/ashahid/.config/emacs/.local/straight/repos/straight.el" "/var/home/ashahid/.config/emacs/lisp/" "/usr/share/emacs/29.3/site-lisp" "/usr/share/emacs/site-lisp" "/usr/share/emacs/site-lisp/autoconf" "/usr/share/emacs/site-lisp/cmake" "/usr/share/emacs/site-lisp/desktop-file-utils" "/usr/share/emacs/site-lisp/libidn" "/usr/share/emacs/site-lisp/site-start.d" "/usr/share/emacs/29.3/lisp" "/usr/share/emacs/29.3/lisp/vc" "/usr/share/emacs/29.3/lisp/use-package" "/usr/share/emacs/29.3/lisp/url" "/usr/share/emacs/29.3/lisp/textmodes" "/usr/share/emacs/29.3/lisp/progmodes" "/usr/share/emacs/29.3/lisp/play" "/usr/share/emacs/29.3/lisp/org" "/usr/share/emacs/29.3/lisp/nxml" "/usr/share/emacs/29.3/lisp/net" "/usr/share/emacs/29.3/lisp/mh-e" "/usr/share/emacs/29.3/lisp/mail" "/usr/share/emacs/29.3/lisp/leim" "/usr/share/emacs/29.3/lisp/language" "/usr/share/emacs/29.3/lisp/international" "/usr/share/emacs/29.3/lisp/image" "/usr/share/emacs/29.3/lisp/gnus" "/usr/share/emacs/29.3/lisp/eshell" "/usr/share/emacs/29.3/lisp/erc" "/usr/share/emacs/29.3/lisp/emulation" "/usr/share/emacs/29.3/lisp/emacs-lisp" "/usr/share/emacs/29.3/lisp/cedet" "/usr/share/emacs/29.3/lisp/calendar" "/usr/share/emacs/29.3/lisp/calc" "/usr/share/emacs/29.3/lisp/obsolete" "/usr/share/emacs/29.3/lisp/vc" "/usr/share/emacs/29.3/lisp/use-package" "/usr/share/emacs/29.3/lisp/url" "/usr/share/emacs/29.3/lisp/textmodes" "/usr/share/emacs/29.3/lisp/progmodes" "/usr/share/emacs/29.3/lisp/play" "/usr/share/emacs/29.3/lisp/org" "/usr/share/emacs/29.3/lisp/nxml" "/usr/share/emacs/29.3/lisp/net" "/usr/share/emacs/29.3/lisp/mh-e" "/usr/share/emacs/29.3/lisp/mail" "/usr/share/emacs/29.3/lisp/leim" "/usr/share/emacs/29.3/lisp/language" "/usr/share/emacs/29.3/lisp/international" "/usr/share/emacs/29.3/lisp/image" "/usr/share/emacs/29.3/lisp/gnus" "/usr/share/emacs/29.3/lisp/eshell" "/usr/share/emacs/29.3/lisp/erc" "/usr/share/emacs/29.3/lisp/emulation" "/usr/share/emacs/29.3/lisp/emacs-lisp" "/usr/share/emacs/29.3/lisp/cedet" "/usr/share/emacs/29.3/lisp/calendar" "/usr/share/emacs/29.3/lisp/calc" "/usr/share/emacs/29.3/lisp/obsolete")) (set-default 'auto-mode-alist '(("\\.[Ss][Aa][Ss]\\'" . SAS-mode) ("\\.Sout\\'" . S-transcript-mode) ("\\.[Ss]t\\'" . S-transcript-mode) ("\\.Rd\\'" . Rd-mode) ("DESCRIPTION\\'" . conf-colon-mode) ("/Makevars\\(\\.win\\)?\\'" . makefile-mode) ("\\.[Rr]out\\'" . ess-r-transcript-mode) ("CITATION\\'" . ess-r-mode) ("NAMESPACE\\'" . ess-r-mode) ("\\.[rR]profile\\'" . ess-r-mode) ("\\.[rR]\\'" . ess-r-mode) ("/R/.*\\.q\\'" . ess-r-mode) ("\\.[Jj][Aa][Gg]\\'" . ess-jags-mode) ("\\.[Bb][Mm][Dd]\\'" . ess-bugs-mode) ("\\.[Bb][Oo][Gg]\\'" . ess-bugs-mode) ("\\.[Bb][Uu][Gg]\\'" . ess-bugs-mode) ("\\.cpp[rR]\\'" . poly-c++r-mode) ("\\.[Rr]cpp\\'" . poly-r+c++-mode) ("\\.[rR]brew\\'" . poly-brew+r-mode) ("\\.[rR]html\\'" . poly-html+r-mode) ("\\.rapport\\'" . poly-rapport-mode) ("\\.[rR]md\\'" . poly-markdown+r-mode) ("\\.[rR]nw\\'" . poly-noweb+r-mode) ("\\.Snw\\'" . poly-noweb+r-mode) ("\\.nw\\'" . poly-noweb-mode) ("\\.md\\'" . poly-markdown-mode) ("\\.hva\\'" . latex-mode) ("\\.\\(e?ya?\\|ra\\)ml\\'" . yaml-mode) ("requirements\\.in" . pip-requirements-mode) ("requirements[^z-a]*\\.txt\\'" . pip-requirements-mode) ("\\.pip\\'" . pip-requirements-mode) ("\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\)\\'" . markdown-mode) ("\\(?:\\(?:\\.\\(?:b\\(?:\\(?:abel\\|ower\\)rc\\)\\|json\\(?:ld\\)?\\)\\|composer\\.lock\\)\\'\\)" . json-mode) ("/git-rebase-todo\\'" . git-rebase-mode) ("/git/ignore\\'" . gitignore-mode) ("/info/exclude\\'" . gitignore-mode) ("/\\.gitignore\\'" . gitignore-mode) ("/etc/gitconfig\\'" . gitconfig-mode) ("/\\.gitmodules\\'" . gitconfig-mode) ("/git/config\\'" . gitconfig-mode) ("/modules/.*/config\\'" . gitconfig-mode) ("/\\.git/config\\'" . gitconfig-mode) ("/\\.gitconfig\\'" . gitconfig-mode) ("/git/attributes\\'" . gitattributes-mode) ("/info/attributes\\'" . gitattributes-mode) ("/\\.gitattributes\\'" . gitattributes-mode) ("\\.desktop\\(\\.in\\)?$" . desktop-entry-mode) ("CMakeLists\\.txt\\'" . cmake-mode) ("\\.cmake\\'" . cmake-mode) (".at'" . autotest-mode) ("\\.gpg\\(~\\|\\.~[0-9]+~\\)?\\'" nil epa-file) ("\\.elc\\'" . elisp-byte-code-mode) ("\\.zst\\'" nil jka-compr) ("\\.dz\\'" nil jka-compr) ("\\.xz\\'" nil jka-compr) ("\\.lzma\\'" nil jka-compr) ("\\.lz\\'" nil jka-compr) ("\\.g?z\\'" nil jka-compr) ("\\.bz2\\'" nil jka-compr) ("\\.Z\\'" nil jka-compr) ("\\.vr[hi]?\\'" . vera-mode) ("\\(?:\\.\\(?:rbw?\\|ru\\|rake\\|thor\\|jbuilder\\|rabl\\|gemspec\\|podspec\\)\\|/\\(?:Gem\\|Rake\\|Cap\\|Thor\\|Puppet\\|Berks\\|Brew\\|Vagrant\\|Guard\\|Pod\\)file\\)\\'" . ruby-mode) ("\\.re?st\\'" . rst-mode) ("\\.py[iw]?\\'" . python-mode) ("\\.m\\'" . octave-maybe-mode) ("\\.less\\'" . less-css-mode) ("\\.scss\\'" . scss-mode) ("\\.cs\\'" . csharp-mode) ("\\.awk\\'" . awk-mode) ("\\.\\(u?lpc\\|pike\\|pmod\\(\\.in\\)?\\)\\'" . pike-mode) ("\\.idl\\'" . idl-mode) ("\\.java\\'" . java-mode) ("\\.m\\'" . objc-mode) ("\\.ii\\'" . c++-mode) ("\\.i\\'" . c-mode) ("\\.lex\\'" . c-mode) ("\\.y\\(acc\\)?\\'" . c-mode) ("\\.h\\'" . c-or-c++-mode) ("\\.c\\'" . c-mode) ("\\.\\(CC?\\|HH?\\)\\'" . c++-mode) ("\\.[ch]\\(pp\\|xx\\|\\+\\+\\)\\'" . c++-mode) ("\\.\\(cc\\|hh\\)\\'" . c++-mode) ("\\.\\(bat\\|cmd\\)\\'" . bat-mode) ("\\.[sx]?html?\\(\\.[a-zA-Z_]+\\)?\\'" . mhtml-mode) ("\\.svgz?\\'" . image-mode) ("\\.svgz?\\'" . xml-mode) ("\\.x[bp]m\\'" . image-mode) ("\\.x[bp]m\\'" . c-mode) ("\\.p[bpgn]m\\'" . image-mode) ("\\.tiff?\\'" . image-mode) ("\\.gif\\'" . image-mode) ("\\.png\\'" . image-mode) ("\\.jpe?g\\'" . image-mode) ("\\.webp\\'" . image-mode) ("\\.te?xt\\'" . text-mode) ("\\.[tT]e[xX]\\'" . tex-mode) ("\\.ins\\'" . tex-mode) ("\\.ltx\\'" . latex-mode) ("\\.dtx\\'" . doctex-mode) ("\\.org\\'" . org-mode) ("\\.dir-locals\\(?:-2\\)?\\.el\\'" . lisp-data-mode) ("\\.eld\\'" . lisp-data-mode) ("eww-bookmarks\\'" . lisp-data-mode) ("tramp\\'" . lisp-data-mode) ("/archive-contents\\'" . lisp-data-mode) ("places\\'" . lisp-data-mode) ("\\.emacs-places\\'" . lisp-data-mode) ("\\.el\\'" . emacs-lisp-mode) ("Project\\.ede\\'" . emacs-lisp-mode) ("\\.\\(scm\\|sls\\|sld\\|stk\\|ss\\|sch\\)\\'" . scheme-mode) ("\\.l\\'" . lisp-mode) ("\\.li?sp\\'" . lisp-mode) ("\\.[fF]\\'" . fortran-mode) ("\\.for\\'" . fortran-mode) ("\\.p\\'" . pascal-mode) ("\\.pas\\'" . pascal-mode) ("\\.\\(dpr\\|DPR\\)\\'" . delphi-mode) ("\\.\\([pP]\\([Llm]\\|erl\\|od\\)\\|al\\)\\'" . perl-mode) ("Imakefile\\'" . makefile-imake-mode) ("Makeppfile\\(?:\\.mk\\)?\\'" . makefile-makepp-mode) ("\\.makepp\\'" . makefile-makepp-mode) ("\\.mk\\'" . makefile-gmake-mode) ("\\.make\\'" . makefile-gmake-mode) ("[Mm]akefile\\'" . makefile-gmake-mode) ("\\.am\\'" . makefile-automake-mode) ("\\.texinfo\\'" . texinfo-mode) ("\\.te?xi\\'" . texinfo-mode) ("\\.[sS]\\'" . asm-mode) ("\\.asm\\'" . asm-mode) ("\\.css\\'" . css-mode) ("\\.mixal\\'" . mixal-mode) ("\\.gcov\\'" . compilation-mode) ("/\\.[a-z0-9-]*gdbinit" . gdb-script-mode) ("-gdb\\.gdb" . gdb-script-mode) ("[cC]hange\\.?[lL]og?\\'" . change-log-mode) ("[cC]hange[lL]og[-.][0-9]+\\'" . change-log-mode) ("\\$CHANGE_LOG\\$\\.TXT" . change-log-mode) ("\\.scm\\.[0-9]*\\'" . scheme-mode) ("\\.[ckz]?sh\\'\\|\\.shar\\'\\|/\\.z?profile\\'" . sh-mode) ("\\.bash\\'" . sh-mode) ("/PKGBUILD\\'" . sh-mode) ("\\(/\\|\\`\\)\\.\\(bash_\\(profile\\|history\\|log\\(in\\|out\\)\\)\\|z?log\\(in\\|out\\)\\)\\'" . sh-mode) ("\\(/\\|\\`\\)\\.\\(shrc\\|zshrc\\|m?kshrc\\|bashrc\\|t?cshrc\\|esrc\\)\\'" . sh-mode) ("\\(/\\|\\`\\)\\.\\([kz]shenv\\|xinitrc\\|startxrc\\|xsession\\)\\'" . sh-mode) ("\\.m?spec\\'" . sh-mode) ("\\.m[mes]\\'" . nroff-mode) ("\\.man\\'" . nroff-mode) ("\\.sty\\'" . latex-mode) ("\\.cl[so]\\'" . latex-mode) ("\\.bbl\\'" . latex-mode) ("\\.bib\\'" . bibtex-mode) ("\\.bst\\'" . bibtex-style-mode) ("\\.sql\\'" . sql-mode) ("\\(acinclude\\|aclocal\\|acsite\\)\\.m4\\'" . autoconf-mode) ("\\.m[4c]\\'" . m4-mode) ("\\.mf\\'" . metafont-mode) ("\\.mp\\'" . metapost-mode) ("\\.vhdl?\\'" . vhdl-mode) ("\\.article\\'" . text-mode) ("\\.letter\\'" . text-mode) ("\\.i?tcl\\'" . tcl-mode) ("\\.exp\\'" . tcl-mode) ("\\.itk\\'" . tcl-mode) ("\\.icn\\'" . icon-mode) ("\\.sim\\'" . simula-mode) ("\\.mss\\'" . scribe-mode) ("\\.f9[05]\\'" . f90-mode) ("\\.f0[38]\\'" . f90-mode) ("\\.indent\\.pro\\'" . fundamental-mode) ("\\.\\(pro\\|PRO\\)\\'" . idlwave-mode) ("\\.srt\\'" . srecode-template-mode) ("\\.prolog\\'" . prolog-mode) ("\\.tar\\'" . tar-mode) ("\\.\\(arc\\|zip\\|lzh\\|lha\\|zoo\\|[jew]ar\\|xpi\\|rar\\|cbr\\|7z\\|squashfs\\|ARC\\|ZIP\\|LZH\\|LHA\\|ZOO\\|[JEW]AR\\|XPI\\|RAR\\|CBR\\|7Z\\|SQUASHFS\\)\\'" . archive-mode) ("\\.oxt\\'" . archive-mode) ("\\.\\(deb\\|[oi]pk\\)\\'" . archive-mode) ("\\`/tmp/Re" . text-mode) ("/Message[0-9]*\\'" . text-mode) ("\\`/tmp/fol/" . text-mode) ("\\.oak\\'" . scheme-mode) ("\\.sgml?\\'" . sgml-mode) ("\\.x[ms]l\\'" . xml-mode) ("\\.dbk\\'" . xml-mode) ("\\.dtd\\'" . sgml-mode) ("\\.ds\\(ss\\)?l\\'" . dsssl-mode) ("\\.js[mx]?\\'" . javascript-mode) ("\\.har\\'" . javascript-mode) ("\\.json\\'" . js-json-mode) ("\\.[ds]?va?h?\\'" . verilog-mode) ("\\.by\\'" . bovine-grammar-mode) ("\\.wy\\'" . wisent-grammar-mode) ("\\.erts\\'" . erts-mode) ("[:/\\]\\..*\\(emacs\\|gnus\\|viper\\)\\'" . emacs-lisp-mode) ("\\`\\..*emacs\\'" . emacs-lisp-mode) ("[:/]_emacs\\'" . emacs-lisp-mode) ("/crontab\\.X*[0-9]+\\'" . shell-script-mode) ("\\.ml\\'" . lisp-mode) ("\\.ld[si]?\\'" . ld-script-mode) ("ld\\.?script\\'" . ld-script-mode) ("\\.xs\\'" . c-mode) ("\\.x[abdsru]?[cnw]?\\'" . ld-script-mode) ("\\.zone\\'" . dns-mode) ("\\.soa\\'" . dns-mode) ("\\.asd\\'" . lisp-mode) ("\\.\\(asn\\|mib\\|smi\\)\\'" . snmp-mode) ("\\.\\(as\\|mi\\|sm\\)2\\'" . snmpv2-mode) ("\\.\\(diffs?\\|patch\\|rej\\)\\'" . diff-mode) ("\\.\\(dif\\|pat\\)\\'" . diff-mode) ("\\.[eE]?[pP][sS]\\'" . ps-mode) ("\\.\\(?:PDF\\|EPUB\\|CBZ\\|FB2\\|O?XPS\\|DVI\\|OD[FGPST]\\|DOCX\\|XLSX?\\|PPTX?\\|pdf\\|epub\\|cbz\\|fb2\\|o?xps\\|djvu\\|dvi\\|od[fgpst]\\|docx\\|xlsx?\\|pptx?\\)\\'" . doc-view-mode-maybe) ("configure\\.\\(ac\\|in\\)\\'" . autoconf-mode) ("\\.s\\(v\\|iv\\|ieve\\)\\'" . sieve-mode) ("BROWSE\\'" . ebrowse-tree-mode) ("\\.ebrowse\\'" . ebrowse-tree-mode) ("#\\*mail\\*" . mail-mode) ("\\.g\\'" . antlr-mode) ("\\.mod\\'" . m2-mode) ("\\.ses\\'" . ses-mode) ("\\.docbook\\'" . sgml-mode) ("\\.com\\'" . dcl-mode) ("/config\\.\\(?:bat\\|log\\)\\'" . fundamental-mode) ("/\\.\\(authinfo\\|netrc\\)\\'" . authinfo-mode) ("\\.\\(?:[iI][nN][iI]\\|[lL][sS][tT]\\|[rR][eE][gG]\\|[sS][yY][sS]\\)\\'" . conf-mode) ("\\.la\\'" . conf-unix-mode) ("\\.ppd\\'" . conf-ppd-mode) ("java.+\\.conf\\'" . conf-javaprop-mode) ("\\.properties\\(?:\\.[a-zA-Z0-9._-]+\\)?\\'" . conf-javaprop-mode) ("\\.toml\\'" . conf-toml-mode) ("\\.desktop\\'" . conf-desktop-mode) ("/\\.redshift\\.conf\\'" . conf-windows-mode) ("\\`/etc/\\(?:DIR_COLORS\\|ethers\\|.?fstab\\|.*hosts\\|lesskey\\|login\\.?de\\(?:fs\\|vperm\\)\\|magic\\|mtab\\|pam\\.d/.*\\|permissions\\(?:\\.d/.+\\)?\\|protocols\\|rpc\\|services\\)\\'" . conf-space-mode) ("\\`/etc/\\(?:acpid?/.+\\|aliases\\(?:\\.d/.+\\)?\\|default/.+\\|group-?\\|hosts\\..+\\|inittab\\|ksysguarddrc\\|opera6rc\\|passwd-?\\|shadow-?\\|sysconfig/.+\\)\\'" . conf-mode) ("[cC]hange[lL]og[-.][-0-9a-z]+\\'" . change-log-mode) ("/\\.?\\(?:gitconfig\\|gnokiirc\\|hgrc\\|kde.*rc\\|mime\\.types\\|wgetrc\\)\\'" . conf-mode) ("/\\.mailmap\\'" . conf-unix-mode) ("/\\.\\(?:asound\\|enigma\\|fetchmail\\|gltron\\|gtk\\|hxplayer\\|mairix\\|mbsync\\|msmtp\\|net\\|neverball\\|nvidia-settings-\\|offlineimap\\|qt/.+\\|realplayer\\|reportbug\\|rtorrent\\.\\|screen\\|scummvm\\|sversion\\|sylpheed/.+\\|xmp\\)rc\\'" . conf-mode) ("/\\.\\(?:gdbtkinit\\|grip\\|mpdconf\\|notmuch-config\\|orbital/.+txt\\|rhosts\\|tuxracer/options\\)\\'" . conf-mode) ("/\\.?X\\(?:default\\|resource\\|re\\)s\\>" . conf-xdefaults-mode) ("/X11.+app-defaults/\\|\\.ad\\'" . conf-xdefaults-mode) ("/X11.+locale/.+/Compose\\'" . conf-colon-mode) ("/X11.+locale/compose\\.dir\\'" . conf-javaprop-mode) ("\\.~?[0-9]+\\.[0-9][-.0-9]*~?\\'" nil t) ("\\.\\(?:orig\\|in\\|[bB][aA][kK]\\)\\'" nil t) ("[/.]c\\(?:on\\)?f\\(?:i?g\\)?\\(?:\\.[a-zA-Z0-9._-]+\\)?\\'" . conf-mode-maybe) ("\\.[1-9]\\'" . nroff-mode) ("\\.art\\'" . image-mode) ("\\.avs\\'" . image-mode) ("\\.bmp\\'" . image-mode) ("\\.cmyk\\'" . image-mode) ("\\.cmyka\\'" . image-mode) ("\\.crw\\'" . image-mode) ("\\.dcr\\'" . image-mode) ("\\.dcx\\'" . image-mode) ("\\.dng\\'" . image-mode) ("\\.dpx\\'" . image-mode) ("\\.fax\\'" . image-mode) ("\\.heic\\'" . image-mode) ("\\.hrz\\'" . image-mode) ("\\.icb\\'" . image-mode) ("\\.icc\\'" . image-mode) ("\\.icm\\'" . image-mode) ("\\.ico\\'" . image-mode) ("\\.icon\\'" . image-mode) ("\\.jbg\\'" . image-mode) ("\\.jbig\\'" . image-mode) ("\\.jng\\'" . image-mode) ("\\.jnx\\'" . image-mode) ("\\.miff\\'" . image-mode) ("\\.mng\\'" . image-mode) ("\\.mvg\\'" . image-mode) ("\\.otb\\'" . image-mode) ("\\.p7\\'" . image-mode) ("\\.pcx\\'" . image-mode) ("\\.pdb\\'" . image-mode) ("\\.pfa\\'" . image-mode) ("\\.pfb\\'" . image-mode) ("\\.picon\\'" . image-mode) ("\\.pict\\'" . image-mode) ("\\.rgb\\'" . image-mode) ("\\.rgba\\'" . image-mode) ("\\.tga\\'" . image-mode) ("\\.wbmp\\'" . image-mode) ("\\.webp\\'" . image-mode) ("\\.wmf\\'" . image-mode) ("\\.wpg\\'" . image-mode) ("\\.xcf\\'" . image-mode) ("\\.xmp\\'" . image-mode) ("\\.xwd\\'" . image-mode) ("\\.yuv\\'" . image-mode) ("\\.tgz\\'" . tar-mode) ("\\.tbz2?\\'" . tar-mode) ("\\.txz\\'" . tar-mode) ("\\.tzst\\'" . tar-mode) ("\\.drv\\'" . latex-mode))) (set-default 'interpreter-mode-alist '(("r" . ess-r-mode) ("Rscript" . ess-r-mode) ("ruby1.8" . ruby-mode) ("ruby1.9" . ruby-mode) ("jruby" . ruby-mode) ("rbx" . ruby-mode) ("ruby" . ruby-mode) ("python[0-9.]*" . python-mode) ("rhino" . js-mode) ("gjs" . js-mode) ("nodejs" . js-mode) ("node" . js-mode) ("gawk" . awk-mode) ("nawk" . awk-mode) ("mawk" . awk-mode) ("awk" . awk-mode) ("pike" . pike-mode) ("\\(mini\\)?perl5?" . perl-mode) ("wishx?" . tcl-mode) ("tcl\\(sh\\)?" . tcl-mode) ("expect" . tcl-mode) ("octave" . octave-mode) ("scm" . scheme-mode) ("[acjkwz]sh" . sh-mode) ("r?bash2?" . sh-mode) ("dash" . sh-mode) ("mksh" . sh-mode) ("\\(dt\\|pd\\|w\\)ksh" . sh-mode) ("es" . sh-mode) ("i?tcsh" . sh-mode) ("oash" . sh-mode) ("rc" . sh-mode) ("rpm" . sh-mode) ("sh5?" . sh-mode) ("tail" . text-mode) ("more" . text-mode) ("less" . text-mode) ("pg" . text-mode) ("make" . makefile-gmake-mode) ("guile" . scheme-mode) ("clisp" . lisp-mode) ("emacs" . emacs-lisp-mode))) (set-default 'magic-mode-alist '(("^%YAML\\s-+[0-9]+\\.[0-9]+\\(\\s-+#\\|\\s-*$\\)" . yaml-mode))) (set-default 'magic-fallback-mode-alist '(("^[{[]$" . json-mode) (image-type-auto-detected-p . image-mode) ("\\(PK00\\)?[P]K\3\4" . archive-mode) ("\\(?:<\\?xml[ \11\15\n]+[^>]*>\\)?[ \11\15\n]*<\\(?:!--\\(?:[^-]\\|-[^-]\\)*-->[ \11\15\n]*<\\)*\\(?:!DOCTYPE[ \11\15\n]+[^>]*>[ \11\15\n]*<[ \11\15\n]*\\(?:!--\\(?:[^-]\\|-[^-]\\)*-->[ \11\15\n]*<\\)*\\)?[Hh][Tt][Mm][Ll]" . mhtml-mode) ("<![Dd][Oo][Cc][Tt][Yy][Pp][Ee][ \11\15\n]+[Hh][Tt][Mm][Ll]" . mhtml-mode) ("<\\?xml " . xml-mode) ("[ \11\15\n]*<\\(?:!--\\(?:[^-]\\|-[^-]\\)*-->[ \11\15\n]*<\\)*!DOCTYPE " . sgml-mode) ("\320\317\21\340\241\261\32\341" . doc-view-mode-maybe) ("%!PS" . ps-mode) ("# xmcd " . conf-unix-mode))) (set-default 'Info-directory-list '("/var/home/ashahid/.config/emacs/.local/straight/build-29.3/auctex/" "/var/home/ashahid/.config/emacs/.local/straight/build-29.3/org/" "/home/linuxbrew/.linuxbrew/share/info" "/usr/share/info/" "/usr/share/info/" "/usr/share/info/")) (put 'doom-version 'major '3) (put 'doom-version 'minor '0) (put 'doom-version 'build '0) (put 'doom-version 'tag '"pre") (put 'doom-version 'ref '"9620bb45ac4cd7b0274c497b2d9d93c4ad9364ee") (put 'doom-version 'branch '"master"))