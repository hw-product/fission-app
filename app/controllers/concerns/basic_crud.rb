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

        [:restrict, :model_class, :model_name, :form_key, :render_overrides, :labels, :footers, :links].each do |n|
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
    container = params.keys.detect{|k| k.to_s.end_with?('_id')}
    if(container)
      klass = container.sub('_id', '').classify.constantize
      base = klass[params[container]]
      @items = base.send(params[:style])
      @title = "#{klass.table_name.humanize} #{base}: #{params[:style].humanize.downcase}"
    else
      @items = model_class.restrict(current_user)
      @title = model_class.table_name.humanize.pluralize
    end
    @items = Kaminari.paginate_array(@items).page(params[:page].to_i).per(50)
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
    @item = model_class[params[:id]]
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
    container = params.keys.detect{|k| k.to_s.end_with?('_id')}
    klass = container.sub('_id', '').classify.constantize if container
    if(klass)
      base = klass[params[container]]
      item = base.send(params[:style])
      if(params[:id])
        raise 'wat. bad id match!' unless item.id == params[:id]
      end
      item
    else
      model_class[params[:id]]
    end
  end

  # Override these in the controller if you want something custom that
  # can't be found via magic

  # How to restrict access. Can be array applied to all actions or
  # hash with action key and array value for specific application
  def restrict
    []
#    self.class.restrict || []
  end

  # Class of model being handled
  def model_class
    unless(self.class.model_class)
      base = self.class.name.sub(%r{Controller$}, '').singularize
      klass = ModelBase.descendants.detect do |k|
        k.name.split('::').last == base
      end
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

  # Footer overrides to add footer partials to main panel
  def footers
    self.class.footers || {}
  end

  # Label overrides to add labels to data
  def labels
    self.class.labels || {}
  end

  # Links overrides to disable display globally or based on user attribute
  def links
    self.class.labels || {}
  end

  ## Okay, all done!

  ## internal helpers

  # Return proper render information
  def apply_render
    action = params[:action].to_sym
    @footer = footers[action] || footers[:default]
    @labels = labels[action] || labels[:default]
    unless(links[action] == false)
      unless(links[:default] == false)
        link_val = links[action] || links[:default]
        if(link_val)
          if(link_val.is_a?(Proc))
            @links = link_val
          end
        end
        @links ||= proc{|arg|true}
      end
    end
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
