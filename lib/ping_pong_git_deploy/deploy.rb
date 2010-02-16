# Ping and/or pong
set :deploy_path_0, "#{deploy_to}/deploy_0"
set :deploy_path_1, "#{deploy_to}/deploy_1"
set :deploy_paths,  [deploy_path_0, deploy_path_1]

set :last_deploy_index,   defer { capture("tail -n 1 #{shared_path}/DEPLOY_INDEX") }
set :deploy_index,        defer { (last_deploy_index.to_i + 1) % 2 }
set :deploy_path,         defer { "#{deploy_to}/deploy_#{deploy_index}" }

# Git SCM
set :sha, defer { `git rev-parse HEAD` }
set :latest_revision, defer { capture("tail -n 1 #{shared_path}/REVISIONS").strip }
set :previous_revision, defer { capture("tail -n 2 #{shared_path}/REVISIONS | head -n 1").strip }

namespace :deploy do
  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    if branch =~ /[0-9a-fA-F]{40}/
      reset_to = branch
    else
      reset_to = "#{fetch(:git_remote, 'origin')}/#{branch}"
    end
    
    announce_deploy_path
    
    run "cd #{deploy_path}; git fetch origin; git reset --hard #{reset_to}; git-clean -fxd"
    run "(echo #{revision} > #{deploy_path}/REVISION)"
    
    finalize_update
  end
  
  
  desc "Link shared files into the deployed directory. This implementation is only slightly modified from the original Capistrano version."
  task :finalize_update, :except => { :no_release => true } do
    # mkdir -p is making sure that the directories are there for some SCMs that don't
    # save empty folders
    run "rm -rf #{deploy_path}/log #{deploy_path}/public/system #{deploy_path}/tmp/pids"
    run <<-CMD
      mkdir -p #{deploy_path}/public &&
      mkdir -p #{deploy_path}/tmp &&
      ln -s #{shared_path}/log #{deploy_path}/log &&
      ln -s #{shared_path}/system #{deploy_path}/public/system &&
      ln -s #{shared_path}/pids #{deploy_path}/tmp/pids
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = %w(images stylesheets javascripts).map { |p| "#{deploy_path}/public/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end
end