#
# BaseMetatags contains all the default values for the page title, page description,
# and meta tags.
#
# This class, or one of its descendants, is instanciated on every page.
#
# If a new page requires different meta tags, create a new subclass, and override
# the necessary methods. Then, instanciate this class in the relevant controller.
# That's it.
#
# We use I18n as much as possible, so instead of overriding methods like title
# and description in subsclasses, consider just overriding `#i18n_scope`, and
# adding the title and desc values to `meta_tags.yml`.
#

module Metatags
  class BaseMetatags
    attr_accessor :object, :view_context

    def self.meta_tags_for(object, view_context)
      find_metatags_klass_for(object).new(object, view_context)
    end

    def initialize(object, view_context)
      self.object = object
      self.view_context = view_context
    end

    def title
      I18n.translate("title", with_scope(i18n_title_data))
    end

    def description
      I18n.translate("description", with_scope(i18n_description_data))
    end

    def url
      view_context.original_url
    end

    def image
      meta_tag_image_url("og-main.jpg")
    end

    def type
      "devpost:website"
    end

    def to_partial_path
      "title_and_meta_tags"
    end

    def twitter_card
      "summary_large_image"
    end

    def i18n_scope
      "meta_tags.base"
    end

    def with_scope(data)
      data.merge({ scope: i18n_scope })
    end

    def i18n_title_data
      {}
    end

    def i18n_description_data
      {}
    end

    def meta_tag_image_url(image_name)
      view_context.image_url("meta_tags/#{image_name}")
    end

    def self.find_metatags_klass_for(object)
      return self if object.blank?

      "Metatags::#{object.class}Metatags".safe_constantize || Metatags::BaseMetatags
    end
  end
end
