# >---------------------------------------------------------------------------<
#
#            _____       _ _
#           |  __ \     (_) |       /\
#           | |__) |__ _ _| |___   /  \   _ __  _ __  ___
#           |  _  // _` | | / __| / /\ \ | '_ \| '_ \/ __|
#           | | \ \ (_| | | \__ \/ ____ \| |_) | |_) \__ \
#           |_|  \_\__,_|_|_|___/_/    \_\ .__/| .__/|___/
#                                        | |   | |
#                                        |_|   |_|
#
#   Application template.
#   Restrain your impulse to make changes to this file.
#
# >---------------------------------------------------------------------------<

# >----------------------------[ Initial Setup ]------------------------------<

module Gemfile
  class GemInfo
    def initialize(name) @name=name; @group=[]; @opts={}; end
    attr_accessor :name, :version
    attr_reader :group, :opts

    def opts=(new_opts={})
      new_group = new_opts.delete(:group)
      if (new_group && self.group != new_group)
        @group = ([self.group].flatten + [new_group].flatten).compact.uniq.sort
      end
      @opts = (self.opts || {}).merge(new_opts)
    end

    def group_key() @group end

    def gem_args_string
      args = ["'#{@name}'"]
      args << "'#{@version}'" if @version
      @opts.each do |name,value|
        args << ":#{name}=>#{value.inspect}"
      end
      args.join(', ')
    end
  end

  @geminfo = {}

  class << self
    # add(name, version, opts={})
    def add(name, *args)
      name = name.to_s
      version = args.first && !args.first.is_a?(Hash) ? args.shift : nil
      opts = args.first && args.first.is_a?(Hash) ? args.shift : {}
      @geminfo[name] = (@geminfo[name] || GemInfo.new(name)).tap do |info|
        info.version = version if version
        info.opts = opts
      end
    end

    def write
      File.open('Gemfile', 'a') do |file|
        file.puts
        grouped_gem_names.sort.each do |group, gem_names|
          indent = ""
          unless group.empty?
            file.puts "group :#{group.join(', :')} do" unless group.empty?
            indent="  "
          end
          gem_names.sort.each do |gem_name|
            file.puts "#{indent}gem #{@geminfo[gem_name].gem_args_string}"
          end
          file.puts "end" unless group.empty?
          file.puts
        end
      end
    end

    private
    #returns {group=>[...gem names...]}, ie {[:development, :test]=>['rspec-rails', 'mocha'], :assets=>[], ...}
    def grouped_gem_names
      {}.tap do |_groups|
        @geminfo.each do |gem_name, geminfo|
          (_groups[geminfo.group_key] ||= []).push(gem_name)
        end
      end
    end
  end
end
def add_gem(*all) Gemfile.add(*all); end

