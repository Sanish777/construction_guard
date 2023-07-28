module ConstructionGuard
  class Engine < Rails::Engine
    isolate_namespace ConstructionGuard

    # Make sure the gem's assets and views are available
    initializer "construction_guard.assets.precompile" do |app|
      app.config.assets.precompile += %w[construction_guard.css]
    end

    initializer "construction_guard.views" do |_app|
      gem_root = Gem.loaded_specs["construction_guard"].full_gem_path
      views_path = File.join(gem_root, "app", "views")
      ActiveSupport.on_load :action_controller do
        append_view_path(views_path)
      end
    end
  end
end
