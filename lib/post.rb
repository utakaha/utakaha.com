class Post
  ROOT_PATH = File.expand_path('..', __dir__)

  def initialize(slug, title, date, content)
    @slug = slug
    @title = title
    @date = date
    @content = content
  end

  attr_reader :slug, :title, :date, :content

  def self.all
    markdown = Redcarpet::Markdown.new(Render, extensions = { fenced_code_blocks: true })
    post_paths = Dir.glob(File.expand_path('posts/', ROOT_PATH) + '/*')
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

      new(slug, title, date, content)
    end.sort_by { |post| post.date }.reverse
  end
end