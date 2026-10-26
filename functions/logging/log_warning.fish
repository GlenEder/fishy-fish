function log_warning -d 'Log warning messages to stderr'
    set -l show_timestamp false

    # Consume leading -t/--timestamp flags
    while test (count $argv) -gt 0
        switch $argv[1]
            case -t --timestamp
                set show_timestamp true
                set -e argv[1]
            case '*'
                break
        end
    end

    set -l message (string join ' ' -- $argv)
    test -z "$message"; and return 0

    if test $show_timestamp = true
        printf '%s[%s] %sWARN%s: %s\n' (set_color yellow) (date '+%Y-%m-%d %H:%M:%S') (set_color --bold yellow) (set_color normal) $message >&2
    else
        printf '%sWARN%s: %s\n' (set_color --bold yellow) (set_color normal) $message >&2
    end
end
