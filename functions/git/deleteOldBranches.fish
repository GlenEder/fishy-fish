function deleteOldBranches -d 'Delete local branches that are gone from the remote'
    git fetch -pt; or return $status

    for line in (git branch -v)
        string match -q -r '\[gone\]' -- $line; or continue

        # Strip the *, +, or leading spaces prefix to get the real branch name
        set -l branch (string replace -r '^[*+ ]+' '' -- $line | awk '{print $1}')

        # Remove the linked worktree when the branch is checked out in another worktree
        if string match -q '+*' -- $line
            set -l worktree_path (git worktree list --porcelain | awk -v ref="refs/heads/$branch" '
                /^worktree / { wt=$2 }
                /^branch / && $2==ref { print wt; exit }
            ')
            if test -n "$worktree_path"
                log_info "Removing worktree for gone branch $branch: $worktree_path"
                git worktree remove --force $worktree_path
            end
        end

        log_info "Deleting stale local branch: $branch"
        git branch -D $branch
    end
end
