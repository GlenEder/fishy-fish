function createBranch -d 'Create and push a new branch'
    if test (count $argv) -ne 1
        log_error "usage: createBranch <branch-name>"
        return 1
    end

    set -l branch_name $argv[1]

    # Refuse to reuse a name that already exists on a remote
    set -l exist_branch (git branch -r | grep $branch_name)
    if test -n "$exist_branch"
        log_error "Branch $branch_name already exists"
        return 1
    end

    log_info "Create branch: $branch_name?"
    confirmYN; or return 0

    git checkout -b $branch_name; or return $status
    git push -u origin $branch_name
end
