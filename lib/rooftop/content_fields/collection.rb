module Rooftop
  module Content
    class Collection < ::Array
      def initialize(content_fields)
          content_fields.each do |field|
            self << Rooftop::Content::Field.new(field)
          end
      end

      # Find content_fields by attribute. Assume there will only be one attribute in the search
      def find_by(hash)
        raise ArgumentError, "you can only find a field by one attribute at a time" unless hash.length == 1
        attr = hash.first.first
        val = hash.first.last
        self.select {|l| l.send(attr) == val.to_s}
      end

      def named(name)
        find_by(name: name.to_s).first
      end
    end
  end
end