module ShiritoriServer
  class SearchMethod
    class << self
      def get_all_methods
        @check_list = {}
        @method_list = []

        scan_method
        @method_list
      end

      def singleton(klass)
        class << klass;
          self
        end
      end

      def scan_method(klass = BasicObject)
        @check_list[klass] = true
        @method_list |= klass.instance_methods

        ObjectSpace.each_object(singleton(klass)) do |subclass|
          scan_method(subclass) if klass != subclass && @check_list[subclass].nil?
        end
      end
    end
  end
end
