# This file is part of Ruby X12-Parser (x12-parser)
#
# Copyright (C) 2008 Chris Parker
# All rights reserved
#
# Based on Perl X12::Parser by
# Prasad Poruporuthan
# http://search.cpan.org/src/PRASAD/X12-0.09
#
# x12-parser is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# x12-parser is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with x12-parser.  If not, see <http://www.gnu.org/licenses/>.


module X12

  class LoopTree
    attr_accessor :loop
    attr_accessor :level
  end

  class CF

    attr_accessor :loop_trees
    attr_accessor :segmentstart
    attr_accessor :file_contents
    attr_accessor :loops
    attr_accessor :level

    def initialize
      @loop_trees = []
      @segmentstart = {}
      @file_contents = []
      @loops = []
    end

    def load(file)
      
      load_file = nil   

      local_path = File.dirname(__FILE__).to_s + "/../../cf/#{file}"

      if File.exist?(file)
        load_file = file
      end

      if File.exist?(local_path)
        load_file = local_path
      end

      return false if not load_file

      File.open(load_file, 'r') { |file|
        file.each do |line|
          @file_contents << line.strip
        end
      }

      self._find_loops
      self._parse_loops
    end

    def _find_loops

      in_loops = false

      @file_contents.each do |line|
        if line == '[LOOPS]'
          in_loops = true
          next
        end

        return if line == ''

        @loops << line if in_loops == true

      end
    end

    def _parse_loops

      @loops.each { |loop|
        @level = 0
        _parse_loop(loop)
      }
      @loops.each { |loop|
        _parse_segment(loop)
      }
    end

    def _parse_loop(loop)

      in_loop = false

      @level += 1

      @file_contents.each { |line|

        if line == "[#{loop}]"

          loop_tree = LoopTree.new
          loop_tree.loop = loop
          loop_tree.level = @level
          @loop_trees << loop_tree
          in_loop = true

        elsif in_loop == true and line =~ /^loop=/
          tmp = line.split('=')
          _parse_loop(tmp[1])
          @level -= 1
        end

        return if in_loop and line == ''
      }

    end

    def _parse_segment(loop)

      in_loop = false

      @file_contents.each { |line|

        if line == "[#{loop}]"
          in_loop = true
        end

        if in_loop == true

          if line =~ /^segment=/
            tmp = line.split('=')
            @segmentstart[loop] = [] if not @segmentstart[loop]
            @segmentstart[loop] << tmp[1]
          end

          if line =~ /^loop=/
            tmp = line.split('=')
            _parse_segment(tmp[1])
          end
        end

        return if in_loop == true and line == ''

      }
    end

    def get_level_one

      tmp = []

      i = 0

      @loop_trees.each do |lt|
        if lt.level == 1
          tmp.push(i)
        end

        i += 1
      end
      tmp

    end

    def get_next_level(current_pos)
      current_level = @loop_trees[current_pos].level || 0

      if @loop_trees[current_pos + 1]
        next_level = @loop_trees[current_pos + 1].level
      else
        next_level = 0
      end

      tmp = []

      if current_level < next_level
        current_pos += 1

        while @loop_trees[current_pos].level > current_level
          if @loop_trees[current_pos].level == next_level
            tmp.push(current_pos)
          end
          current_pos += 1
        end
      else
        tmp.push('END')
      end

      tmp

    end

  end

end
