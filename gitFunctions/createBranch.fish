function createBranch -a branchName -d 'Checkouts and pushes to remote the given branch name'
    if test (count $argv) -ne 1
        echo "usage: createBranch <branch-name>"
        return 1
    end

    # check for existing branch 
    set existBranch (git branch -r | grep "$branchName")
    if test -n "$existBranch"
        echo "Branch $branchName already exists";
        return 1
    end  

    # confirm branch name 
    echo "Create branch: $branchName?"
    confirmYN
    if test $status -eq 0
        git checkout -b $branchName;
        git push -u origin $branchName;
    end
end 
