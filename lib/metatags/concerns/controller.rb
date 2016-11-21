#
# Concerns::MetaTags is included in the ApplicationController.
#
# If the meta tags of a page don't rely on a particular model, then the default
# meta tags are going to be build, nothing to do on your end.
#
# If your meta tags depend on a model, say an article, then we can't rely on the
# before_action `build_default_meta_tags`, because it would be executed before the
# before_action `find_article` from ArticlesController.
# In this case, all you have to do is:
# - call `build_meta_tags` after `before_action :find_article` in the ArticlesController
# - define a `build_meta_tags` that builds the meta tag object with `@article`.
#
# Example:
#
# class ArticlesController < ApplicationController
#   before_action :find_article, only: [:show]
#   build_meta_tags
#
#   protected
#
#   def build_meta_tags
#     self.meta_tags = Metatags::BaseMetatags.meta_tags_for(@article, view_context)
#   end
#
#   def find_article
#     @article = Article.friendly.find(params[:id])
#   end
# end
#

module Metatags
  module Concerns
    module Controller
      extend ActiveSupport::Concern

      included do
        before_action :build_default_meta_tags

        attr_accessor :meta_tags
        helper_method :meta_tags
      end

      module ClassMethods
        def build_meta_tags(options = {})
          skip_before_action :build_default_meta_tags, options
          before_action :build_meta_tags, options
        end
      end

      protected

      def build_default_meta_tags
        self.meta_tags = ::Metatags::BaseMetatags.new(nil, view_context)
      end
    end
  end
end
