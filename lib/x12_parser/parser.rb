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

  class Parser
    attr_accessor :line_count
    attr_accessor :current_level
    attr_accessor :track_level
    attr_accessor :segment_separator
    attr_accessor :element_separator

    attr_accessor :cf
    attr_accessor :segment_list

    attr_accessor :file_handle
    attr_accessor :array_of_handles

    attr_accessor :last_read_segment
    attr_accessor :last_read_loop

    def initialize
      @line_count = 0
      @current_level = nil
      @track_level = nil
      @element_separator = nil
      @segment_separator = nil

      @cf = nil
      @segment_list = nil

      @array_of_handles = []

      @last_read_segment = nil
      @last_read_loop = nil
    end

    def get_edi_type(file)

      file_contents = nil

      File.open(file, 'r') do |file|
        file_contents = file.read
        file_contents = file_contents.strip
      end

      self._set_separators(file_contents)
      @segment_list = file_contents.split(@segment_separator)
      @segment_list.each do |segment|

        elements = segment.split(@element_separator)

        if elements[0] == 'ST'
          return elements[1]
        end 
      end

      return nil

    end

    def parse(options = {})
      file = options[:file]
      conf = options[:conf]

      @cf = X12::CF.new
      @cf.load(conf) if conf

      p conf

      @track_level = 1
      level_one = @cf.get_level_one

      @array_of_handles.unshift(level_one)

      file_contents = nil
      File.open(file, 'r') do |file|
        file_contents = file.read
        file_contents = file_contents.strip
      end

      self._set_separators(file_contents)
      @segment_list = file_contents.split(@segment_separator)

      file_contents

    end

    def _set_separators(file_contents)
      isa = nil

      begin
        isa = file_contents[0, 106]

        @segment_separator = isa[105].chr
        @element_separator = isa[3].chr
      rescue
        nil
      end

    end

    def _parse_loop_start

      current_loop = nil
      segment = nil
      segment_list = nil

      if @last_read_loop != nil
        tmp = @last_read_loop
        @last_read_loop = nil
        return tmp
      end

      @segment_list[@line_count..-1].each do |segment|

        @line_count += 1
        segment_list = segment.split(@element_separator)

        @last_read_segment = segment_list

        @array_of_handles.each do |level_handle|
          level_handle.each do |tree_index|

            xloop = @cf.loop_trees[tree_index].loop

            left = @cf.segmentstart[xloop][0].split(':')

            if left[0] == segment_list[0]
              if left[2] == ''
                current_loop = @cf.loop_trees[tree_index].loop
                @current_level = @cf.loop_trees[tree_index].level
                diff = @track_level - @cf.loop_trees[tree_index].level
                @track_level = @cf.loop_trees[tree_index].level

                while diff > 0
                  @array_of_handles.shift
                  diff -= 1
                end

                next_level = @cf.get_next_level(tree_index)
                if 'END' != next_level[0]
                  @track_level += 1
                  @array_of_handles.unshift(next_level)
                  return current_loop
                end
                return current_loop

              else

                qual = left[2].split(',')
                if qual.include?(segment_list[left[1].to_i])
                  current_loop = @cf.loop_trees[tree_index].loop
                  @current_level = @cf.loop_trees[tree_index].level
                  diff = @track_level - @cf.loop_trees[tree_index].level
                  @track_level = @cf.loop_trees[tree_index].level

                  while diff > 0
                    @array_of_handles.shift
                    diff -=1
                  end

                  next_level = @cf.get_next_level(tree_index)
                  if 'END' != next_level[0]
                    @track_level += 1
                    @array_of_handles.unshift(next_level)
                    return current_loop;
                  end
                  return current_loop
                end
              end
            end
          end
        end
      end
    end

    def _parse_loop
      segment = nil
      segment_list = nil
      xloop = []

      if @last_read_segment != nil
        xloop.push(@last_read_segment)
        @last_read_segment = nil
      end

      @segment_list[@line_count..-1].each do |segment|

        @line_count += 1

        segment_list = segment.split(@element_separator)
        @last_read_segment = segment_list

        @array_of_handles.each do |level_handle|
          level_handle.each do |tree_index|

            tmp_loop = @cf.loop_trees[tree_index].loop
            left = @cf.segmentstart[tmp_loop][0].split(':')

            if left[0] == segment_list[0]

              if left[2] == ''
                @last_read_loop = @cf.loop_trees[tree_index].loop
                @current_level = @cf.loop_trees[tree_index].level
                diff = @track_level - @cf.loop_trees[tree_index].level
                @track_level = @cf.loop_trees[tree_index].level

                while diff > 0
                  @array_of_handles.shift
                  diff -= 1
                end

                next_level = @cf.get_next_level(tree_index)
                if 'END' != next_level[0]
                  @track_level += 1
                  @array_of_handles.unshift(next_level)
                  return xloop
                end

                return xloop

              else
                qual = left[2].split(',')

                if qual.include?(segment_list[left[1].to_i])

                  @last_read_loop = @cf.loop_trees[tree_index].loop
                  @current_level = @cf.loop_trees[tree_index].level
                  diff = @track_level - @cf.loop_trees[tree_index].level
                  @track_level = @cf.loop_trees[tree_index].level

                  while diff > 0
                    @array_of_handles.shift
                    diff -=1
                  end

                  next_level = @cf.get_next_level(tree_index)
                  if 'END' != next_level[0]
                    @track_level += 1
                    @array_of_handles.unshift(next_level)
                    return xloop
                  end
                  return xloop
                end # if qual.include?
              end #  if left[2] == ''
            end # if left[0] == segment_list[0]
          end # level.handle.each
        end # @array_of_handles.each
        xloop.push(segment_list)
      end # @segment_list[@line_count..-1].each
      return xloop
    end

    def get_next_loop

      xloop = nil

      xloop = self._parse_loop_start

      if 'IEA' == xloop
        #self._set_separator
      end

      return false if not xloop or xloop.size == 0

      return xloop
    end

    def get_next_pos_loop
      loop = []

      loop = self._parse_loop_start

      return false if not loop or loop.size == 0

      [ @line_count, loop ]

    end

    def get_next_pos_level_loop
      loop = []

      loop = self._parse_loop_start

      return false if not loop or loop.size == 0

      return [ @line_count, @current_level, loop ]

    end

    def get_loop_segments
      xloop = []

      xloop = self._parse_loop

      [ @line_count, xloop ]

    end

    def print_tree

      pad = nil
      index = nil
      segment = nil

      while line = self.get_next_pos_level_loop

        pos = line[0].to_i
        level = line[1].to_i
        loop = line[2]

        if level != 0
          pad = '  |' * level
          print "       #{pad}-- #{loop}\n"
          tmp_level = level + 1
          tmp_pad = '  |' * tmp_level
          tmp_loop = self.get_loop_segments

          tmp_loop.each do |segment|
            index = sprintf("%+7s", pos)
            pos = pos += 1
            print "#{index}#{tmp_pad}-- #{segment}\n"
          end
        end
      end
    end

    class EdiItem

      attr_accessor :loop_xid
      attr_accessor :xid
      attr_accessor :elements
      attr_accessor :children

      def initialize
        @loop_xid = ''
        @xid = ''
        @elements = []
        @children = []
      end
    end
  end
end
