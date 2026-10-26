function log_info -d 'Log informational messages to stdout'
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

    set -l message (string join ' ' -- $argv | string collect)
    test -z "$message"; and return 0

    if test $show_timestamp = true
        printf '%s[%s] %sINFO%s: %s\n' (set_color cyan) (date '+%Y-%m-%d %H:%M:%S') (set_color --bold cyan) (set_color normal) $message
    else
        printf '%sINFO%s: %s\n' (set_color --bold cyan) (set_color normal) $message
    end
end
