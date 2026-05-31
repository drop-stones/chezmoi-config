# Language/locale
set -gx LANG en_US.UTF-8

# Editor
set -gx EDITOR nvim
set -gx VISUAL $EDITOR
set -gx GIT_EDITOR $EDITOR
set -gx GIT_SEQUENCE_EDITOR $EDITOR # used by `git rebase -i`

# Truecolor hint for TUI apps
set -gx COLORTERM truecolor

# msys2: when launched with `-shell fish` (as the WSL alias does), bash is
# bypassed and `/etc/profile` never runs, so PATH starts without /usr/bin.
# /etc/fish/msys2.fish would fix that, but it's sourced from /etc/fish/config.fish
# which runs *after* conf.d - by then 20-interactive.fish has already failed
# trying to call `uname` from fish_vi_key_bindings. Prepend the essentials here.
if set -q MSYSTEM
    fish_add_path -gp /usr/local/bin /usr/bin /bin /opt/bin
end
