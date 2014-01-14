require 'fission-app/errors'

class ApplicationController < ActionController::Base
  # Load in any modules we care about
  include JsonApi
  include FissionApp::Errors

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery :with => :exception

  # Prevent regular errors from propogating up unless in dev mode
  unless(Rails.env == 'development')
    rescue_from StandardError, :with => :exception_handler
  end

  # User access helpers
  helper_method :current_user
  helper_method :valid_user?

  # Permission helpers
  helper_method :permit

  # Set analytics variables
  before_action :analytics

  # Always validate
  before_action :validate_user!

  # Just say no to infinity
  after_action :reset_redirect_counter

  protected

  ## Helpers

  # returns if user is logged in
  def valid_user?
    !!current_user
  end

  # return instance of current user
  def current_user
    if(ENV['ALLOW_NO_AUTH'])
      session[:user_id] = User.first.id
    end
    unless(@current_user)
      @current_user = User[session[:user_id]] if defined?(User)
    end
    if(@current_user)
      if(session[:account_id])
        act = @current_user.accounts.detect{|a| a.key == session[:account_id]}
      end
      @current_user.run_state.current_account = act || @current_user.base_account
    end
    @current_user
  end

  # args:: permission(s)
  # raise exception if current user is not allowed
  def permit(*args)
    res = args.detect do |arg|
      current_user.permitted?(arg)
    end
    res || raise(Error.new('Access denied', :unauthorized))
  end

  ## Callbacks

  # forces login if user is not valid
  def validate_user!
    unless(valid_user?)
      flash.each do |k,v|
        flash[k] = v
      end
      respond_to do |format|
        format.html do
          if(page = Rails.application.config.fission.config[:static_pages].try(:[], :landing))
            redirect_to File.join('/s', page)
          else
            redirect_to new_session_url
          end
        end
        format.json do
          unless(api_validate)
            render :json => json_response('Access denied', :fail)
          end
        end
      end
    else
      whitelist_validate!
    end
  end

  # redirect:: do redirect
  # Validate user is in whitelist. Redirect user if applicable.
  def whitelist_validate!(redirect=true)
    unless(Rails.application.config.fission.whitelist[:users].include?(current_user.username))
      if(redirect)
        redirect_to Rails.application.config.fission.whitelist[:redirect_to]
      end
      false
    else
      true
    end
  end

  def api_validate
    # valid authentication paths:
    # Basic Auth
    user = authenticate_with_http_basic do |username, password|

    end
    # OAuth token
    false
  end

  # error:: Exception
  # Handles uncaught exceptions
  def exception_handler(error)
    Rails.logger.error "#{error.class}: #{error} - (user: #{current_user.try(:username)})"
    Rails.logger.debug "#{error.class}: #{error}\n#{error.backtrace.join("\n")}"
    msg = error.is_a?(Error) ? error.message : 'Unknown error encountered'
    session[:redirect_count] ||= 0
    session[:redirect_count] += 1
    @error_state = true
    respond_to do |format|
      format.html do
        flash[:error] = msg
        if(session[:redirect_count] > 5)
          Rails.logger.error 'Caught in redirect loop. Bailing out!'
          render
        else
          redirect_to root_url
        end
      end
      format.json do
        render(
          :json => json_response(nil, :error, :message => msg),
          :status => error.respond_to?(:status_code) ? error.status_code : :internal_server_error
        )
      end
    end
  end

  after_action :reset_redirect_counter
  def reset_redirect_counter
    session[:redirect_count] = 0 unless @error_state
  end

  def fetch_github_repos(*accounts)
    [accounts].flatten.compact.map do |account|
      Fission::App::Jobs.fetch_all(github.org(account), :repos)
    end.flatten.sort{|x,y| x.full_name <=> y.full_name}
  end

  def github
    Octokit::Client.new(:access_token => current_user.token_for(:github))
  end

  def analytics
    if(Rails.env == 'production')
      dns = request.env.fetch('SERVER_NAME', '')
      property = Rails.application.config.fission.analytics[:properties].detect do |key, value|
        dns.include?(key.to_s)
      end
      if(property)
        @analytics = {
          :ref => [Rails.application.config.fission.analytics[:account], property.last].join('-'),
          :name => property.first
        }
      else
        Rails.logger.warn "Failed to locate analytics property using connected DNS (#{dns})"
      end
    end
  end

end
