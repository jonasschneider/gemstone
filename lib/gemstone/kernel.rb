module Gemstone
  module Kernel
    def self.puts(arg)
      [:call, :println, arg]
    end

    def self.typeof(arg)
      [:call, :typeof, arg]
    end

    def self.returnstr(arg)
      [:setres, arg]
    end

    def self.lvar_assign(arg)
      [:lvar_assign, arg, [:poparg]]
    end

    def self.lvar_get(arg)
      [:setres, [:lvar_get, arg]]
    end

    def self.run_lambda(arg)
      [:call_lambda, arg]
    end

    def self.set_message_dispatcher(arg)
      [:object_set_message_dispatcher, arg, [:poparg]]
    end
  end
end