function deleteOldBranches -d 'Deletes local branches that have been deleted or merged on remote'
    git fetch -pt && git branch -v | grep "\[gone\]" | awk "{print \$1}" | xargs git branch -D
end 