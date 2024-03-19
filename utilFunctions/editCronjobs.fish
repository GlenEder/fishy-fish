function editCronjobs -d 'uses vi to edit crontab file'
    sudo $EDITOR /etc/crontab
    crontab /etc/crontab
end
