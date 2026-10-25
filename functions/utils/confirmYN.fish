function confirmYN -d 'Prompts user with y/n input'
    read -n 1 -p "echo '[y\n] '" yesno
    if string match -q "y" $yesno
        return 0
    end 
    return 1
end