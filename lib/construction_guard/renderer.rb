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

      # Read the ERB template file
      erb_template = File.read(template_path)
      binding_with_locals = binding
      binding_with_locals.local_variable_set(:message, options[:message])
      # Render the ERB template
      renderer = ERB.new(erb_template)
      renderer.result(binding_with_locals)
    end

    def self.find_template(template_name)
      gem_root = Gem.loaded_specs["construction_guard"].full_gem_path
      template_path = File.join(gem_root, "lib", "construction_guard", 'views', "#{template_name}.html.erb")
      File.exist?(template_path) ? template_path : nil
    end
  end
end
