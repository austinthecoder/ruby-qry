module Qry
  class NullInstrumenter
    def instrument(*)
      yield
    end
  end
end
