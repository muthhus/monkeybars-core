module Monkeybars
  class InvalidNestingError < Exception; end
  
  class Nesting
    class << self
      alias_method :__new__, :new
    end
    
    def self.new(nesting_options = {})
      nesting_options.validate_only(:sub_view, :using, :view)
      nesting_options.extend Monkeybars::HashNestingValidation

      if nesting_options.property_only?
        PropertyNesting.__new__(nesting_options)
      elsif nesting_options.methods_only?
        MethodNesting.__new__(nesting_options)
      else
        raise InvalidNestingError, "Cannot determine nesting type with parameters #{nesting_options.inspect}"
      end
    end
    
    def initialize(properties)
      @sub_view = properties[:sub_view]
    end
  end
  
  class PropertyNesting < Nesting
    def initialize(properties)
      super
      @view_property = properties[:view]
    end
    
    def nests_with_add?
      true
    end
    
    def nests_with_remove?
      true
    end
    
    def add(view, model, transfer)
      instance_eval("view.#{@view_property}.add #{@sub_view}")
    end
    
    def remove(view, model, transfer)
      instance_eval("view.#{@view_property}.remove #{@sub_view}")
    end
  end
  
  class MethodNesting < Nesting
    def initialize(nesting_options)
      super
      @add_method, @remove_method = if nesting_options[:using].kind_of? Array
        [nesting_options[:using][0], nesting_options[:using][1]]
      else
        [nesting_options[:using], nil]
      end
    end
    
    def nests_with_add?
      !@add_method.nil?
    end
    
    def nests_with_remove?
      !@remove_method.nil?
    end
    
    def add(view, nested_view, nested_component, model, transfer)
      #instance_eval("view.#{@add_method}(@sub_view, model, transfer)")
      view.send(@add_method, nested_view, nested_component, model, transfer)
    end
    
    def remove(view, model, transfer)
      #instance_eval("view.#{@remove_method}(@sub_view, model, transfer)")
      view.send(@remove_method, @sub_view, model, transfer)
    end
  end
  
  module HashNestingValidation
    def property_only?
      property_present? and not (to_view_method_present? and from_view_method_present?)
    end
    
    def methods_only?
      (to_view_method_present? and from_view_method_present?) and not property_present?
    end
    
    def property_present?
      !self[:view].nil?
    end
    
    def to_view_method_present?
      !to_view_method.nil?
    end

    def from_view_method_present?
      !from_view_method.nil?
    end
    
    def to_view_method
      if self[:using].kind_of? Array
        self[:using].first
      else
        self[:using]
      end
    end
    
    def from_view_method
      if self[:using].kind_of? Array
        self[:using][1]
      else
        nil
      end
    end
  end
end