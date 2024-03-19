function checkout -a ticketNumber -d 'checkouts the branch with the matching ticket number'
    # ensure argument is number 
    isNumber $ticketNumber
    if test $status -gt 0
        echo "Usage: checkout <ticket-number>"
        return 1
    end

    # find branch with that number 
    set branch (git branch | grep "dev.*$ticketNumber\$" | awk '{print $1}')
    echo "current branch value: $branch"
    # check if local branch was found 
    if test -z "$branch"
        set branch (git branch -r | grep "dev.*$ticketNumber\$" | awk '{print $1}')
        echo "Found remote branch: $branch"
        set branch (string replace 'origin/' '' $branch)
    end 

    # check branch was found 
    if test -n "$branch"; and not test -z "$branch"
        # ensure user wants to checkout onto the found branch 
        echo "checkout onto: $branch"
        confirmYN
        if test $status -eq 0
            git checkout $branch && git pull
        end
    else 
        echo "No branch found for ticket number $ticketNumber"
    end
end
