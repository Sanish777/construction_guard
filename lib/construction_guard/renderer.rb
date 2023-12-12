require "erb"

module ConstructionGuard
  class Renderer
    def self.render_template(template_name, options = {})
      template_path = find_template(template_name)

      unless template_path
        template_path = File.join(File.dirname(__FILE__), 'views', 'default_template.html.erb')
        puts "Template '#{template_name}' not found. Rendering default template."
      end

      locals = { title: 'Default Title', greeting: 'Hello' }.merge(options)
      flash_messages = locals.delete(:flash) || {} # Extract flash messages

      # Read the ERB template file
      erb_template = File.read(template_path)
      binding_with_locals = binding

      # Set locals in the binding
      locals.each { |key, value| binding_with_locals.local_variable_set(key, value) }

      # Render the ERB template
      renderer = ERB.new(erb_template)
      rendered_template = renderer.result(binding_with_locals)

      # Inject flash messages into the rendered template
      inject_flash_messages(rendered_template, flash_messages)
    end

    def self.find_template(template_name)
      gem_root = Gem.loaded_specs["construction_guard"].full_gem_path
      template_path = File.join(gem_root, "lib", "construction_guard", 'views', "#{template_name}.html.erb")
      File.exist?(template_path) ? template_path : nil
    end

    def self.inject_flash_messages(template, flash_messages)
      template + "\n" + flash_messages.map { |key, value| "<div class='flash #{key}'>#{value}</div>" }.join("\n")
    end
  end
end
