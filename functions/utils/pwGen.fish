function pwGen -d 'Generate a random password'
    set -l length 32
    set -l help "Usage: pwGen [-l/--length <n>] [-h/--help]

Options:
  -l, --length <n>  Length of the generated password (default: 32)
  -h, --help        Show this help message"

    while test (count $argv) -gt 0
        switch $argv[1]
            case -l --length
                set -e argv[1]
                if test (count $argv) -eq 0
                    log_error "Missing value for --length"
                    log_info $help
                    return 1
                end
                if not string match -q -r '^[0-9]+$' -- $argv[1]; or test $argv[1] -lt 1
                    log_error "Length must be a positive integer: $argv[1]"
                    return 1
                end
                set length $argv[1]
                set -e argv[1]
            case -h --help
                log_info $help
                return 0
            case '*'
                log_error "Unknown param provided: $argv[1]"
                log_info $help
                return 1
        end
    end

    # Generate more bytes than needed, join the wrapped lines, then trim to the requested length
    set -l raw (string join '' (openssl rand -base64 (math "$length * 2")))
    echo (string sub -l $length -- $raw)
end
