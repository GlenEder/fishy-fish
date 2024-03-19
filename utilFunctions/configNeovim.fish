function configNeovim -d 'Opens base init.lua for neovim configuration'
  cd $NEOVIM_HOME; $EDITOR init.lua; cd -; 
end
