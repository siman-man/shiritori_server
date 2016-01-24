module ShiritoriServer
  class ShiritoriError < Exception; end

  class UseSameMethodError < ShiritoriError
    def message
      %q(Can't use same method.)
    end
  end

  class ShiritoriChainError < ShiritoriError
    def message
      %q(Failed method chain.)
    end
  end

  class UndefinedObjectError < ShiritoriError
    def message
      'Undefined Object'
    end
  end
end
