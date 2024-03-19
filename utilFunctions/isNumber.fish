function isNumber -d 'tests if the passed arg is a number'
    if string match -r '^[0-9]+$' $argv[1] > /dev/null
        return 0
    else
        return 1
    end
end