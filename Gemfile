source "https://rubygems.org"

gemspec

# The gemspec allows chef >= 18.0, but chef 18.x is published as platform-specific
# gems (e.g. chef 18.3.0-x64-mingw-ucrt) which Bundler prefers over the pure-ruby
# version. Chef 19+ is pure-ruby only, so force_ruby_platform: true makes Bundler
# ignore all platform-specific variants. The '>= 19.0' lower bound is required
# because without it Bundler still resolves chef 18.3.0 (the pure-ruby build).
gem "chef", ">= 18.10", platforms: [:ruby] unless ENV["GEMFILE_MOD"]

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
