require 'bundler/capistrano'  # Add Bundler integration
require 'capistrano/ext/multistage'

load 'deploy/assets'  # only for rails 3.1 apps, this makes sure our assets are precompiled.
set :shared_children, shared_children + %w{public/system}

set :application, "<AppName>"
set :stages, %w(staging production)
set :default_stage, 'staging'

set :keep_releases, 1

set :scm, 'git'

set :repository,  '<project-git>'
set :rvm_type, :system

set :deploy_via, :remote_cache
set :use_sudo, false
default_run_options[:pty] = true  # Forgo errors when deploying from windows
set :ssh_options, { :forward_agent => true }
after 'deploy', 'deploy:cleanup'
after 'deploy:cleanup', 'deploy:restart_apache'


namespace :deploy do
  desc "reload the database with seed data"
  task :seed do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
  end
end
namespace :deploy do
  desc "Restart apache"
  task :restart_apache do
    run "cd #{current_path}; rm log/production.log;sudo service apache2 restart"
  end
end

namespace :deploy do
  desc "Print log tail"
  task :logs do
    run "cd #{current_path}; cat log/production.log"
  end
end