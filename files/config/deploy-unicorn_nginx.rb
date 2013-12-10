require 'capistrano/ext/multistage'
require 'rvm/capistrano' # This is for working with capistrano

set :application, "<App_name>" # I don't know why but it's not working if you set <app_name> in stages
set :rails_env, "production"
set :stages, %w(staging production)
set :default_stage, 'production'
set :deploy_to, "<Dir_for_deploy>"
set :user_rails, "<user_name>"

set :keep_releases, 2

set :use_sudo, false
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/tmp/pids/unicorn.pid"

set :scm, :git
set :repository, "<Repository>"
set :branch, "master"
set :deploy_via, :remote_cache

require "bundler/capistrano"

set :bundle_flags, ''
set :bundle_without, %w{development test}.join(' ')

set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
set :unicorn_binary, "bash -c 'source /etc/profile.d/rvm.sh && unicorn_rails -c #{unicorn_config} -E #{rails_env} -D'"
set :su_rails, "sudo -u #{user_rails}"

after 'deploy', 'deploy:create_sock'

namespace 'bundle' do
  task 'install' do
    run "cd #{release_path} && bundle install --gemfile #{release_path}/Gemfile --path #{shared_path}/bundle  --without development test"
  end
end

namespace 'deploy' do
  task 'create_sock' do
    run "mkdir #{current_path}/tmp/sockets"
  end
end

require 'capistrano-unicorn'
before 'deploy', 'unicorn:stop'
after 'deploy', 'unicorn:start'

namespace 'unicorn' do

  task :start, :except => { :no_release => true } do
    # Start unicorn server using sudo (rails)
    run "cd #{current_path} && #{su_rails} #{unicorn_binary}"
  end

  task :stop, :except => { :no_release => true } do
    run "if [ -f #{unicorn_pid} ]; then #{su_rails} kill `cat #{unicorn_pid}`; fi"
  end
  task :restart, :except => { :no_release => true } do
    stop
    start
  end
end

namespace 'nginx' do
  task 'stop' do
    run "cd #{current_path}; sudo /etc/init.d/nginx stop"
  end
  task 'start' do
    run "cd #{current_path}; sudo /etc/init.d/nginx start;"
  end
  task 'restart' do
    run "cd #{current_path}; sudo /etc/init.d/nginx restart"
  end
end