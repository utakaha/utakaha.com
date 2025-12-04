require 'erb'

class TemplateRenderer
  def initialize(template, locals = {})
    @template = template
    @locals = locals
    locals.each do |key, value|
      define_singleton_method(key) { value }
    end
  end

  attr_reader :template, :locals

  def render(source = template)
    ERB.new(source).result(binding)
  end

  def render_partial(name)
    partial_path = File.expand_path("../templates/_#{name}.html.erb", __dir__)
    partial_source = File.read(partial_path)
    self.class.new(template, locals).render(partial_source)
  end
end
