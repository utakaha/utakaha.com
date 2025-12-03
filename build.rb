require 'erb'
require 'fileutils'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'yaml'

def render_partial(name, locals = {})
  partial_path = File.expand_path("./templates/_#{name}.html.erb", __dir__)
  partial_source = File.read(partial_path)
  ERB.new(partial_source).result_with_hash(locals)
end

public_dir = File.expand_path('./public/', __dir__)

public_files = Dir.glob(public_dir + '/*')
FileUtils.rm_rf(public_files)

template_path = './templates/post.html.erb'
template = File.read(template_path)

FileUtils.mkdir_p(File.join(public_dir, 'posts'))

class Render < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
end
markdown = Redcarpet::Markdown.new(Render, extensions = { fenced_code_blocks: true })

posts_dir = File.expand_path('./posts/', __dir__)
post_paths = Dir.glob(posts_dir + '/*')
posts = post_paths.map do |post_path|
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

  @title = front_matter["title"]
  @date = Date.parse(front_matter["date"])
  @content = markdown.render(content_markdown)
  erb = ERB.new(template)
  result = erb.result(binding)
  output_path = "./public/posts/#{slug}.html"

  File.open(output_path, 'w') do |file|
    file.write(result)
  end
  [slug, @title, @date]
end

assets_src_dir = File.expand_path('./assets/', __dir__)
assets_dst_dir = File.expand_path('./public/assets/', __dir__)
FileUtils.mkdir_p(assets_dst_dir)
FileUtils.cp_r(Dir.glob(assets_src_dir + '/*'), assets_dst_dir)

index_template_path = './templates/index.html.erb'
index_template = File.read(index_template_path)
@title = "@utakaha"
erb = ERB.new(index_template)
result = erb.result_with_hash(posts: posts.sort_by { |_, _, date| date }.reverse)
File.open("./public/index.html", 'w') do |file|
  file.write(result)
end
