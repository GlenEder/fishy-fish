function checkout -d 'Interactively pick a local or remote branch to check out'
    # Collect all local branches
    set -l branches (git branch --format='%(refname:short)')

    # Track whether we are currently showing remote branches
    set -l showing_remote false

    # Present branches ten at a time and prompt the user to pick one
    set -l page 0
    set -l page_size 10
    set -l total (count $branches)
    log_info "Found $total local branches"

    set -l selected ''
    while true
        # Calculate the slice of branches to display on this page
        set -l start (math "$page * $page_size")
        set -l end (math "$start + $page_size")
        if test $end -gt $total
            set end $total
        end

        # Print the numbered list for the current page
        echo ""
        set -l i $start
        while test $i -lt $end
            set -l num (math "$i - $start + 1")
            set -l idx (math "$i + 1")
            echo "  $num) "$branches[$idx]
            set i (math $i + 1)
        end

        # Determine the extra option to show after the branch list
        set -l extra_label ''
        if test $end -lt $total
            # More pages of the current source remain
            set extra_label "Show more branches"
        else if test $showing_remote = false
            # All local branches shown - offer to load remote branches
            set extra_label "Show remote branches"
        end

        # Print the extra option if there is one
        set -l extra_num (math "$end - $start + 1")
        if test -n "$extra_label"
            echo "  $extra_num) $extra_label"
        end

        # Prompt the user to enter a number
        echo ""
        read -P "Enter a number to checkout a branch: " choice; or return 1

        # Validate that the input is a positive integer
        if not string match -q -r '^[0-9]+$' -- $choice; or test $choice -lt 1
            log_error "Invalid selection. Please enter a number from the list."
            continue
        end

        # Handle the extra option if it was selected
        if test -n "$extra_label"; and test $choice -eq $extra_num
            if test "$extra_label" = "Show more branches"
                # Advance to the next page of the current branch list
                set page (math $page + 1)
                continue
            else
                # Fetch remote state and load all remote branches
                log_info "Fetching remote branches..."
                git fetch -p
                # %(refname:short) renders origin/HEAD as bare "origin", so drop both forms
                set branches (git branch -r --format='%(refname:short)' | string match -rv 'HEAD|^[^/]+$')
                set showing_remote true
                set page 0
                set total (count $branches)
                continue
            end
        end

        # Validate the choice is within the displayed range
        if test $choice -gt (math "$end - $start")
            log_error "Invalid selection. Please enter a number from the list."
            continue
        end

        # Resolve the selected branch name, stripping the remote prefix if needed
        set -l idx (math "$start + $choice")
        set selected $branches[$idx]
        if test $showing_remote = true
            set selected (string replace -r '^[^/]+/' '' -- $selected)
        end
        break
    end

    # Checkout the selected branch and pull the latest changes
    git checkout $selected; or return $status
    git pull
end
