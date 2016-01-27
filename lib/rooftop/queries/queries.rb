module Rooftop
  module Queries
    PER_PAGE = 99999999
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # We need to fix up the `where()` filter. WP-API expects a url format for filters like this:
      # /?filter[something]=foo. But we have a magic hash key to allow us to send things which aren't mangled.
      def where(args)
        args = HashWithIndifferentAccess.new(args)
        # the fact that 'slug' is referred to in the db as 'name' is irritating. Let's fix that
        # in queries so we can specify {slug: "foo"}
        if args.keys.collect(&:to_sym).include?(:slug)
          if args[:slug].is_a?(Array)
            args[:post_name__in] ||= []
            args[:slug].each do |slug|
              args[:post_name__in] << slug
            end
          else
            args[:name] = args[:slug]
          end
          args.delete(:slug)
        end

        if args.keys.collect(&:to_sym).include?(:id)
          if args[:id].is_a?(Array)
            args[:post__in] ||= []
            args[:id].each do |id|
              args[:post__in] << id
            end
          else
            args[:page_id] = args[:id]
          end
          args.delete(:id)
        end

        if args.keys.collect(&:to_sym).include?(:no_filter)
          args_to_filter = args.except(*args[:no_filter]).except(:no_filter)
          args_not_to_filter = args.except(args_to_filter).except(:no_filter)
          filters =  args_to_filter.inject({}) {|hash,pair| hash["filter[#{pair.first}]"] = pair.last; hash}
          filters = {per_page: Rooftop::Queries::PER_PAGE}.merge(filters).merge(args_not_to_filter)
        else
          #TODO DRY
          filters =  args.inject({}) {|hash,pair| hash["filter[#{pair.first}]"] = pair.last; hash}
          filters = {per_page: Rooftop::Queries::PER_PAGE}.merge(filters)
        end

        # we probably want every result without pagination, unless we specify otherwise

        #Call the Her `where` method with our new filters
        super().where(filters)
      end

      alias_method :find_by, :where

      def find_by!(args)
        results = find_by(args)
        if results.present?
          results
        else
          raise Rooftop::RecordNotFoundError
        end
      end

      # 'all' needs to have a querystring param passed to really get all. It should be -1 but for some reason that's not working.
      def all(args = {})
        super({per_page: Rooftop::Queries::PER_PAGE}.merge(args))
      end
    end
  end
end