function cat --wraps cat --description 'bat for regular files, real cat for cygwin virtual paths'
    # /proc/* under msys2 is a cygwin-only virtual filesystem (registry,
    # process info, etc). bat is a native Windows binary and doesn't go
    # through the cygwin syscall layer, so it can't open those paths -
    # fall back to the real cat in that case.
    for arg in $argv
        if string match -q '/proc/*' -- $arg
            command cat $argv
            return
        end
    end
    bat $argv
end
