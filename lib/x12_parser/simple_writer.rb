module X12
  class SimpleWriter
    
    class Transaction
      
    end

    class Level
      attr_accessor :xid
      attr_accessor :segments
    end

    class Segment
      attr_accessor :xid
      attr_accessor :children
      attr_accessor :elements

      def initialize
        @children = []
        @elements = []
      end
    end
    
    attr_accessor :segment_separator
    attr_accessor :element_separator

    def write

    end

  end
end
