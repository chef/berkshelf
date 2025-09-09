source "https://rubygems.org"

gemspec

group :build do
  gem "rake", ">= 10.1"
end

group :development do
  gem "debug"
  gem "aruba",         "~> 2.3"
  gem "cucumber",      ">= 9.2", "< 10"
  gem "cucumber-cucumber-expressions", "~> 17.1"
  gem "chef-zero",     ">= 4.0"
  gem "dep_selector",  ">= 1.0"
  gem "fuubar",        ">= 2.0"
  gem "rspec",         ">= 3.0"
  gem "rspec-its",     ">= 1.2"
  gem "webmock",       ">= 1.11"
  gem "http",          ">= 0.9.8"
  gem "chefstyle"
end

gem "appbundler"

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
