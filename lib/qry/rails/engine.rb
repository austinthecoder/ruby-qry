module Qry
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Qry

      config.eager_load_paths += [config.root.join('lib')]
    end
  end
end
