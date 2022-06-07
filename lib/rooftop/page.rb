module Rooftop
  module Page
    mattr_accessor :extra_includes

    def self.included(base)
      self.extra_includes ||= []
      @page_classes ||= []
      @page_classes << base unless @page_classes.include?(base)
      base.include Rooftop::Base
      base.include Rooftop::Nested
      base.include Rooftop::Preview
      base.include Rooftop::AdvancedFields::Schema
      base.include Rooftop::AdvancedFields::Writeable
      base.extend ClassMethods

      extra_includes.each do |module_to_include|
        base.include module_to_include
      end
    end

    def self.page_classes
      @page_classes
    end

    module ClassMethods


    end



  end
end
