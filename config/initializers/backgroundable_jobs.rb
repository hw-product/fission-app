unless(defined?(Rake))
  # TODO: Allow specifying carnivore source for sending payloads into fission
  require 'fission-app/backgroundable'
  Rails.application.config.backgroundable = Fission::App::Backgroundable.new
end
