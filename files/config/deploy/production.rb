server '<server address>', :app, :web, :db, :primary => true
set :branch, '<branch for staging>'
set :deploy_to, "/var/www/#{application}"