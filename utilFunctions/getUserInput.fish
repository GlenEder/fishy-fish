function getUserInput -a prompt -d 'Helper class that propmts user and returns response'
    read -p "echo $prompt " userInput
    echo $userInput; 
end