require 'erb'
require 'fileutils'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'yaml'

require_relative 'template_renderer'
require_relative 'post'

class Render < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
end

class Build
  ROOT_PATH = File.expand_path('..', __dir__)
  BASE_URL = 'https://utakaha.com'
  FEED_URL = "#{BASE_URL}/feed.xml"
  FEED_TITLE = '@utakaha'
  FEED_AUTHOR = 'utakaha'

  def start
    remove_public_dir
    build_assets
    build_index_page
    build_post_pages
    build_atom_feed
    build_404_page
  end

  private

  def public_dir
    File.expand_path('public/', ROOT_PATH)
  end

  def remove_public_dir
    public_files = Dir.glob(public_dir + '/*')
    FileUtils.rm_rf(public_files)
  end

  def build_assets
    assets_src_dir = File.expand_path('assets/', ROOT_PATH)
    assets_dst_dir = File.expand_path('public/assets/', ROOT_PATH)
    FileUtils.mkdir_p(assets_dst_dir)
    FileUtils.cp_r(Dir.glob(assets_src_dir + '/*'), assets_dst_dir)
  end
  
  def posts
    @posts ||= Post.all
  end

  def build_index_page
    index_template_path = File.expand_path('templates/index.html.erb', ROOT_PATH)
    index_template = File.read(index_template_path)
    title = "@utakaha"
    renderer = TemplateRenderer.new(index_template, posts:, title:)
    result = renderer.render
    File.open(File.expand_path('public/index.html', ROOT_PATH), 'w') do |file|
      file.write(result)
    end
  end

  def build_post_pages
    post_template_path = File.expand_path('templates/post.html.erb', ROOT_PATH)
    post_template = File.read(post_template_path)

    FileUtils.mkdir_p(File.join(public_dir, 'posts'))

    posts.each do |post|
      renderer = TemplateRenderer.new(
                   post_template, 
                   title: post.title, 
                   date: post.date, 
                   content: post.content
                 )
      result = renderer.render
      output_path = File.expand_path("public/posts/#{post.slug}.html", ROOT_PATH)

      File.open(output_path, 'w') do |file|
        file.write(result)
      end
    end
  end

  def build_atom_feed
    feed_template_path = File.expand_path('templates/feed.xml.erb', ROOT_PATH)
    feed_template = File.read(feed_template_path)
    renderer = TemplateRenderer.new(
      feed_template,
      posts:,
      feed_url: FEED_URL,
      feed_title: FEED_TITLE,
      feed_author: FEED_AUTHOR,
      base_url: BASE_URL,
      feed_updated_at:
    )
    feed = renderer.render
    File.open(File.expand_path('public/feed.xml', ROOT_PATH), 'w') do |file|
      file.write(feed)
    end
  end

  def build_404_page
    not_found_template_template_path = File.expand_path('templates/404.html.erb', ROOT_PATH)
    not_found_template = File.read(not_found_template_template_path)
    title = "404 Not Found"
    renderer = TemplateRenderer.new(not_found_template, title:)
    result = renderer.render
    File.open(File.expand_path('public/404.html', ROOT_PATH), 'w') do |file|
      file.write(result)
    end
  end

  def feed_updated_at
    posts.first&.published_at || Time.new(1970, 1, 1, 0, 0, 0, "+09:00")
  end
end
