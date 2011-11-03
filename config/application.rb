require "rails"
gem 'sqlite3-ruby'
# %w(
#   active_record
#   action_controller
#   action_mailer
# ).each do |framework|
#   begin
#     require "#{framework}/railtie"
#   rescue LoadError
#   end
# end
# 
# [
#   Rack::Sendfile,
#   ActionDispatch::Flash,
#   ActionDispatch::Session::CookieStore,
#   ActionDispatch::Cookies,
#   ActionDispatch::BestStandardsSupport,
#   Rack::MethodOverride,
#   ActionDispatch::ShowExceptions,
#   ActionDispatch::Static,
#   ActionDispatch::RemoteIp,
#   ActionDispatch::ParamsParser,
#   Rack::Lock,
#   ActionDispatch::Head
# ].each do |klass|
#   config.middleware.delete klass
# end

# config/environments/production.rb
config.middleware.delete
ActiveRecord::ConnectionAdapters::ConnectionManagement