function dropChanges -d 'Revert changes in the current repository'
    set -l help "Usage: dropChanges [-a/--all-files] [-d/--delete-untracked] [-h/--help]

Drop changes in the current repository by checking out the current path.

Options:
  -a, --all-files         Find all changed files via git status and check them out
  -d, --delete-untracked  Delete untracked files in current directory and below
  -h, --help              Show this help message"

    set -l all_files false
    set -l delete_untracked false

    while test (count $argv) -gt 0
        switch $argv[1]
            case -a --all-files
                set all_files true
                set -e argv[1]
            case -d --delete-untracked
                set delete_untracked true
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

    if test $delete_untracked = true
        set -l untracked (gits | string match '?? *' | string sub -s 4)
        if test (count $untracked) -eq 0
            log_info "No untracked files to delete"
        else if test $all_files = true
            for file in $untracked
                rm -rf $file
                log_info "Deleted: $file"
            end
        else
            # Only delete untracked files at or below the current directory
            set -l current_dir (realpath (pwd))
            set -l deleted_any false
            for file in $untracked
                if string match -q -- "$current_dir/*" (realpath $file)
                    rm -rf $file
                    log_info "Deleted: $file"
                    set deleted_any true
                end
            end
            if test $deleted_any = false
                log_info "No untracked files to delete in current directory"
            end
        end
    end

    if test $all_files = true
        set -l changed_files (gits | grep -v '^??' | cut -c 4-)
        if test (count $changed_files) -eq 0
            log_info "No changed files found"
            return 0
        end
        for file in $changed_files
            git checkout -- $file
            log_info "Checked out: $file"
        end
    end

    if test $all_files = false; and test $delete_untracked = false
        git checkout -- .
    end
end