@recipes = ["core", "git", "railsapps", "setup", "readme", "gems", "testing", "email", "models", "controllers", "views", "routes", "frontend", "init", "apps4", "prelaunch", "saas", "extras"]
@prefs = {}
@gems = []
@diagnostics_recipes = [["example"],
                        ["setup"],
                        ["railsapps"],
                        ["gems", "setup"],
                        ["gems", "readme", "setup"],
                        ["extras", "gems", "readme", "setup"],
                        ["example", "git"],
                        ["git", "setup"],
                        ["git", "railsapps"],
                        ["gems", "git", "setup"],
                        ["gems", "git", "readme", "setup"],
                        ["extras", "gems", "git", "readme", "setup"],
                        ["controllers", "email", "extras", "frontend", "gems", "git", "init", "models", "railsapps", "readme", "routes", "setup", "testing", "views"],
                        ["controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "railsapps", "readme", "routes", "setup", "testing", "views"],
                        ["controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "setup", "testing", "views"],
                        ["controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "saas", "setup", "testing", "views"],
                        ["controllers", "email", "example", "extras", "frontend", "gems", "git", "init", "models", "railsapps", "readme", "routes", "setup", "testing", "views"],
                        ["controllers", "email", "example", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "setup", "testing", "views"],
                        ["controllers", "email", "example", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "saas", "setup", "testing", "views"],
                        ["apps4", "controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "saas", "setup", "testing", "views"]]
@diagnostics_prefs = [{:railsapps=>"none", :database=>"sqlite", :prod_database => "sqlite", :unit_test=>"rspec", :integration=>"rspec-capybara", :fixtures=>"factory_girl", :frontend=>"bootstrap", :bootstrap=>"sass", :email=>"none", :authentication=>"devise", :authorization=>"cancan", :form_builder=>"none", :starter_app=>"admin_app", :capistrano => false, :resque => false, :apiversions => false, :apipie => false}]
diagnostics = {}

# >-------------------------- templates/helpers.erb --------------------------start<
def recipes; @recipes end
def recipe?(name); @recipes.include?(name) end
def prefs; @prefs end
def prefer(key, value); @prefs[key].eql? value end
def gems; @gems end
def diagnostics_recipes; @diagnostics_recipes end
def diagnostics_prefs; @diagnostics_prefs end

def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end
def say_recipe(name); say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..." end
def say_wizard(text); say_custom(@current_recipe || 'composer', text) end

def rails_4?
  Rails::VERSION::MAJOR.to_s == "4"
end

def ask_wizard(question)
  ask "\033[1m\033[36m" + (@current_recipe || "prompt").rjust(10) + "\033[1m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

def no_wizard?(question); !yes_wizard?(question) end

def multiple_choice(question, choices)
  say_custom('question', question)
  values = {}
  choices.each_with_index do |choice,i|
    values[(i + 1).to_s] = choice[1]
    say_custom( (i + 1).to_s + ')', choice[0] )
  end
  answer = ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

@current_recipe = nil
@configs = {}

@after_blocks = []
def after_bundler(&block); @after_blocks << [@current_recipe, block]; end
@after_everything_blocks = []
def after_everything(&block); @after_everything_blocks << [@current_recipe, block]; end
@before_configs = {}
def before_config(&block); @before_configs[@current_recipe] = block; end

def copy_from(source, destination)
  begin
    remove_file destination
    get source, destination
  rescue OpenURI::HTTPError
    say_wizard "Unable to obtain #{source}"
  end
end

def copy_from_repo(filename, opts = {})
  repo = 'https://raw.github.com/KolomoetsOleg/rails_template/master/files/'
  repo = opts[:repo] unless opts[:repo].nil?
  if (!opts[:prefs].nil?) && (!prefs.has_value? opts[:prefs])
    return
  end
  source_filename = filename
  destination_filename = filename
  unless opts[:prefs].nil?
    if filename.include? opts[:prefs]
      destination_filename = filename.gsub(/\-#{opts[:prefs]}/, '')
    end
  end
  if (prefer :templates, 'haml') && (filename.include? 'views')
    remove_file destination_filename
    destination_filename = destination_filename.gsub(/.erb/, '.haml')
  end
  begin
    remove_file destination_filename
    if (prefer :templates, 'haml') && (filename.include? 'views')
      create_file destination_filename, html_to_haml(repo + source_filename)
    else
      get repo + source_filename, destination_filename
    end
  rescue OpenURI::HTTPError
    say_wizard "Unable to obtain #{source_filename} from the repo #{repo}"
  end
end

def html_to_haml(source)
  begin
    html = open(source) {|input| input.binmode.read }
    Haml::HTML.new(html, :erb => true, :xhtml => true).render
  rescue RubyParser::SyntaxError
    say_wizard "Ignoring RubyParser::SyntaxError"
    # special case to accommodate https://github.com/RailsApps/rails-composer/issues/55
    html = open(source) {|input| input.binmode.read }
    say_wizard "applying patch" if html.include? 'card_month'
    say_wizard "applying patch" if html.include? 'card_year'
    html = html.gsub(/, {add_month_numbers: true}, {name: nil, id: "card_month"}/, '')
    html = html.gsub(/, {start_year: Date\.today\.year, end_year: Date\.today\.year\+10}, {name: nil, id: "card_year"}/, '')
    result = Haml::HTML.new(html, :erb => true, :xhtml => true).render
    result = result.gsub(/select_month nil/, "select_month nil, {add_month_numbers: true}, {name: nil, id: \"card_month\"}")
    result = result.gsub(/select_year nil/, "select_year nil, {start_year: Date.today.year, end_year: Date.today.year+10}, {name: nil, id: \"card_year\"}")
  end
end


# full credit to @mislav in this StackOverflow answer for the #which() method:
# - http://stackoverflow.com/a/5471032
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
      return exe if File.executable? exe
    end
  end
  return nil
end
# >-------------------------- templates/helpers.erb --------------------------end<

if diagnostics_recipes.sort.include? recipes.sort
  diagnostics[:recipes] = 'success'
  say_wizard("WOOT! The recipes you've selected are known to work together.")
else
  diagnostics[:recipes] = 'fail'
  say_wizard("\033[1m\033[36m" + "WARNING! The recipes you've selected might not work together." + "\033[0m")
  say_wizard("Help us out by reporting whether this combination works or fails.")
  say_wizard("Please open an issue for rails_apps_composer on GitHub.")
  say_wizard("Your new application will contain diagnostics in its README file.")
  say_wizard("Continuing...")
end

# this application template only supports Rails version 3.1 and newer
case Rails::VERSION::MAJOR.to_s
  when "3"
    case Rails::VERSION::MINOR.to_s
      when "0"
        say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported. Try 3.1 or newer."
        raise StandardError.new "Rails #{Rails::VERSION::STRING} is not supported. Try 3.1 or newer."
    end
  when "4"
    say_wizard "You are using Rails version #{Rails::VERSION::STRING}."
  else
    say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported. Try 3.1 or newer."
    raise StandardError.new "Rails #{Rails::VERSION::STRING} is not supported. Try 3.1 or newer."
end

say_wizard "Using rails_apps_composer recipes to generate an application."

# >---------------------------[ Autoload Modules/Classes ]-----------------------------<

inject_into_file 'config/application.rb', :after => 'config.autoload_paths += %W(#{config.root}/extras)' do <<-'RUBY'

    config.autoload_paths += %W(#{config.root}/lib)
RUBY
end

# >---------------------------------[ Recipes ]----------------------------------<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ core ]----------------------------------<
@current_recipe = "core"
@before_configs["core"].call if @before_configs["core"]
say_recipe 'core'
@configs[@current_recipe] = config
# >----------------------------- recipes/core.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/core.rb

## Git
say_wizard "selected all core recipes"
# >----------------------------- recipes/core.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >----------------------------------[ git ]----------------------------------<
@current_recipe = "git"
@before_configs["git"].call if @before_configs["git"]
say_recipe 'git'
@configs[@current_recipe] = config
# >----------------------------- recipes/git.rb ------------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/git.rb

## Git
say_wizard "initialize git"
prefs[:git] = true unless prefs.has_key? :git
if prefer :git, true
  copy_from 'https://raw.github.com/KolomoetsOleg/rails_template/master/files/gitignore.txt', '.gitignore'
  git :init
  git :add => '-A'
  git :commit => '-qm "rails_template: initial commit"'
else
  after_everything do
    say_wizard "removing .gitignore and .gitkeep files"
    git_files = Dir[File.join('**','.gitkeep')] + Dir[File.join('**','.gitignore')]
    File.unlink git_files
  end
end
# >----------------------------- recipes/git.rb ------------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ railsapps ]-------------------------------<
@current_recipe = "railsapps"
@before_configs["railsapps"].call if @before_configs["railsapps"]
say_recipe 'railsapps'
@configs[@current_recipe] = config
# >-------------------------- recipes/railsapps.rb ---------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/railsapps.rb

raise if (defined? defaults) || (defined? preferences) # Shouldn't happen.
if options[:verbose]
  print "\nrecipes: ";p recipes
  print "\ngems: "   ;p gems
  print "\nprefs: "  ;p prefs
  print "\nconfig: " ;p config
end

case Rails::VERSION::MAJOR.to_s
  when "3"
    prefs[:railsapps] = multiple_choice "Install an example application for Rails 3.2?",
                                        [["I want to build my own application", "none"]] unless prefs.has_key? :railsapps
  when "4"
    prefs[:apps4] = multiple_choice "Install an example application for Rails 4.0?", [["I want to build my own application", "none"]] unless prefs.has_key? :apps4
end

# >-------------------------- recipes/railsapps.rb ---------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ setup ]---------------------------------<
@current_recipe = "setup"
@before_configs["setup"].call if @before_configs["setup"]
say_recipe 'setup'
@configs[@current_recipe] = config
# >---------------------------- recipes/setup.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/setup.rb

## Ruby on Rails
HOST_OS = RbConfig::CONFIG['host_os']
say_wizard "Your operating system is #{HOST_OS}."
say_wizard "You are using Ruby version #{RUBY_VERSION}."
say_wizard "You are using Rails version #{Rails::VERSION::STRING}."

## Is sqlite3 in the Gemfile?
gemfile = File.read(destination_root() + '/Gemfile')
sqlite_detected = gemfile.include? 'sqlite3'

## Web Server
prefs[:dev_webserver] = multiple_choice "Web server for development?", [["WEBrick (default)", "webrick"], ["Unicorn", "unicorn"]] unless prefs.has_key? :dev_webserver
prefs[:prod_webserver] = multiple_choice "Web server for production?", [["Unicorn+Nginx", "unicorn_nginx"], ["Unicorn+apache", "unicorn_apache"],
                                                                        ["Passenger+Nginx", "passenger_nginx"], ["Passenger+apache", "passenger_apache"]] unless prefs.has_key? :prod_webserver

## Database Adapter
prefs[:database] = multiple_choice "Database used in development?", [["SQLite", "sqlite"], ["PostgreSQL", "postgresql"],
                                                                     ["MySQL", "mysql"]] unless prefs.has_key? :database
## Production Database Adapter
prefs[:prod_database] = multiple_choice "Database used in production?", [["SQLite", "sqlite"], ["PostgreSQL", "postgresql"],
                                                                         ["MySQL", "mysql"]] unless prefs.has_key? :prod_database

## Template Engine
prefs[:templates] = multiple_choice "Template engine?", [["ERB", "erb"], ["Haml", "haml"]] unless prefs.has_key? :templates

## Testing Framework
if recipes.include? 'testing'
  prefs[:unit_test] = multiple_choice "Unit testing?", [["Test::Unit", "test_unit"], ["RSpec", "rspec"]] unless prefs.has_key? :unit_test
  prefs[:integration] = multiple_choice "Integration testing?", [["None", "none"], ["RSpec with Capybara", "rspec-capybara"],
                                                                 ["Cucumber with Capybara", "cucumber"]] unless prefs.has_key? :integration
  prefs[:fixtures] = multiple_choice "Fixture replacement?", [["None","none"], ["Factory Girl","factory_girl"]] unless prefs.has_key? :fixtures
end

## Front-end Framework
if recipes.include? 'frontend'
  prefs[:frontend] = multiple_choice "Front-end framework?", [["None", "none"],["Twitter Bootstrap 3.0", "bootstrap3"], ["Twitter Bootstrap 2.3", "bootstrap2"]] unless prefs.has_key? :frontend
end

## Email
if recipes.include? 'email'
  prefs[:email] = multiple_choice "Add support for sending email?", [["None", "none"], ["Gmail","gmail"], ["SMTP","smtp"]] unless prefs.has_key? :email
else
  prefs[:email] = 'none'
end

## Authentication and Authorization
if recipes.include? 'models'
  prefs[:authentication] = multiple_choice "Authentication?", [["None", "none"], ["Devise", "devise"]] unless prefs.has_key? :authentication
  case prefs[:authentication]
    when 'devise'
      if rails_4?
        prefs[:devise_modules] = multiple_choice "Devise modules?", [["Devise with default modules","default"],
                                                                     ["Devise with Confirmable module","confirmable"],
                                                                     ["Devise with Confirmable and Invitable modules","invitable"]] unless prefs.has_key? :devise_modules
      else
        prefs[:devise_modules] = multiple_choice "Devise modules?", [["Devise with default modules","default"],
                                                                     ["Devise with Confirmable module","confirmable"]] unless prefs.has_key? :devise_modules
      end
  end
  prefs[:authorization] = multiple_choice "Authorization?", [["None", "none"], ["CanCan with Rolify", "cancan"]] unless prefs.has_key? :authorization
end

## Form Builder
prefs[:form_builder] = multiple_choice "Use a form builder gem?", [["None", "none"], ["SimpleForm", "simple_form"]] unless prefs.has_key? :form_builder

## MVC
if (recipes.include? 'models') && (recipes.include? 'controllers') && (recipes.include? 'views') && (recipes.include? 'routes')
  if prefer :authorization, 'cancan'
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"],
                                                                     ["Home Page, User Accounts", "users_app"], ["Home Page, User Accounts, Admin Dashboard", "admin_app"]] unless prefs.has_key? :starter_app
  elsif prefer :authentication, 'devise'
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"],
                                                                     ["Home Page, User Accounts", "users_app"]] unless prefs.has_key? :starter_app
  else
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"]] unless prefs.has_key? :starter_app
  end
end


##Deploing web application
config['capistrano'] = yes_wizard?("Install capistrano?") if true && true unless prefs.has_key? :capistrano

## Resque AND Resque_mailer
config['resque'] = yes_wizard?("Do you want to install resque and resque_mailer?") if true && true unless prefs.has_key? :resque


##APIVirsions and APIpie
config['apiversions'] = yes_wizard?("Install API Versions?") if true && true unless prefs.has_key? :apiversions
config['apipie'] = yes_wizard?("Install APIpie?") if true && true unless prefs.has_key? :apipie

# save diagnostics before anything can fail
create_file "README", "RECIPES\n#{recipes.sort.inspect}\n"
append_file "README", "PREFERENCES\n#{prefs.inspect}"
# >---------------------------- recipes/setup.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

## >-------------------------- templates/recipe.erb ---------------------------start<
## >--------------------------------[ readme ]---------------------------------<
#@current_recipe = "readme"
#@before_configs["readme"].call if @before_configs["readme"]
#say_recipe 'readme'
#@configs[@current_recipe] = config
## >---------------------------- recipes/readme.rb ----------------------------start<
#
## Application template recipe for the rails_apps_composer. Change the recipe here:
## https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/readme.rb
#
#after_everything do
#  say_wizard "recipe running after everything"
#
#  # remove default READMEs
#  %w{
#    README
#    README.rdoc
#    doc/README_FOR_APP
#  }.each { |file| remove_file file }
#
#  # add placeholder READMEs and humans.txt file
#  copy_from_repo 'public/humans.txt'
#  copy_from_repo 'README'
#  copy_from_repo 'README.textile'
#  gsub_file "README", /App_Name/, "#{app_name.humanize.titleize}"
#  gsub_file "README.textile", /App_Name/, "#{app_name.humanize.titleize}"
#
#  # Diagnostics
#  gsub_file "README.textile", /recipes that are known/, "recipes that are NOT known" if diagnostics[:recipes] == 'fail'
#  gsub_file "README.textile", /preferences that are known/, "preferences that are NOT known" if diagnostics[:prefs] == 'fail'
#  gsub_file "README.textile", /RECIPES/, recipes.sort.inspect
#  gsub_file "README.textile", /PREFERENCES/, prefs.inspect
#  gsub_file "README", /RECIPES/, recipes.sort.inspect
#  gsub_file "README", /PREFERENCES/, prefs.inspect
#
#  # Ruby on Rails
#  gsub_file "README.textile", /\* Ruby/, "* Ruby version #{RUBY_VERSION}"
#  gsub_file "README.textile", /\* Rails/, "* Rails version #{Rails::VERSION::STRING}"
#
#  # Database
#  gsub_file "README.textile", /SQLite/, "PostgreSQL" if prefer :database, 'postgresql'
#  gsub_file "README.textile", /SQLite/, "MySQL" if prefer :database, 'mysql'
#
#  # Template Engine
#  gsub_file "README.textile", /ERB/, "Haml" if prefer :templates, 'haml'
#
#  # Testing Framework
#  gsub_file "README.textile", /Test::Unit/, "RSpec" if prefer :unit_test, 'rspec'
#  gsub_file "README.textile", /RSpec/, "RSpec and Cucumber" if prefer :integration, 'cucumber'
#  gsub_file "README.textile", /RSpec/, "RSpec and Factory Girl" if prefer :fixtures, 'factory_girl'
#
#  # Front-end Framework
#  gsub_file "README.textile", /Front-end Framework: None/, "Front-end Framework: Twitter Bootstrap 2.3 (Sass)" if prefer :frontend, 'bootstrap2'
#  gsub_file "README.textile", /Front-end Framework: None/, "Front-end Framework: Twitter Bootstrap 3.0 (Sass)" if prefer :frontend, 'bootstrap3'
#
#  # Form Builder
#  gsub_file "README.textile", /Form Builder: None/, "Form Builder: SimpleForm" if prefer :form_builder, 'simple_form'
#
#  # Email
#  unless prefer :email, 'none'
#    gsub_file "README.textile", /Gmail/, "SMTP" if prefer :email, 'smtp'
#  else
#    gsub_file "README.textile", /h2. Email/, ""
#    gsub_file "README.textile", /The application is configured to send email using a Gmail account./, ""
#  end
#
#  # Authentication and Authorization
#  gsub_file "README.textile", /Authentication: None/, "Authentication: Devise" if prefer :authentication, 'devise'
#  gsub_file "README.textile", /Authorization: None/, "Authorization: CanCan" if prefer :authorization, 'cancan'
#
#  git :add => '-A' if prefer :git, true
#  git :commit => '-qm "rails_apps_composer: add README files"' if prefer :git, true
#
#end # after_everything
## >---------------------------- recipes/readme.rb ----------------------------end<
## >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ gems ]----------------------------------<
@current_recipe = "gems"
@before_configs["gems"].call if @before_configs["gems"]
say_recipe 'gems'
@configs[@current_recipe] = config
# >----------------------------- recipes/gems.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/gems.rb

### GEMFILE ###

## Ruby on Rails
insert_into_file('Gemfile', "ruby '#{RUBY_VERSION}'\n", :before => /^ *gem 'rails'/, :force => false)

## Cleanup
# remove the 'sdoc' gem
gsub_file 'Gemfile', /group :doc do/, ''
gsub_file 'Gemfile', /\s*gem 'sdoc', require: false\nend/, ''

assets_group = rails_4? ? nil : :assets

## Web Server
add_gem 'unicorn', :group => [:development, :test] if prefer :dev_webserver, 'unicorn'
case prefs[:prod_webserver]
  when 'unicorn_nginx'
    add_gem 'unicorn', :group => :production
    add_gem 'capistrano-unicorn', :group => :development, :require => false
    copy_from_repo 'config/unicorn-unicorn_nginx.rb', :prefs => 'unicorn_nginx'
    copy_from_repo 'config/deploy-unicorn_nginx.rb', :prefs => 'unicorn_nginx' if config['capistrano']
  when 'unicorn_apache'
    add_gem 'unicorn', :group => :production
    add_gem 'capistrano-unicorn', :group => :development, :require => false
    copy_from_repo 'config/unicorn-unicorn_apache.rb', :prefs => 'unicorn_apache'
    copy_from_repo 'config/deploy-unicorn_apache.rb', :prefs => 'unicorn_apache' if config['capistrano']
  when 'passenger_nginx'
    add_gem 'passenger', :group => :production
    copy_from_repo 'config/unicorn.rb'
    copy_from_repo 'config/deploy-unicorn_apache.rb' if config['capistrano']
  when 'passenger_apache'
    add_gem 'passenger', :group => :production
    copy_from_repo 'config/unicorn.rb'
    copy_from_repo 'config/deploy.rb' if config['capistrano']

end



## Database Adapter

## Development Database Adapter
gsub_file 'Gemfile', /gem 'sqlite3'\n/, '' unless prefer :database, 'sqlite'
gsub_file 'Gemfile', /gem 'pg'.*/, ''
add_gem 'pg' if prefer :database, 'postgresql'
gsub_file 'Gemfile', /gem 'mysql2'.*/, ''
add_gem 'mysql2' if prefer :database, 'mysql'

## Production Database Adapter
gsub_file 'Gemfile', /gem 'sqlite3'\n/, '' unless prefer :database, 'sqlite'
gsub_file 'Gemfile', /gem 'pg'.*/, ''
add_gem 'pg', :group => [:production] if prefer :prod_database, 'postgresql'
gsub_file 'Gemfile', /gem 'mysql2'.*/, ''
add_gem 'mysql2', :group => [:production] if prefer :prod_database, 'mysql'

##Capistrano
if config['capistrano']
  prefs[:capistrano] = true
end

if prefs[:capistrano]
  add_gem 'capistrano', :group => [:development]
  add_gem 'capistrano-ext', :group => [:development]
  add_gem 'rvm-capistrano', :group => [:development]
  add_gem 'capistrano-unicorn', :group => [:development], :require => false
  copy_from_repo 'config/deploy/production.rb'
  copy_from_repo 'config/deploy/staging.rb'
  server_name = prefs[:server_name] || ask_wizard("Enter server name for deploy:")
  gsub_file 'config/deploy/production.rb', /<server_address>/, server_name
  gsub_file 'config/deploy/staging.rb', /<server_address>/, server_name
  branch_name = prefs[:branch_name] || ask_wizard("Enter branch name for deploy:")
  gsub_file 'config/deploy/production.rb', /<branch_for_staging>/, branch_name
  gsub_file 'config/deploy/staging.rb', /<branch_for_staging>/, branch_name
  run "capify ."
end

## REsque and Resque_mailer
if config['resque']
  prefs[:resque] = true
end

if prefs[:resque]
  add_gem 'resque'
  add_gem 'resque_mailer'
end


##API Versions AND AIEpie
if config['apiversions']
  prefs[:apiversions] = true
end
if config['apipie']
  prefs[:apipie] = true
end

add_gem 'api-versions' if prefs[:apiversions]
add_gem 'apipie-rails' if prefs[:apipie]

add_gem 'bcrypt-ruby'


## Template Engine
if prefer :templates, 'haml'
  add_gem 'haml-rails'
  add_gem 'html2haml', :group => :development
end

## Testing Framework
if prefer :unit_test, 'rspec'
  add_gem 'rspec-rails', :group => [:development, :test]
  add_gem 'capybara', :group => :test if prefer :integration, 'rspec-capybara'
  add_gem 'database_cleaner', '1.0.1', :group => :test
  add_gem 'email_spec', :group => :test
end
if prefer :integration, 'cucumber'
  add_gem 'cucumber-rails', :group => :test, :require => false
  add_gem 'database_cleaner', '1.0.1', :group => :test unless prefer :unit_test, 'rspec'
  add_gem 'launchy', :group => :test
  add_gem 'capybara', :group => :test
end
add_gem 'factory_girl_rails', :group => [:development, :test] if prefer :fixtures, 'factory_girl'

## Front-end Framework
add_gem 'rails_layout', :group => :development
case prefs[:frontend]
  when 'bootstrap2'
    add_gem 'bootstrap-sass', '~> 2.3.2.2'
  when 'bootstrap3'
    add_gem 'bootstrap-sass', '>= 3.0.0.0'
end

## Authentication (Devise)
add_gem 'devise' if prefer :authentication, 'devise'
add_gem 'devise_invitable' if prefer :devise_modules, 'invitable'

## Authorization
if prefer :authorization, 'cancan'
  add_gem 'cancan'
  add_gem 'rolify'
end

## Form Builder
add_gem 'simple_form' if prefer :form_builder, 'simple_form'

## Gems from a defaults file or added interactively
gems.each do |g|
  gem(*g)
end

## Git
git :add => '-A' if prefer :git, true
git :commit => '-qm "rails_template: Gemfile"' if prefer :git, true

### CREATE DATABASE ###
after_bundler do
  copy_from_repo 'config/database-postgresql.yml', :prefs => 'postgresql' if prefer :database, 'postgresql'
  copy_from_repo 'config/database-mysql.yml', :prefs => 'mysql' if prefer :database, 'mysql'

  if prefer :database, 'sqlite'
    config =  <<-TEXT

production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
    TEXT

    gsub_file 'config/database.yml', config, ""
  end

  case prefs[:prod_database]
    when  'postgresql'
      config = <<-TEXT

production:
  adapter:  postgresql
  host:     localhost
  encoding: unicode
  database: myapp_production
  pool:     5
  username: myapp
  password:
  template: template0

      TEXT
      append_to_file  'config/database.yml', config

    when 'mysql'
      config = <<-TEXT

production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: myapp_production
  pool: 5
  username: root
  password:
  host: localhost
      TEXT
      append_to_file  'config/database.yml', config
    when 'sqlite'
      config = <<-TEXT

production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
      TEXT
      append_to_file  'config/database.yml', config
    else
      say_wizard "Something went wrong"
  end

  if prefer :database, 'postgresql'
    begin
      pg_username = prefs[:pg_username] || ask_wizard("Username for PostgreSQL?(leave blank to use the app name)")
      if pg_username.blank?
        say_wizard "Creating a user named '#{app_name}' for PostgreSQL"
        run "createuser #{app_name}" if prefer :database, 'postgresql'
        gsub_file "config/database.yml", /username: .*/, "username: #{app_name}"
      else
        gsub_file "config/database.yml", /username: .*/, "username: #{pg_username}"
        pg_password = prefs[:pg_password] || ask_wizard("Password for PostgreSQL user #{pg_username}?")
        gsub_file "config/database.yml", /password:/, "password: #{pg_password}"
        say_wizard "set config/database.yml for username/password #{pg_username}/#{pg_password}"
      end
    rescue StandardError => e
      raise "unable to create a user for PostgreSQL, reason: #{e}"
    end
    gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
    gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
    gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
  end


  if prefer :database, 'mysql'
    mysql_username = prefs[:mysql_username] || ask_wizard("Username for MySQL? (leave blank to use the app name)")
    if mysql_username.blank?
      gsub_file "config/database.yml", /username: .*/, "username: #{app_name}"
    else
      gsub_file "config/database.yml", /username: .*/, "username: #{mysql_username}"
      mysql_password = prefs[:mysql_password] || ask_wizard("Password for MySQL user #{mysql_username}?")
      gsub_file "config/database.yml", /password:/, "password: #{mysql_password}"
      say_wizard "set config/database.yml for username/password #{mysql_username}/#{mysql_password}"
    end
    gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
    gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
    gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
  end
  unless prefer :database, 'sqlite'
    if (prefs.has_key? :drop_database) ? prefs[:drop_database] :
        (yes_wizard? "Okay to drop all existing databases named #{app_name}? 'No' will abort immediately!")
      run 'rake db:drop'
    else
      raise "aborted at user's request"
    end
  end
  ## Git
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: create database"' if prefer :git, true
end # after_bundler

### GENERATORS ###
after_bundler do
  ## Form Builder
  if prefer :form_builder, 'simple_form'
    case prefs[:frontend]
      when 'bootstrap2'
        say_wizard "recipe installing simple_form for use with Twitter Bootstrap"
        generate 'simple_form:install --bootstrap'
      when 'bootstrap3'
        say_wizard "recipe installing simple_form for use with Twitter Bootstrap"
        generate 'simple_form:install --bootstrap'
      else
        say_wizard "recipe installing simple_form"
        generate 'simple_form:install'
    end
  end
  ## Figaro Gem
  if prefs[:local_env_file]
    generate 'figaro:install'
    gsub_file 'config/application.yml', /# PUSHER_.*\n/, ''
    gsub_file 'config/application.yml', /# STRIPE_.*\n/, ''
    prepend_to_file 'config/application.yml' do <<-FILE
# Add account credentials and API keys here.
# See http://railsapps.github.io/rails-environment-variables.html
# This file should be listed in .gitignore to keep your settings secret!
# Each entry sets a local environment variable and overrides ENV variables in the Unix shell.
# For example, setting:
# GMAIL_USERNAME: Your_Gmail_Username
# makes 'Your_Gmail_Username' available as ENV["GMAIL_USERNAME"]

    FILE
    end
  end
  ## Git
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: generators"' if prefer :git, true
end # after_bundler
# >----------------------------- recipes/gems.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ testing ]--------------------------------<
@current_recipe = "testing"
@before_configs["testing"].call if @before_configs["testing"]
say_recipe 'testing'
@configs[@current_recipe] = config
# >--------------------------- recipes/testing.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/testing.rb

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  ### TEST/UNIT ###
  if prefer :unit_test, 'test_unit'
    inject_into_file 'config/application.rb', :after => "Rails::Application\n" do <<-RUBY

    RUBY
    end
  end

  ### RSPEC ###
  if prefer :unit_test, 'rspec'
    say_wizard "recipe installing RSpec"
    generate 'rspec:install'
    copy_from_repo 'spec/spec_helper.rb'
    generate 'email_spec:steps' if prefer :integration, 'cucumber'
    inject_into_file 'spec/spec_helper.rb', "require 'email_spec'\n", :after => "require 'rspec/rails'\n"
    inject_into_file 'spec/spec_helper.rb', :after => "RSpec.configure do |config|\n" do <<-RUBY
      config.include(EmailSpec::Helpers)
      config.include(EmailSpec::Matchers)
    RUBY
    end
    run 'rm -rf test/' # Removing test folder (not needed for RSpec)
    inject_into_file 'config/application.rb', :after => "Rails::Application\n" do <<-RUBY

      # don't generate RSpec tests for views and helpers
      config.generators do |g|
        g.view_specs false
        g.helper_specs false
      end

    RUBY
    end
                       ## RSPEC AND DEVISE
    if prefer :authentication, 'devise'
      # add Devise test helpers
      create_file 'spec/support/devise.rb' do
        <<-RUBY
          RSpec.configure do |config|
            config.include Devise::TestHelpers, :type => :controller
          end
        RUBY
      end
    end
  end
  ### CUCUMBER ###
  if prefer :integration, 'cucumber'
    say_wizard "recipe installing Cucumber"
    generate "cucumber:install --capybara#{' --rspec' if prefer :unit_test, 'rspec'}#{' -D' if prefer :orm, 'mongoid'}"
    # make it easy to run Cucumber for single features without adding "--require features" to the command line
    gsub_file 'config/cucumber.yml', /std_opts = "/, 'std_opts = "-r features/support/ -r features/step_definitions '
    create_file 'features/support/email_spec.rb' do <<-RUBY
      require 'email_spec/cucumber'
    RUBY
    end
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: testing framework"' if prefer :git, true
end # after_bundler

after_everything do
  say_wizard "recipe running after everything"
  ### RSPEC ###
  if prefer :unit_test, 'rspec'
    if (prefer :authentication, 'devise') && (prefer :starter_app, 'users_app')
      say_wizard "copying RSpec files from the rails_template"
      copy_from_repo 'spec/factories/users.rb'
      gsub_file 'spec/factories/users.rb', /# confirmed_at/, "confirmed_at" if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
      copy_from_repo 'spec/controllers/home_controller_spec.rb'
      copy_from_repo 'spec/controllers/users_controller_spec.rb'
      copy_from_repo 'spec/models/user_spec.rb'
      remove_file 'spec/views/home/index.html.erb_spec.rb'
      remove_file 'spec/views/home/index.html.haml_spec.rb'
      remove_file 'spec/views/users/show.html.erb_spec.rb'
      remove_file 'spec/views/users/show.html.haml_spec.rb'
      remove_file 'spec/helpers/home_helper_spec.rb'
      remove_file 'spec/helpers/users_helper_spec.rb'
    end
    if (prefer :authentication, 'devise') && (prefer :starter_app, 'admin_app')
      say_wizard "copying RSpec files from the rails_template"
      copy_from_repo 'spec/factories/users.rb'
      gsub_file 'spec/factories/users.rb', /# confirmed_at/, "confirmed_at" if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
      copy_from_repo 'spec/controllers/home_controller_spec.rb'
      copy_from_repo 'spec/controllers/users_controller_spec.rb'
      copy_from_repo 'spec/models/user_spec.rb'
      remove_file 'spec/views/home/index.html.erb_spec.rb'
      remove_file 'spec/views/home/index.html.haml_spec.rb'
      remove_file 'spec/views/users/show.html.erb_spec.rb'
      remove_file 'spec/views/users/show.html.haml_spec.rb'
      remove_file 'spec/helpers/home_helper_spec.rb'
      remove_file 'spec/helpers/users_helper_spec.rb'
    end
    ## GIT
    git :add => '-A' if prefer :git, true
    git :commit => '-qm "rails_template: rspec files"' if prefer :git, true
  end
  ### CUCUMBER ###
  if prefer :integration, 'cucumber'
    ## CUCUMBER AND DEVISE (USERS APP)
    if (prefer :authentication, 'devise') && (prefer :starter_app, 'users_app')
      say_wizard "copying Cucumber scenarios from the rails_template"
      copy_from_repo 'spec/controllers/home_controller_spec.rb'
      copy_from_repo 'features/users/sign_in.feature'
      copy_from_repo 'features/users/sign_out.feature'
      copy_from_repo 'features/users/sign_up.feature'
      copy_from_repo 'features/users/user_edit.feature'
      copy_from_repo 'features/users/user_show.feature'
      copy_from_repo 'features/step_definitions/user_steps.rb'
      copy_from_repo 'features/support/paths.rb'
      if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
        gsub_file 'features/step_definitions/user_steps.rb', /Welcome! You have signed up successfully./, "A message with a confirmation link has been sent to your email address."
        inject_into_file 'features/users/sign_in.feature', :before => '    Scenario: User signs in successfully' do
          <<-RUBY
            Scenario: User has not confirmed account
            Given I exist as an unconfirmed user
            And I am not logged in
            When I sign in with valid credentials
            Then I see an unconfirmed account message
            And I should be signed out
          RUBY
        end
      end
    end
    ## CUCUMBER AND DEVISE (ADMIN APP)
    if (prefer :authentication, 'devise') && (prefer :starter_app, 'admin_app')
      say_wizard "copying Cucumber scenarios from the rails_template"
      copy_from_repo 'spec/controllers/home_controller_spec.rb'
      copy_from_repo 'features/users/sign_in.feature'
      copy_from_repo 'features/users/sign_out.feature'
      copy_from_repo 'features/users/sign_up.feature'
      copy_from_repo 'features/users/user_edit.feature'
      copy_from_repo 'features/users/user_show.feature'
      copy_from_repo 'features/step_definitions/user_steps.rb'
      copy_from_repo 'features/support/paths.rb'
      if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
        gsub_file 'features/step_definitions/user_steps.rb', /Welcome! You have signed up successfully./, "A message with a confirmation link has been sent to your email address."
        inject_into_file 'features/users/sign_in.feature', :before => '    Scenario: User signs in successfully' do
          <<-RUBY
            Scenario: User has not confirmed account
            Given I exist as an unconfirmed user
            And I am not logged in
            When I sign in with valid credentials
            Then I see an unconfirmed account message
            And I should be signed out
          RUBY
        end
      end
    end
    ## GIT
    git :add => '-A' if prefer :git, true
    git :commit => '-qm "rails_template: cucumber files"' if prefer :git, true
  end
end # after_everything
# >--------------------------- recipes/testing.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<


# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ email ]---------------------------------<
@current_recipe = "email"
@before_configs["email"].call if @before_configs["email"]
say_recipe 'email'
@configs[@current_recipe] = config
# >---------------------------- recipes/email.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/email.rb

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  if prefer :email, 'none'
    send_email_text = <<-TEXT

  # Send email in development mode.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    TEXT
    inject_into_file 'config/environments/development.rb', send_email_text, :after => "config.assets.debug = true"
  end


  if prefer :email, 'smtp'
    if rails_4?
      send_email_text = <<-TEXT

  # Send email in development mode.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
      TEXT
      inject_into_file 'config/environments/development.rb', send_email_text, :after => "config.assets.debug = true"
    else
      ### DEVELOPMENT
      gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# ActionMailer Config'
      gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
        <<-RUBY
        config.action_mailer.default_url_options = { :host => 'localhost:3000' }
        config.action_mailer.delivery_method = :smtp
        # change to true to allow email to be sent during development
        config.action_mailer.perform_deliveries = false
        config.action_mailer.raise_delivery_errors = true
        config.action_mailer.default :charset => "utf-8"
        RUBY
      end
      ### TEST
      inject_into_file 'config/environments/test.rb', :before => "\nend" do
        <<-RUBY
          \n
           # ActionMailer Config
           config.action_mailer.default_url_options = { :host => 'example.com' }
        RUBY
      end
      ### PRODUCTION
      gsub_file 'config/environments/production.rb', /config.active_support.deprecation = :notify/ do
        <<-RUBY
          config.active_support.deprecation = :notify

          config.action_mailer.default_url_options = { :host => 'example.com' }
          # ActionMailer Config
          # Setup for production - deliveries, no errors raised
          config.action_mailer.delivery_method = :smtp
          config.action_mailer.perform_deliveries = true
          config.action_mailer.raise_delivery_errors = false
          config.action_mailer.default :charset => "utf-8"
        RUBY
      end
    end
  end
  ### GMAIL ACCOUNT
  if prefer :email, 'gmail'
    gmail_configuration_text = <<-TEXT
      \n
      config.action_mailer.smtp_settings = {
        address: "smtp.gmail.com",
        port: 587,
        domain: ENV["DOMAIN_NAME"],
        authentication: "plain",
        enable_starttls_auto: true,
        user_name: ENV["GMAIL_USERNAME"],
        password: ENV["GMAIL_PASSWORD"]
      }
    TEXT
    inject_into_file 'config/environments/development.rb', gmail_configuration_text, :after => "config.assets.debug = true"
    inject_into_file 'config/environments/production.rb', gmail_configuration_text, :after => "config.active_support.deprecation = :notify"
  end
  ### GIT
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: set email accounts"' if prefer :git, true
end # after_bundler
# >---------------------------- recipes/email.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<


# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ models ]---------------------------------<
@current_recipe = "models"
@before_configs["models"].call if @before_configs["models"]
say_recipe 'models'
@configs[@current_recipe] = config
# >---------------------------- recipes/models.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/models.rb

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  ### DEVISE ###
  if prefer :authentication, 'devise'
    # prevent logging of password_confirmation
    gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'
    generate 'devise:install'
    generate 'devise_invitable:install' if prefer :devise_modules, 'invitable'
    generate 'devise user' # create the User model
                           ## DEVISE AND ACTIVE RECORD
    generate 'migration AddNameToUsers name:string'
    copy_from_repo 'app/models/user.rb' unless rails_4?
    if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
      gsub_file 'app/models/user.rb', /:registerable,/, ":registerable, :confirmable,"
      generate 'migration AddConfirmableToUsers confirmation_token:string confirmed_at:datetime confirmation_sent_at:datetime unconfirmed_email:string'
    end
  end
  ##APIpie
  if prefs[:apipie]
    generate 'apipie:install'
  end
  ## DEVISE AND CUCUMBER
  if prefer :integration, 'cucumber'
    # Cucumber wants to test GET requests not DELETE requests for destroy_user_session_path
    # (see https://github.com/RailsApps/rails3-devise-rspec-cucumber/issues/3)
    gsub_file 'config/initializers/devise.rb', 'config.sign_out_via = :delete', 'config.sign_out_via = Rails.env.test? ? :get : :delete'
  end
  ### AUTHORIZATION ###
  if prefer :authorization, 'cancan'
    generate 'cancan:ability'
    if prefer :starter_app, 'admin_app'
      # Limit access to the users#index page
      copy_from_repo 'app/models/ability.rb', :repo => 'https://raw.github.com/RailsApps/rails3-bootstrap-devise-cancan/master/'
      # allow an admin to update roles
      insert_into_file 'app/models/user.rb', "  attr_accessible :role_ids, :as => :admin\n", :before => "  attr_accessible"
    end
    generate 'rolify:role Role User'
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: models"' if prefer :git, true
end # after_bundler
# >---------------------------- recipes/models.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<


# >-------------------------- templates/recipe.erb ---------------------------start<
# >------------------------------[ controllers ]------------------------------<
@current_recipe = "controllers"
@before_configs["controllers"].call if @before_configs["controllers"]
say_recipe 'controllers'
@configs[@current_recipe] = config
# >------------------------- recipes/controllers.rb --------------------------start<

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  ### APPLICATION_CONTROLLER ###
  if prefer :authorization, 'cancan'
    inject_into_file 'app/controllers/application_controller.rb', :before => "\nend" do <<-RUBY
      \n
      rescue_from CanCan::AccessDenied do |exception|
        redirect_to root_path, :alert => exception.message
      end
    RUBY
    end
  end
  ### HOME_CONTROLLER ###
  if ['home_app','users_app','admin_app'].include? prefs[:starter_app]
    generate(:controller, "home index")
  end
  if ['users_app','admin_app'].include? prefs[:starter_app]
    gsub_file 'app/controllers/home_controller.rb', /def index/, "def index\n    @users = User.all"
  end
  ### USERS_CONTROLLER ###
  copy_from_repo 'app/controllers/users_controller.rb'

  ### REGISTRATIONS_CONTROLLER ###
  if rails_4?
    if ['users_app','admin_app'].include? prefs[:starter_app]
      ## accommodate strong parameters in Rails 4
      copy_from_repo 'app/controllers/registrations_controller-devise.rb', :prefs => 'devise'
    end
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: controllers"' if prefer :git, true
end # after_bundler
# >------------------------- recipes/controllers.rb --------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<


# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ views ]---------------------------------<
@current_recipe = "views"
@before_configs["views"].call if @before_configs["views"]
say_recipe 'views'
@configs[@current_recipe] = config
# >---------------------------- recipes/views.rb -----------------------------start<

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  ### DEVISE ###
  if prefer :authentication, 'devise'
    copy_from_repo 'app/views/devise/shared/_links.html.erb'
    unless prefer :form_builder, 'simple_form'
      copy_from_repo 'app/views/devise/registrations/edit.html.erb'
      copy_from_repo 'app/views/devise/registrations/new.html.erb'
    else
      copy_from_repo 'app/views/devise/registrations/edit-simple_form.html.erb', :prefs => 'simple_form'
      copy_from_repo 'app/views/devise/registrations/new-simple_form.html.erb', :prefs => 'simple_form'
      copy_from_repo 'app/views/devise/sessions/new-simple_form.html.erb', :prefs => 'simple_form'
      copy_from_repo 'app/helpers/application_helper-simple_form.rb', :prefs => 'simple_form'
    end
  end
  ### HOME ###
  copy_from_repo 'app/views/home/index.html.erb'
  ### USERS ###
  if ['users_app','admin_app'].include? prefs[:starter_app]
    ## INDEX
    if prefer :starter_app, 'admin_app'
      copy_from_repo 'app/views/users/index-admin_app.html.erb', :prefs => 'admin_app'
      unless prefer :form_builder, 'simple_form'
        copy_from_repo 'app/views/users/_user.html.erb'
      else
        copy_from_repo 'app/views/users/_user-simple_form.html.erb', :prefs => 'simple_form'
      end
    end
    ## SHOW
    copy_from_repo 'app/views/users/show.html.erb'
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: views"' if prefer :git, true
end # after_bundler
# >---------------------------- recipes/views.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ routes ]---------------------------------<
@current_recipe = "routes"
@before_configs["routes"].call if @before_configs["routes"]
say_recipe 'routes'
@configs[@current_recipe] = config
# >---------------------------- recipes/routes.rb ----------------------------start<

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  ### HOME ###
  if prefer :starter_app, 'home_app'
    remove_file 'public/index.html'
    gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'
  end
  ### USER_ACCOUNTS ###
  if ['users_app','admin_app'].include? prefs[:starter_app]
    ## DEVISE
    if prefer :authentication, 'devise'
      copy_from_repo 'config/routes.rb', :repo => 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/'
      ## Rails 4.0 doesn't allow two 'root' routes
      gsub_file 'config/routes.rb', /authenticated :user do\n.*\n.*\n  /, '' if rails_4?
      ## accommodate strong parameters in Rails 4
      gsub_file 'config/routes.rb', /devise_for :users/, 'devise_for :users, :controllers => {:registrations => "registrations"}' if rails_4?
    end
  end
  ### CORRECT APPLICATION NAME ###
  gsub_file 'config/routes.rb', /^.*.routes.draw do/, "#{app_const}.routes.draw do"
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: routes"' if prefer :git, true
end # after_bundler
# >---------------------------- recipes/routes.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<

# >-------------------------- templates/recipe.erb ---------------------------start<
# >-------------------------------[ frontend ]--------------------------------<
@current_recipe = "frontend"
@before_configs["frontend"].call if @before_configs["frontend"]
say_recipe 'frontend'
@configs[@current_recipe] = config
# >--------------------------- recipes/frontend.rb ---------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/frontend.rb

after_bundler do
  say_wizard "recipe running after 'bundle install'"
  # set up a front-end framework using the rails_layout gem
  case prefs[:frontend]
    when 'simple'
      generate 'layout simple -f'
    when 'bootstrap2'
      generate 'layout bootstrap2 -f'
    when 'bootstrap3'
      generate 'layout bootstrap3 -f'
  end

  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: front-end framework"' if prefer :git, true
end # after_bundler

after_everything do
  say_wizard "recipe running after everything"
  # create navigation links using the rails_layout gem
  generate 'navigation -f'
  # replace with specialized navigation partials
  if prefer :authentication, 'omniauth'
    if prefer :authorization, 'cancan'
      copy_from 'https://raw.github.com/RailsApps/rails-composer/master/files/app/views/layouts/_navigation-cancan-omniauth.html.erb', 'app/views/layouts/_navigation.html.erb'
    else
      copy_from_repo 'app/views/layouts/_navigation-omniauth.html.erb', :prefs => 'omniauth'
    end
  end

  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: navigation links"' if prefer :git, true
end # after_everything
# >--------------------------- recipes/frontend.rb ---------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<



# >-------------------------- templates/recipe.erb ---------------------------start<
# >---------------------------------[ init ]----------------------------------<
@current_recipe = "init"
@before_configs["init"].call if @before_configs["init"]
say_recipe 'init'
@configs[@current_recipe] = config
# >----------------------------- recipes/init.rb -----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/init.rb

after_everything do
  say_wizard "recipe running after everything"
  ### CONFIGURATION FILE ###
  ## EMAIL
  case prefs[:email]
    when 'none'
      credentials = ''
    when 'smtp'
      credentials = ''
    when 'gmail'
      credentials = "GMAIL_USERNAME: Your_Username\nGMAIL_PASSWORD: Your_Password\n"
  end
  append_file 'config/application.yml', credentials if prefs[:local_env_file]
  if prefs[:local_env_file]
    ## DEFAULT USER
    unless prefer :starter_app, false
      append_file 'config/application.yml' do <<-FILE
ADMIN_NAME: First User
ADMIN_EMAIL: user@example.com
ADMIN_PASSWORD: changeme
      FILE
      end
    end
    ## AUTHORIZATION
    if (prefer :authorization, 'cancan')
      append_file 'config/application.yml', "ROLES: [admin, user, VIP]\n"
    end
  end
  ### APPLICATION.EXAMPLE.YML ###
  if prefs[:local_env_file]
    copy_file destination_root + '/config/application.yml', destination_root + '/config/application.example.yml'
  end
  ### DATABASE SEED ###
  if prefs[:local_env_file]
    append_file 'db/seeds.rb' do <<-FILE
# Environment variables (ENV['...']) can be set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html
    FILE
    end
  end
  if (prefer :authorization, 'cancan')
    append_file 'db/seeds.rb' do <<-FILE
puts 'ROLES'
YAML.load(ENV['ROLES']).each do |role|
  Role.find_or_create_by_name({ :name => role }, :without_protection => true)
  puts 'role: ' << role
end
    FILE
    end
    ## Fix db seed for Rails 4.0
    gsub_file 'db/seeds.rb', /{ :name => role }, :without_protection => true/, 'role' if rails_4?
  else
    append_file 'db/seeds.rb' do <<-FILE
puts 'ROLES'
YAML.load(ENV['ROLES']).each do |role|
  Role.mongo_session['roles'].insert({ :name => role })
  puts 'role: ' << role
end
    FILE
    end
  end
  ## DEVISE-DEFAULT
  if prefer :authentication, 'devise'
    append_file 'db/seeds.rb' do <<-FILE
puts 'DEFAULT USERS'
user = User.find_or_create_by_email :name => ENV['ADMIN_NAME'].dup, :email => ENV['ADMIN_EMAIL'].dup, :password => ENV['ADMIN_PASSWORD'].dup, :password_confirmation => ENV['ADMIN_PASSWORD'].dup
puts 'user: ' << user.name
    FILE
    end
  end
  ## DEVISE-CONFIRMABLE
  if (prefer :devise_modules, 'confirmable') || (prefer :devise_modules, 'invitable')
    append_file 'db/seeds.rb', "user.confirm!\n"
  end
  if (prefer :authorization, 'cancan')
    append_file 'db/seeds.rb', 'user.add_role :admin'
  end
  ## DEVISE-INVITABLE
  if prefer :devise_modules, 'invitable'
    run 'rake db:migrate'
    generate 'devise_invitable user'
  end
  ### APPLY DATABASE SEED ###
  unless prefer :database, 'default'
    ## ACTIVE_RECORD
    say_wizard "applying migrations and seeding the database"
    run 'rake db:migrate'
    run 'rake db:test:prepare'
  end
  unless prefs[:skip_seeds]
    inject_into_file 'config/environments/development.rb', :before => '      config.action_mailer.smtp_settings = {' do
      <<-RUBY
      config.action_mailer.default_url_options = { :host => 'localhost:3000' }
      RUBY
    end
    inject_into_file 'config/environments/production.rb', :before => '      config.action_mailer.smtp_settings = {' do
      <<-RUBY
      config.action_mailer.default_url_options = { :host => 'localhost:3000' }
      RUBY
    end
    inject_into_file 'config/environments/test.rb', :before => '      config.action_mailer.smtp_settings = {' do
      <<-RUBY
      config.action_mailer.default_url_options = { :host => 'localhost:3000' }
      RUBY
    end
    run 'rake db:seed'
  end
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: set up database"' if prefer :git, true
end # after_everything
# >----------------------------- recipes/init.rb -----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<



# >-------------------------- templates/recipe.erb ---------------------------start<
# >--------------------------------[ extras ]---------------------------------<
@current_recipe = "extras"
@before_configs["extras"].call if @before_configs["extras"]
say_recipe 'extras'
config = {}
config['ban_spiders'] = yes_wizard?("Set a robots.txt file to ban spiders?") if true && true unless config.key?('ban_spiders') || prefs.has_key?(:ban_spiders)
#config['git_rep'] = yes_wizard?("Create a Git repository?") if true && true unless config.key?('git_rep') || prefs.has_key?(:git_rep)
config['local_env_file'] = yes_wizard?("Use application.yml file for environment variables?") if true && true unless config.key?('local_env_file') || prefs.has_key?(:local_env_file)
config['quiet_assets'] = yes_wizard?("Reduce assets logger noise during development?") if true && true unless config.key?('quiet_assets') || prefs.has_key?(:quiet_assets)
config['better_errors'] = yes_wizard?("Improve error reporting with 'better_errors' during development?") if true && true unless config.key?('better_errors') || prefs.has_key?(:better_errors)
@configs[@current_recipe] = config
# >---------------------------- recipes/extras.rb ----------------------------start<

# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

## RVMRC
rvmrc_detected = false
if File.exist?('.rvmrc')
  rvmrc_file = File.read('.rvmrc')
  rvmrc_detected = rvmrc_file.include? app_name
end
if File.exist?('.ruby-gemset')
  rvmrc_file = File.read('.ruby-gemset')
  rvmrc_detected = rvmrc_file.include? app_name
end
unless rvmrc_detected || (prefs.has_key? :rvmrc)
  prefs[:rvmrc] = yes_wizard? "Use or create a project-specific rvm gemset?"
end
if prefs[:rvmrc]
  if which("rvm")
    say_wizard "recipe creating project-specific rvm gemset and .rvmrc"
    # using the rvm Ruby API, see:
    # http://blog.thefrontiergroup.com.au/2010/12/a-brief-introduction-to-the-rvm-ruby-api/
    # https://rvm.io/integration/passenger
    if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
      begin
        gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')
        ENV['GEM_PATH'] = "#{gems_path}:#{gems_path}@global"
        require 'rvm'
        RVM.use_from_path! File.dirname(File.dirname(__FILE__))
      rescue LoadError
        raise "RVM gem is currently unavailable."
      end
    end
    say_wizard "creating RVM gemset '#{app_name}'"
    RVM.gemset_create app_name
    say_wizard "switching to gemset '#{app_name}'"
    # RVM.gemset_use! requires rvm version 1.11.3.5 or newer
    rvm_spec =
        if Gem::Specification.respond_to?(:find_by_name)
          Gem::Specification.find_by_name("rvm")
        else
          Gem.source_index.find_name("rvm").last
        end
    unless rvm_spec.version > Gem::Version.create('1.11.3.4')
      say_wizard "rvm gem version: #{rvm_spec.version}"
      raise "Please update rvm gem to 1.11.3.5 or newer"
    end
    begin
      RVM.gemset_use! app_name
    rescue => e
      say_wizard "rvm failure: unable to use gemset #{app_name}, reason: #{e}"
      raise
    end
    run "rvm gemset list"
    if File.exist?('.ruby-version')
      say_wizard ".ruby-version file already exists"
    else
      create_file '.ruby-version', "#{RUBY_VERSION}\n"
    end
    if File.exist?('.ruby-gemset')
      say_wizard ".ruby-gemset file already exists"
    else
      create_file '.ruby-gemset', "#{app_name}\n"
    end
  else
    say_wizard "WARNING! RVM does not appear to be available."
  end
end

## QUIET ASSETS
if config['quiet_assets']
  prefs[:quiet_assets] = true
end
if prefs[:quiet_assets]
  say_wizard "recipe setting quiet_assets for reduced asset pipeline logging"
  add_gem 'quiet_assets', :group => :development
end

## LOCAL_ENV.YML FILE
if config['local_env_file']
  prefs[:local_env_file] = true
end
if prefs[:local_env_file]
  say_wizard "recipe creating application.yml file for environment variables"
  add_gem 'figaro'
end

## BETTER ERRORS
if config['better_errors']
  prefs[:better_errors] = true
end
if prefs[:better_errors]
  say_wizard "recipe adding better_errors gem"
  add_gem 'better_errors', :group => :development
  add_gem 'binding_of_caller', :group => :development, :platforms => [:mri_19, :mri_20, :rbx]
end

## BAN SPIDERS
if config['ban_spiders']
  prefs[:ban_spiders] = true
end
if prefs[:ban_spiders]
  say_wizard "recipe banning spiders by modifying 'public/robots.txt'"
  after_bundler do
    gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
    gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'
  end
end

## JSRUNTIME
case RbConfig::CONFIG['host_os']
  when /linux/i
    prefs[:jsruntime] = yes_wizard? "Add 'therubyracer' JavaScript runtime (for Linux users without node.js)?" unless prefs.has_key? :jsruntime
    if prefs[:jsruntime]
      say_wizard "recipe adding 'therubyracer' JavaScript runtime gem"
      add_gem 'therubyracer', :platform => :ruby
    end
end

## AFTER_EVERYTHING
after_everything do
  say_wizard "recipe removing unnecessary files and whitespace"
  %w{
    public/index.html
    app/assets/images/rails.png
  }.each { |file| remove_file file }
  # remove commented lines and multiple blank lines from Gemfile
  # thanks to https://github.com/perfectline/template-bucket/blob/master/cleanup.rb
  gsub_file 'Gemfile', /#.*\n/, "\n"
  gsub_file 'Gemfile', /\n^\s*\n/, "\n"
  # remove commented lines and multiple blank lines from config/routes.rb
  gsub_file 'config/routes.rb', /  #.*\n/, "\n"
  gsub_file 'config/routes.rb', /\n^\s*\n/, "\n"
  # GIT
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_template: extras"' if prefer :git, true
end

## GIT REPOSITORY
if config['git_rep']
  prefs[:git_rep] = true
end
# >---------------------------- recipes/extras.rb ----------------------------end<
# >-------------------------- templates/recipe.erb ---------------------------end<




# >-----------------------------[ Final Gemfile Write ]------------------------------<
Gemfile.write

# >---------------------------------[ Diagnostics ]----------------------------------<

# remove prefs which are diagnostically irrelevant
redacted_prefs = prefs.clone
redacted_prefs.delete(:ban_spiders)
redacted_prefs.delete(:better_errors)
redacted_prefs.delete(:dev_webserver)
redacted_prefs.delete(:git)
redacted_prefs.delete(:git_rep)
redacted_prefs.delete(:jsruntime)
redacted_prefs.delete(:local_env_file)
redacted_prefs.delete(:main_branch)
redacted_prefs.delete(:prelaunch_branch)
redacted_prefs.delete(:prod_webserver)
redacted_prefs.delete(:quiet_assets)
redacted_prefs.delete(:rvmrc)
redacted_prefs.delete(:templates)

if diagnostics_prefs.include? redacted_prefs
  diagnostics[:prefs] = 'success'
else
  diagnostics[:prefs] = 'fail'
end

@current_recipe = nil

# >-----------------------------[ Run 'Bundle Install' ]-------------------------------<

say_wizard "Installing gems. This will take a while."
run 'gem install bundler' if prefs[:rvmrc]
run 'bundle install --without production'
say_wizard "Updating gem paths."
Gem.clear_paths
# >-----------------------------[ Run 'After Bundler' Callbacks ]-------------------------------<

say_wizard "Running 'after bundler' callbacks."
if prefer :templates, 'haml'
  say_wizard "importing html2haml conversion tool"
  require 'html2haml'
end
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; puts @current_recipe; b[1].call}

# >-----------------------------[ Run 'After Everything' Callbacks ]-------------------------------<

@current_recipe = nil
say_wizard "Running 'after everything' callbacks."
@after_everything_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; puts @current_recipe; b[1].call}

@current_recipe = nil
if diagnostics[:recipes] == 'success'
  say_wizard("WOOT! The recipes you've selected are known to work together.")
  say_wizard("If they don't, open an issue for rails_apps_composer on GitHub.")
else
  say_wizard("\033[1m\033[36m" + "WARNING! The recipes you've selected might not work together." + "\033[0m")
  say_wizard("Help us out by reporting whether this combination works or fails.")
  say_wizard("Please open an issue for rails_apps_composer on GitHub.")
  say_wizard("Your new application will contain diagnostics in its README file.")
end
if diagnostics[:prefs] == 'success'
  say_wizard("WOOT! The preferences you've selected are known to work together.")
  say_wizard("If they don't, open an issue for rails_apps_composer on GitHub.")
else
  say_wizard("\033[1m\033[36m" + "WARNING! The preferences you've selected might not work together." + "\033[0m")
  say_wizard("Help us out by reporting whether this combination works or fails.")
  say_wizard("Please open an issue for rails_apps_composer on GitHub.")
  say_wizard("Your new application will contain diagnostics in its README file.")
end
say_wizard "Finished running the rails_apps_composer app template."
say_wizard "Your new Rails app is ready. Time to run 'bundle install'."

