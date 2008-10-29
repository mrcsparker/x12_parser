require 'x12'

Dir["/opt/adelpo/data/edi/*"].each do |d|

  parser = X12::Parser.new
  edi_type = parser.get_edi_type(d)
  next if not edi_type
  next if edi_type != '810'
  parsed = parser.parse(:file => d, :conf => edi_type + ".cf")
  
  edi_file = nil
  edi_transactional = nil
  edi_segment_loop = nil

  next if not parsed

  edi_file = Edi::File.new
  edi_file.file_name = File.basename(d)
  edi_file.data = parsed
  edi_file.save

  old_x12_level = 1
  old_level_xid = ''
  new_level_xid = 'foobar'

  in_transaction = false

  while line = parser.get_next_pos_level_loop
    
    x12_pos = line[0].to_i
    x12_level = line[1].to_i
    x12_loop = line[2]

    segments = parser.get_loop_segments

    s = segments[1]
    s.each do |segment|
    
      if segment[0] == "ST"
        
        level_xid = x12_loop.split('-')
        next if level_xid.size < 2
        next if level_xid[1] != 'H'
     
        new_level_xid = level_xid[1]

        edi_transactional = edi_file.transactionals.new
        edi_transactional.transaction_type = edi_type
        edi_transactional.save
        
        in_transaction = true

      end

      if in_transaction == true

        level_xid = x12_loop.split('-')
        new_level_xid = level_xid[1]

        if old_level_xid != new_level_xid 
          edi_level = edi_transactional.levels.new
          edi_level.xid = new_level_xid
          edi_level.save
        end

        if old_x12_level == x12_level or old_x12_level < x12_level
          edi_segment_loop = Edi::SegmentLoop.new
          edi_segment_loop.xid = x12_loop
          edi_segment_loop.transactional_id = edi_transactional.id
          edi_segment_loop.save
        else
          edi_segment_loop = Edi::SegmentLoop.new
          edi_segment_loop.xid = x12_loop
          edi_segment_loop.transactional_id = edi_transactional.id
          edi_segment_loop.save
        end

        #p segment

        segment.each do |elements|
          
          
          #p x12_loop
          #p elements
        end

      end

      if segment[0] == "SE"
        in_transaction = false
      end

      old_x12_level = x12_level
      old_level_xid = new_level_xid if in_transaction and level_xid

    end
  end


end
