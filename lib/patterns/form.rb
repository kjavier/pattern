require "virtus"
require "action_controller/metal/strong_parameters"

module Patterns
  class Form
    include Virtus.model
    include ActiveModel::Validations

    Error = Class.new(StandardError)
    Invalid = Class.new(Error)
    NoParamKey = Class.new(Error)

    def initialize(*args)
      attributes = args.extract_options!

      if attributes.blank? && args.last.is_a?(ActionController::Parameters)
        attributes = args.pop.to_unsafe_h
      end

      @resource = args.first

      if resource&.respond_to?(:attributes)
        attributes = resource.attributes.merge(attributes)
      end

      super(attributes)
    end

    def save
      valid? ? persist : false
    end

    def save!
      save.tap do |saved|
        raise Invalid unless saved
      end
    end

    def as(form_owner)
      @form_owner = form_owner
      self
    end

    def to_key
      nil
    end

    def to_partial_path
      nil
    end

    def to_model
      self
    end

    def persisted?
      if resource&.respond_to?(:persisted?)
        resource.persisted?
      else
        false
      end
    end

    def model_name
      @model_name ||= Struct.
        new(:param_key).
        new(param_key)
    end

    def self.param_key(key = nil)
      if key.nil?
        @param_key
      else
        @param_key = key
      end
    end

    private

    attr_reader :resource, :form_owner

    def param_key
      param_key = self.class.param_key
      param_key ||= resource&.respond_to?(:model_name) && resource.model_name.param_key
      raise NoParamKey if param_key.blank?
      param_key
    end

    def persist
      raise NotImplementedError, "#persist has to be implemented"
    end
  end
end
