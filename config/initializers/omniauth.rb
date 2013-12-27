Rails.application.config.middleware.use OmniAuth::Builder do
  if(Rails.env.production? || ENV['ENABLE_OMNIAUTH'])
    Rails.application.config.omniauth_provider = :identity
  else
    Rails.application.config.omniauth_provider = :developer
  end
  provider(:github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: 'user,repo')
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
OmniAuth.config.logger = Rails.logger
