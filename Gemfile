source 'https://rubygems.org'

gem 'rails', '4.0.0'
gem 'sass-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 1.2'

gem 'sprockets', '2.10.1'


gem 'rouge', git: 'git://github.com/chrisroberts/rouge.git', branch: 'fix/lazyload'

group :doc do
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# Web server
gem 'unicorn', :platforms => :ruby

# JS Runtime
gem 'therubyrhino', :platforms => :jruby
gem 'therubyracer', :platforms => :ruby
gem 'jruby-rack', '1.1.13.3', :platforms => :jruby

gem 'omniauth', '~> 1.1'
gem 'omniauth-github'
gem 'oauth_simple'
gem 'kaminari'
gem 'haml', '>= 0.3.4'
gem 'simple_form'
gem 'bootstrap-sass'

group :development do
  gem 'warbler', '1.4.0'
  gem 'pry-rails'
end

group :test do
  gem 'rspec-rails', group: :test
  gem 'capybara'
end

gem 'octokit'
gem 'risky', git: 'git://github.com/chrisroberts/risky.git', branch: 'updates'

if(ENV['FISSION_LOCALS'] == 'true')
  gem 'fission-app-jobs', path: '../fission-app-jobs', require: 'fission-app-jobs/version'
  gem 'fission-data', path: '../fission-data'
  gem 'fission-app-stripe', path: '../fission-app-stripe'
  gem 'fission-app-static', path: '../fission-app-static'
  gem 'fission-app-docs', path: '../fission-app-docs'
else
  gem 'fission-app-jobs', git: 'git@github.com:heavywater/fission-app-jobs.git', branch: 'develop', require: 'fission-app-jobs/version'
  gem 'fission-data', git: 'git@github.com:heavywater/fission-data.git', branch: 'develop'
  gem 'fission-app-stripe', git: 'git@github.com:heavywater/fission-app-stripe.git', branch: 'develop'
  gem 'fission-app-static', git: 'git@github.com:heavywater/fission-app-static', branch: 'develop'
  gem 'fission-app-docs', git: 'git@github.com:heavywater/fission-app-docs', branch: 'develop'
end

gemspec
