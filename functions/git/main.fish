function main -d 'Checkout the default branch, pull, fetch tags, and delete stale branches'
    # Resolve the repo's default branch (main, master, or whatever origin/HEAD points at)
    set -l head_ref (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    or begin
        log_error "Could not determine the default branch; is origin configured?"
        return 1
    end
    set -l default_branch (basename $head_ref)

    log_info "Checking out default branch: $default_branch"
    git checkout $default_branch; or return $status

    log_info "Pulling latest changes from remote"
    git pull; or return $status

    # Grab latest tags and update local ones
    log_info "Fetching tags from remote"
    git fetch --tags --force

    log_info "Deleting stale local branches"
    deleteOldBranches
end
