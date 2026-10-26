function updateDevroot -d 'Update all git repositories in the specified directory'
    set -l help "Usage: updateDevroot [-h/--help] [-f/--fetch-only] [-i/--ignore-dir <dir>]... <directory>

Update all git repositories in the specified directory.

Options:
  -h, --help               Show this help message
  -f, --fetch-only         Fetch latest changes only (skip checkout to default branch)
  -i, --ignore-dir <dir>   Skip repositories whose directory name matches <dir> (repeatable)"

    set -l fetch_only false
    set -l ignore_dirs

    while test (count $argv) -gt 0
        switch $argv[1]
            case -h --help
                log_info $help
                return 0
            case -f --fetch-only
                set fetch_only true
                set -e argv[1]
            case -i --ignore-dir
                set -e argv[1]
                if test (count $argv) -eq 0
                    log_error "Missing value for --ignore-dir"
                    log_info $help
                    return 1
                end
                set -a ignore_dirs $argv[1]
                set -e argv[1]
            case '-*'
                log_error "Unknown option: $argv[1]"
                log_info $help
                return 1
            case '*'
                break
        end
    end

    set -l target_dir
    if test (count $argv) -lt 1
        log_warning "Missing directory argument, checking for env DEVROOT"
        if test -n "$DEVROOT"
            log_info "Using $DEVROOT"
            set target_dir $DEVROOT
        else
            log_error "DEVROOT missing/empty"
            log_info $help
            return 1
        end
    else
        set target_dir $argv[1]
    end

    if not test -d "$target_dir"
        log_error "Directory does not exist: $target_dir"
        return 1
    end

    set -l repos (find $target_dir -maxdepth 2 -type d -name '.git' -exec dirname {} \; 2>/dev/null)
    if test (count $repos) -eq 0
        log_info "No git repositories found in $target_dir"
        return 0
    end
    log_info "Found "(count $repos)" repository(ies) in $target_dir"

    # Filter out ignored directories
    if test (count $ignore_dirs) -gt 0
        set -l filtered
        for repo in $repos
            set -l repo_basename (basename $repo)
            if contains -- $repo_basename $ignore_dirs
                log_info "Skipping $repo_basename (ignored)"
                continue
            end
            set -a filtered $repo
        end
        set repos $filtered
    end

    # Run each repo in the background; results land in a temp file because fish does not
    # expose $last_pid for backgrounded functions (shortcut: temp file, revisit if fish adds job pids)
    set -l result_file (mktemp)
    for repo in $repos
        log_info -t "Updating "(basename $repo)"..."
        __updateDevrootRepo $repo $fetch_only $result_file &
    end
    wait

    set -l results (cat $result_file)
    rm -f $result_file

    set -l updated_count (count (string match 'SUCCESS:*' -- $results))
    set -l error_count (count (string match 'FAILED:*' -- $results))
    set -l failed_repos (string replace 'FAILED:' '' -- (string match 'FAILED:*' -- $results))

    if test $error_count -gt 0
        log_error "Failed repos: $failed_repos"
    end
    log_info "Update complete: $updated_count succeeded, $error_count failed"
end

function __updateDevrootRepo -d 'internal: update one repository for updateDevroot'
    set -l repo $argv[1]
    set -l fetch_only $argv[2]
    set -l result_file $argv[3]
    set -l repo_name (basename $repo)

    if test "$fetch_only" = true
        if git -C $repo fetch -pt 2>/dev/null
            echo "SUCCESS:$repo_name" | tee -a $result_file
            return 0
        end
        echo "FAILED:$repo_name" | tee -a $result_file
        return 1
    end

    pushd $repo; or begin
        echo "FAILED:$repo_name" | tee -a $result_file
        return 1
    end
    main
    set -l result $status
    popd

    if test $result -eq 0
        echo "SUCCESS:$repo_name" | tee -a $result_file
        return 0
    end
    echo "FAILED:$repo_name" | tee -a $result_file
    return 1
end
