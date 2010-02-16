namespace :deploy do
  def banner(message)
    puts "========================================"
    puts message
    puts "========================================"
  end
  
  def mark_deploy_index(index = 0)
    run "(echo #{index} > #{shared_path}/DEPLOY_INDEX)"
  end
end