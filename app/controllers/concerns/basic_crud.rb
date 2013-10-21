module BasicCrud

  include FissionApp::Errors
  extend ActiveSupport::Concern

  included do
    before_action :apply_restriction
    include JsonApi
  end

  def self.included(base)
    base.class_eval do
      class << self

        [:restrict, :model_class, :model_name, :form_key, :render_overrides].each do |n|
          define_method(n) do |*args|
            unless(args.empty?)
              config.send("#{n}=", args.size > 1 ? args : args.first)
            end
            config.send(n)
          end
        end
      end
    end
  end

  # Need to add filtering here based on params (i.e. account_id, etc)
  def index
    @items = model_class.restrict(current_user).page(params[:page].to_i)
    @keys = model_class.respond_to?(:display_attributes) ? model_class.display_attributes : model_class.attribute_names
    respond_to do |format|
      format.html{ render apply_render }
      format.json{ render :json => json_response(@items, :success) }
    end
  end

  def new
    @item = model_class.new
    respond_to do |format|
      format.html{ render apply_render }
    end
  end

  def create
    @item = model_class.new(params[form_key])
    if(@item.save)
      respond_to do |format|
        format.html{ render apply_render }
        format.json{ render :json => json_response(@item, :success) }
      end
    else
      respond_to do |format|
        format.html{ render :action => 'show', :error => "Failed to create #{model_name}" }
        format.json do
          render :json => json_response(@item.errors, :fail), :status => :unprocessible_entity
        end
      end
    end
  end

  def show
    @item = fetch_item
    respond_to do |format|
      format.html{ render apply_render }
      format.json{ render :json => json_response(@item, :success) }
    end
  end

  def edit
    @item = model_class.restrict(current_user).find_by_id(params[:id])
    raise Error.new("#{model_name} requested not found", :not_found) unless @item
    respond_to do |format|
      format.html{ render apply_render }
    end
  end

  def update
    @item = fetch_item
    @item.update_attributes(params[form_key])
    if(@item.save)
      respond_to do |format|
        format.html{ render apply_render }
        format.json{ render :json => json_response(@item, :success) }
      end
    else
      respond_to do |format|
        format.html{ render :action => 'edit', :error => "Failed to edit #{model_name}" }
        format.json do
          render :json => json_response(@item.errors, :fail), :status => :unprocessible_entity
        end
      end
    end
  end

  def destroy
    @item = fetch_item
    if(@item.destroy)
      respond_to do |format|
        format.html{ render apply_render }
        format.json{ render :json => json_response(@item, :success) }
      end
    else
      respond_to do |format|
        format.html{ render :action => 'show', :error => "Failed to destroy #{model_name}" }
        format.json do
          render :json => json_response(@item.errors, :fail), :status => :unprocessible_entity
        end
      end
    end
  end

  protected

  # Find requested model instance
  def fetch_item
    item = model_class.restrict(current_user).find_by_id(params[:id])
    item || raise(Error.new("#{model_name} requested not found", :not_found))
  end

  # Override these in the controller if you want something custom that
  # can't be found via magic

  # How to restrict access. Can be array applied to all actions or
  # hash with action key and array value for specific application
  def restrict
    self.class.restrict || []
  end

  # Class of model being handled
  def model_class
    unless(self.class.model_class)
      base = self.class.name.sub(%r{Controller$}, '').singularize
      unless(Rails.env.production?)
        # NOTE: Yay autoloading
        ObjectSpace.const_get(base)
      end
      klass = ActiveRecord::Base.descendants.detect do |k|
        k.name == base
      end
      p klass
      self.class.model_class(klass)
    end
    self.class.model_class
  end

  # Display name for model being handled
  def model_name
    self.class.model_name || model_class.name
  end

  # Form key to access user provided data
  def form_key
    self.class.form_key || model_name.underscore.to_sym
  end

  # Rendering overrides to provide custom views if desired. Key value
  # in hash is action with value being string of view:
  #   {:index => 'users/index'}
  def render_overrides
    self.class.render_overrides || {}
  end

  ## Okay, all done!

  ## internal helpers

  # Return proper render information
  def apply_render
    action = params[:action].to_sym
    if(val = render_overrides[action])
      val == true ? params[:action] : val
    else
      ['basic_crud', params[:action]].join('/')
    end
  end

  # Apply expected restriction
  def apply_restriction
    unless(restrict.empty?)
      args = nil
      action = action_name.to_sym
      if(restrict.is_a?(Hash))
        args = restrict[action] if restrict[action]
      else
        args = restrict
      end
      if(args)
        permit(*Array(args).flatten.compact)
      end
    end
  end

end
