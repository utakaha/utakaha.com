require 'erb'

class TemplateRenderer
  def initialize(template, locals = {})
    @template = template
    @locals = locals
    locals.each do |key, value|
      define_singleton_method(key) { value }
    end
  end

  def render_template
    render(@template)
  end

  def render(source)
    ERB.new(source).result(binding)
  end

  def with_locals(extra_locals = {})
    self.class.new(@template, @locals.merge(extra_locals))
  end

  def render_partial(name, locals = {})
    partial_path = File.expand_path("../templates/_#{name}.html.erb", __dir__)
    partial_source = File.read(partial_path)
    with_locals(locals).render(partial_source)
  end
end
