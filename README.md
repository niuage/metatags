# Metatags

## About

Dealing with meta tags is a pain. Hopefully Metatags can help.
It leverages I18n and smart defaults to make it as easy as possible to output meta tags on each pages.

## Installation

Add this line to your application's Gemfile:

    gem 'metatags'

And then execute:

    > bundle

## Usage

##### Controllers
Since one of the responsabilities of controllers is to prepare data for the views, our controllers are going to be the one building the meta tags.
Start by including the `Metatags::Concerns::Controller` module to your `ApplicationController`.

```ruby
class ApplicationController < ActionController::Base
    include Metatags::Concerns::Controller
end
```

##### Views
In your application layout, use `<%= render_meta_tags %>` in the `<head>` element to output the meta tags.

##### Locales

Create a new file in `config/locales` called `meta_tags.yml`:

```yaml
en:
    meta_tags:
        base:
            title: "My application title"
            description: "My application description"
```

-------

Every page of your app should now have default meta tags defined.

### Customizing meta tags

Let's take the example of an app dealing with `Article`s.
Our routes looks like this:

```ruby
    root to: "articles#index"
    resources :articles
```

Our `ArticlesController` could look like this:

```ruby
class ArticlesController < ApplicationController
    before_action :find_article, only: [:show]
    
    def index
        @articles = Article.all # you can tell this is fake...
    end
    
    def show
    end
   
    protected
   
    def find_article
        @article = Article.find(params[:id])
    end
end
```

What we want is for the index page to keep the default meta tags, as it's the root of our site, and for the show page to have meta tags about the article.

Well, here's what you would do:

```ruby
class ArticlesController < ApplicationController
    before_action :find_article, only: [:show]
    
    # add this line to your controller
    build_meta_tags instance: :article
    
    # nothing changes here
end
```

Then, create the `Metatags::ArticleMetatags` class. You can create it anywhere in your app directory, as long as it's loaded by Rails. I have it in `app/services/metatags`.

```ruby
module Metatags
    class ArticleMetatags < Metatags::BaseMetatags
        
    end
end
```

Behing the scenes, `build_meta_tags` will add a `before_action` callback that will do something like the following (but in a more generic way):

```ruby
before_action :build_meta_tags_with_instance

def build_meta_tags_with_instance
    self.meta_tags = Metatags::ArticleMetatags.new(@article, view_context)
end
```

Where does `Metatags::ArticleMetatags` come from? Well, the gem will try to guess the name of the metatags class from the controller class name.

Let's take an example. We'll assume that:
* the current controller is an instance of `Manage::ArticlesController`
* the current action is `index`

Metatags will try to find these classes, in order:
* `Metatags::Manage::ArticleMetatags::Index`
* `Metatags::Manage::ArticleMetatags`
* `ArticleMetatags::Index`
* `ArticleMetatags`

If none exist, then it will default to Metatags::BaseMetatags.

Ok, so let's apply this to our case. Our `Metatags::ArticleMetatags` class would be...

```ruby
module Metatags
    class ArticleMetatags < Metatags::BaseMetatags
        class Index < ArticleMetatags
            # the default i18n_scope for this class would be "meta_tags.article/index" but we decide to use the defaults since articles#index is the root of our app.
            def i18n_scope
                "meta_tags.base"
            end
        end
        
        class Show < ArticleMetatags
            # object is @article from the controller
            alias_method :article, :object

            def i18n_title_data
                { article_title: article.title }
            end

            def i18n_description_data
                { article_description: article.description }
            end
        end
    end
end
```

We then need to update `config/locales/meta_tags.yml`:

```
en:
    meta_tags:
        base:
            title: ...
            description: ...
        article/show:
            title: "%{article_title} | My app name"
            description: "%{article_description}"
```

What if you want to use the same Metatags' class in several controllers? Easy, use the `with` option.

```
class SomeController
    build_meta_tags with: Metatags::GenericMetatags
end
```

What if you need "complexe" logic to determine which class to use? Then you can skip the `before_action` building the default meta tags, then use `build_meta_tags` in the action itself.

```
class SomeController
    skip_building_meta_tags only: [:index]
    
    def index
        metatags_class = case
        when current_user.vetted? then Metatags::VettedCandidateMetatags
        when current_user.pending? then Metatags::PendingCandidateMetatags
        when current_user.rejected? then Metatags::RejectedCandidateMetatags
        end
        
        build_meta_tags with: metatags_class
    end
end
```

That's the gist of it! If you have questions, read the source code, or ask on Github.

## Supported meta tags

* title
* description
* url (http://mysite.com/article_title)
* image (ex: http://site.com/article_title.jpg)
* type (ex: "article")
* twitter_card (defaults to "summary_large_image")
* twitter_site
* twitter_creator
* facebook_app_id
* robots
* theme_color



