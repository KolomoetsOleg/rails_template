server '<server_address>', :app, :web, :db, :primary => true
set :branch, '<branch_for_staging>'
set :deploy_to, "/var/www/#{application}"