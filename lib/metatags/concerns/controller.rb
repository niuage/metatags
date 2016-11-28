# Example:
#
# class ApplicationController < ActionController::Base
#   include Metatags::Concerns::Controller
# end
#
# class ArticlesController < ApplicationController
#   before_action :find_article, only: [:show]
#
#   # Simplest option.
#   # Will use Metatags::ArticleMetatags by default.
#   build_meta_tags instance: :article
#   # OR
#   # if you need to be specific about which class to use
#   build_meta_tags with: Metatags::CustomArticleMetatags, instance: :article
#   # OR
#   # if you need logic to determine which Metatags class to use, and want to build
#   # the meta tags in the action itself.
#   skip_building_metatags only: [:index]
#
#   def index
#     @articles = Article.all
#   end
#
#   def show
#   end
#
#   protected
#
#   def find_article
#     @article = Article.find(params[:id])
#   end
# end

module Metatags
  module Concerns
    module Controller
      extend ActiveSupport::Concern

      included do
        class_attribute :metatags_class, :metatags_instance_sym
        initialize_metatags_class

        before_action :build_default_meta_tags

        attr_accessor :meta_tags
        helper_method :meta_tags
      end

      module ClassMethods

        ## Example:
        #
        # class TeamsController
        #   build_meta_tags with: Metatags::TeamMetatags, instance: :team
        # end
        #
        ## The code above will build an instance of the Metatags::TeamMetatags class
        ## with `@team` if present.
        #
        def build_meta_tags(options = {})
          self.metatags_class = options.delete(:with)
          self.metatags_instance_sym = options.delete(:instance)

          skip_before_action :build_default_meta_tags, options
          before_action :build_meta_tags_with_instance, options
        end

        def skip_building_meta_tags(options = {})
          skip_before_action :build_default_meta_tags, options
        end

        def initialize_metatags_class
          self.metatags_class = "Metatags::AppMetatags".safe_constantize || Metatas::BaseMetatags
        end
      end

      protected

      # Builds the meta_tags using either the class passed by the user with the `with`
      # option or a class which name is inferred from the controller name.
      #
      def build_default_meta_tags
        klass = metatags_class || default_metatags_class
        build_meta_tags(with: klass, instance: metatags_instance)
      end
      alias_method :build_meta_tags_with_instance, :build_default_meta_tags

      def metatags_instance
        return nil unless metatags_instance_sym
        instance_variable_get("@#{metatags_instance_sym}")
      end

      # Infers the metatags class name from the controller name by default.
      #
      # The default class can be overriden with the `with` option of `build_meta_tags`
      #
      def default_metatags_class
        inferred_name = self.class.name.gsub("Controller", "").singularize

        [
          # Metatags::Manage::TeamMetatags::Index
          "Metatags::#{inferred_name}Metatags::#{action_name.classify}",
          # Metatags::Manage::TeamMetatags
          "Metatags::#{inferred_name}Metatags",
          # Metatags::TeamMetatags::Index
          "Metatags::#{inferred_name.split("::").last}Metatags::#{action_name.classify}",
          # Metatags::TeamMetatags
          "Metatags::#{inferred_name.split("::").last}Metatags",
          # Metatags::BaseMetatags
          "Metatags::AppMetatags"
          # Metatags::BaseMetatags
          "Metatags::BaseMetatags"
        ].detect do |class_name|
          klass = class_name.safe_constantize
          break klass if klass
        end
      end

      # This method is useful when the class name of the Metatags class cannot
      # be inferred by the gem.
      #
      # Ex:
      #
      # class TeamsController
      #   def show
      #     if special_case?
      #       build_meta_tags with: Metatags::SpecialMetatags, instance: :team
      #     end
      #   end
      # end
      #
      def build_meta_tags(with: Metatags::BaseMetatags, instance: nil)
        self.meta_tags = with.new(instance, view_context)
      end
    end
  end
end
