# XDG Base Directory paths -- set early so other tools (e.g. direnv) can
# locate their config/data/cache dirs.
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
$env:XDG_DATA_HOME = "$env:USERPROFILE\.local\share"
$env:XDG_CACHE_HOME = "$env:USERPROFILE\.cache"
