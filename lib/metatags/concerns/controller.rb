#
# Metatags::Concerns::Controller should be included in your ApplicationController.
#
# If the meta tags of a page don't rely on a particular model, then the default
# meta tags are going to be build, nothing to do on your end.
#
# If your meta tags depend on a model, say an article, then we can't rely on the
# before_action `build_default_meta_tags`, because it would be executed before the
# before_action `find_article` from ArticlesController.
# In this case, all you have to do is call `build_meta_tags` after
# `before_action :find_article` in the ArticlesController, with the appropriate
# options. See below:
#
# Example:
#
# class ArticlesController < ApplicationController
#   before_action :find_article, only: [:show]
#
#   build_meta_tags with: Metatags::ArticleMetatags, instance: :article
#
#   protected
#
#   def find_article
#     @article = Article.friendly.find(params[:id])
#   end
# end
#
# If you ommit the `with` option, then Metatags will try to infer the class
# from the controller name.
# So in the example above, `build_meta_tags instance: :article` would have worked
# just as well.
#
#
# module Metatags
#   class ArticleMetatags < Metatags::BaseMetatags
#      def url
#         article_path(object, ref_medium: ...)
#      end
#   end
# end
#

module Metatags
  module Concerns
    module Controller
      extend ActiveSupport::Concern

      included do
        class_attribute :metatags_class, :metatags_instance_sym
        self.metatags_class = Metatags::BaseMetatags

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
