require 'erb'
require 'fileutils'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'yaml'

class Render < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
end

def render_partial(name, locals = {})
  partial_path = File.expand_path("./templates/_#{name}.html.erb", __dir__)
  partial_source = File.read(partial_path)
  ERB.new(partial_source).result_with_hash(locals)
end

class Build
  def start
    remove_public_dir
    build_assets
    build_index_page
    build_post_pages
    build_404_page
  end

  private

  def public_dir
    File.expand_path('./public/', __dir__)
  end

  def remove_public_dir
    public_files = Dir.glob(public_dir + '/*')
    FileUtils.rm_rf(public_files)
  end

  def build_assets
    assets_src_dir = File.expand_path('./assets/', __dir__)
    assets_dst_dir = File.expand_path('./public/assets/', __dir__)
    FileUtils.mkdir_p(assets_dst_dir)
    FileUtils.cp_r(Dir.glob(assets_src_dir + '/*'), assets_dst_dir)
  end
  
  def posts
    markdown = Redcarpet::Markdown.new(Render, extensions = { fenced_code_blocks: true })
    post_paths = Dir.glob(File.expand_path('./posts/', __dir__) + '/*')
    post_paths.map do |post_path|
      slug = File.basename(post_path, ".md")
      content_markdown = File.read(post_path)

      if content_markdown =~ /\A---\s*\n(.*?)\n---\s*\n/m
        content_markdown = Regexp.last_match.post_match
        front_matter = YAML.safe_load(
          Regexp.last_match(1),
          permitted_classes: [Date, Time],
          aliases: true
        )
      else
        raise "Front Matter not found"
      end

      title = front_matter["title"]
      date = Date.parse(front_matter["date"])
      content = markdown.render(content_markdown)

      [slug, title, date, content]
    end
  end

  def build_index_page
    index_template_path = './templates/index.html.erb'
    index_template = File.read(index_template_path)
    title = "@utakaha"
    erb = ERB.new(index_template)
    result = erb.result_with_hash(posts: posts.sort_by { |_, _, date| date }.reverse, title: title)
    File.open("./public/index.html", 'w') do |file|
      file.write(result)
    end
  end

  def build_post_pages
    template_path = './templates/post.html.erb'
    template = File.read(template_path)

    FileUtils.mkdir_p(File.join(public_dir, 'posts'))

    posts.each do |slug, title, date, content|
      erb = ERB.new(template)
      result = erb.result_with_hash(title: title, date: date, content: content)
      output_path = "./public/posts/#{slug}.html"

      File.open(output_path, 'w') do |file|
        file.write(result)
      end
    end
  end

  def build_404_page
    not_found_template_template_path = './templates/404.html.erb'
    not_found_template = File.read(not_found_template_template_path)
    title = "404 Not Found"
    erb = ERB.new(not_found_template)
    result = erb.result_with_hash(title: title)
    File.open("./public/404.html", 'w') do |file|
      file.write(result)
    end
  end
end
