function configFishEnvs -d 'opens config.fish with $EDITOR'
    cd $FISH_HOME; $EDITOR config.fish; cd -;
end
