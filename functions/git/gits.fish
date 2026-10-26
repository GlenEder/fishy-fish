function gits -d 'Shortcut for git status; -f prints filenames only'
    set -l help "Usage: gits [-f/--filenames-only] [-h/--help]

Options:
  -f, --filenames-only  (optional) Show only filenames, not status symbols
  -h, --help            Show this help message"

    set -l filename_only false

    # Parse command line arguments
    while test (count $argv) -gt 0
        switch $argv[1]
            case -f --filenames-only
                set filename_only true
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

    if test $filename_only = true
        git status -s | cut -c 4-
    else
        git status -s
    end
end
