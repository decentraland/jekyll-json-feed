module JekyllJsonFeed
  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      return if file_exists?("feed.json")
      
      @site.pages << make_page("feed.json")
      @site.pages << make_page("feed.latest.json", { "limit" => 10 })

      @site.tags.keys.each do |tag|
        next if %r![^a-zA-Z0-9_]!.match?(tag)
        @site.pages << make_page("feed/t/#{tag}.json", { "tag" => "post.tags contains '#{tag}'" })
        @site.pages << make_page("feed/t/#{tag}.latest.json", { "tag" => "post.tags contains '#{tag}'", "limit" => 10 })
      end

      @site.categories.keys.each do |category|
        next if %r![^a-zA-Z0-9_]!.match?(category)
        @site.pages << make_page("feed/c/#{category}.json", { "category" => "post.categories contains '#{category}'" })
        @site.pages << make_page("feed/c/#{category}.latest.json", { "category" => "post.categories contains '#{category}'", "limit" => 10 })
      end
    end

    private

    # Matches all whitespace that follows
    #   1. A '>', which closes an XML tag or
    #   2. A '}', which closes a Liquid tag
    # We will strip all of this whitespace to minify the template
    MINIFY_REGEX = %r!(?<=>|})\s+!

    # Path to feed.json template file
    def feed_source_path
      @feed_source_path ||= File.expand_path "./feed.json", File.dirname(__FILE__)
    end

    def feed_template
      @feed_template ||= File.read(feed_source_path).gsub(MINIFY_REGEX, "")
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      File.exist? @site.in_source_dir(file_path)
    end

    def make_page(file_path, data = {})
      Jekyll::PageWithoutAFile.new(@site, File.dirname(__FILE__), "", file_path).tap do |file|
        file.content = feed_template
        file.data.merge!( "layout" => nil, "sitemap" => false )
        file.data.merge!(data)
        file.output
      end
    end
  end
end
