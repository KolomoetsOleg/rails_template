rails_root = "<location of the project>"

working_directory rails_root

pid "#{rails_root}/tmp/pids/unicorn.pid" # file for pids


socket_file = "#{rails_root}/tmp/sockets/unicorn.sock" # Which socket it should listen. Mast be the same as in nginx.conf
stdout_path "#{rails_root}/tmp/log/unicorn.stdout.log" # File for log
stderr_path rails_root+"/tmp/log/unicorn.stderr.log" # File for error log

timeout 30
worker_processes 1 # You can change it depending on the load
listen socket_file, :backlog => 1024
# listen 8080 # Uncomment this line and comment line above if you want unicorn to listen port, not socket


preload_app true # Process loads the application, before the produce workflows.

GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=) # not sure what it means to this line, but I decided to leave it.