namespace :deploy do
  desc "Set up initial deployment state"
  task :setup, :roles => :app, :except => { :no_release => true } do
    # Do an initial clone of the repo to each deploy path
    deploy_paths.each do |path|
      run "if [ -d #{path} ] ; then rm -rf #{path} ; fi"
      run "if [ -f #{path} ] ; then rm #{path} ; fi"
      run "git clone #{repository} #{path}"
    end
    
    # Clear out the current_path, be it a directory or an alias
    run "if [ -d #{current_path} ] ; then rm -rf #{current_path}; fi" 
    run "if [ -f #{current_path} ]; then rm #{current_path}; fi"
    
    # Mark the first deploy path
    mark_deploy_index
  end
end