require 'fission-app/errors'

class ApplicationController < ActionController::Base
  # Load in any modules we care about
  include JsonApi
  include FissionApp::Errors

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery :with => :exception

  # Prevent regular errors from propogating up
  rescue_from StandardError, :with => :exception_handler

  # User access helpers
  helper_method :current_user
  helper_method :valid_user?

  # Permission helpers
  helper_method :permit

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
    unless(@current_user)
      @current_user = User.find_by_id(session[:user_id])
    end
    if(@current_user && session[:account_id])
      @current_user.config.account_id = session[:account_id] || @current_user.base_account_id
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
      redirect_to new_session_url
    end
  end

  # error:: Exception
  # Handles uncaught exceptions
  def exception_handler(error)
    Rails.logger.error "#{error.class}: #{error} - (user: #{current_user.try(:username)})"
    Rails.logger.debug "#{error.class}: #{error}\n#{error.backtrace.join("\n")}"
    respond_to do |format|
      msg = error.is_a?(Error) ? error.message : 'Unknown error encountered'
      session[:redirect_count] ||= 0
      session[:redirect_count] += 1
      @error_state = true
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

end
