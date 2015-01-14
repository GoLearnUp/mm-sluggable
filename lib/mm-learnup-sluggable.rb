require 'mongo_mapper'

module MongoMapper
  module Plugins
    module LearnupSluggable
      extend ActiveSupport::Concern

      class OldSlugException < StandardError
        attr_accessor :object
        attr_accessor :new_slug
        attr_accessor :old_slug
      end

      module ClassMethods
        def sluggable(to_slug = :title, options = {})
          class_attribute :slug_options

          self.slug_options = {
            :to_slug      => to_slug,
            :key          => :slug,
            :method       => :parameterize,
            :scope        => nil,
            :max_length   => 256,
            :start        => 2,
            :callback     => [:before_validation, {:on => :create, :unless => :slug_field_changed?}]
          }.merge(options)

          key slug_options[:key], String
          key :old_slugs, Array, :default => []

          return_value = slug_options[:callback].is_a?(Array) ?
            self.send(slug_options[:callback][0], :set_slug, slug_options[:callback][1]) :
            self.send(slug_options[:callback], :set_slug)

          slug_key = self.slug_options[:key]

          define_method :to_param do
            self.send(slug_key).blank? ? self.id.to_s : self.send(slug_key)
          end

          # TODO: Should these be included?  They break specs...
          # define_method :"#{slug_key}=" do |value|
          #   v = value.respond_to?(:downcase) ? value.downcase : value
          #   super(v)
          # end
          #
          # define_method :"#{slug_key}" do
          #   value = super()
          #   value.respond_to?(:downcase) ? value.downcase : value
          # end
          #
          # # Silly, custom attribute readers aren't used by form_helpers
          # # Instead, they use "value_before_type_cast", and we can override
          # # the behavior with the following method.
          # # See http://apidock.com/rails/ActionView/Helpers/InstanceTagMethods/ClassMethods/value_before_type_cast
          # define_method :"#{slug_key}_before_type_cast" do
          #   value = super()
          #   value.respond_to?(:downcase) ? value.downcase : value
          # end

          metaclass = class << self; self; end
          metaclass.class_eval do
            define_method :find_by_slug do |slug|
              if obj = where(slug_key => slug).first
                obj
              elsif obj = where(:old_slugs => slug).first
                raise old_slug_exception(slug, obj)
              elsif obj = where(slug_key => /^#{Regexp.escape(slug)}$/i).first
                raise old_slug_exception(slug, obj)
              else
                nil
              end
            end
          end

          before_update do
            if self.send("#{slug_key}_changed?")
              self.old_slugs = self.old_slugs.reject { |slug| slug == self.send(slug_key) }
              self.old_slugs << self.send("#{slug_key}_was")
            end

            true
          end

          return_value
        end
      end

      def slug_field_changed?
        self.send("#{self.class.slug_options[:key]}_changed?")
      end

      def set_slug
        klass = self.class
        while klass.respond_to?(:single_collection_parent)
          superclass = klass.single_collection_parent
          if superclass && superclass.respond_to?(:slug_options)
            klass = superclass
          else
            break
          end
        end

        options = klass.slug_options

        to_slug = self[options[:to_slug]]
        return if to_slug.blank?

        the_slug = raw_slug = to_slug.send(options[:method]).to_s[0...options[:max_length]]

        conds = {}
        conds[options[:key]]   = the_slug
        conds[options[:scope]] = self.send(options[:scope]) if options[:scope]
        conds['_id'] = {
          '$ne' => self.id
        }

        # todo - remove the loop and use regex instead so we can do it in one query
        i = options[:start]

        while klass.first(conds)
          conds[options[:key]] = the_slug = "#{raw_slug}-#{i}"
          i += 1
        end

        self.send(:"#{options[:key]}=", the_slug)
      end
    end

    def old_slug_exception(slug, obj)
      error = MongoMapper::Plugins::LearnupSluggable::OldSlugException.new
      error.old_slug = slug
      error.new_slug = obj.slug
      error.object = obj
      error
    end

    def find_by_slug!(slug)
      if obj = find_by_slug(slug)
        obj
      else
        raise MongoMapper::DocumentNotFound, "Couldn't find #{self} with slug: #{slug}"
      end
    end

    def find_by_slug_or_id(slug_or_id)
      self.find_by_slug(slug_or_id) || self.find_by_id(slug_or_id)
    end

    def find_by_slug_or_id!(slug_or_id)
      if obj = find_by_slug_or_id(slug_or_id)
        obj
      else
        raise MongoMapper::DocumentNotFound, "Couldn't find #{self} with slug or id: #{slug_or_id}"
      end
    end
  end
end