#!/usr/bin/env ruby

# Convert a CASPER core_info.tab file to its binary CSL representation.
#
# core_info.tab files contain lines describing how CASPER yellow blocks are
# mapped into the memory space of a CAPER FPGA design.  Historically, each line
# is a core_info.tab file consists of four fields: device name, access mode,
# offset, and length.  Modern core_info.tab files have a fifth field that
# indicates the type of yellow block.  Clients can use this block type
# information to determine how to interpret the contents of the block's memory
# region.
#
# When converting a core_info.tab file to its binary CSL representation, the
# device names are the strings of the CSL.  The payload of each CSL entry
# consist of offset/mode, length, and type code.  Offset/mode is the four byte
# offset within the FPGA memory space with the least significant bit being a
# read-only flag.  Because FPGA devices are always at 4-byte aligned offsets,
# the two least significant bits are implicitly 0 so these bits can be used to
# carry additional information such as a read-only flag.  If the device is
# read-only (i.e. unwritable) then the offset's LSb will be a '1'.  The length
# field is also stored as four bytes.  The type code field is stored as a
# single byte.
#
# The offset and length fields are stored in network byte order (big endian).

require 'stringio'

# Read lines
lines = ARGF.readlines

# Sort lines
lines.sort!

# Parse lines
lines.map! do |l|
  dev, mode, offset, length, type = l.split
  offset = offset.to_i(16)
  offset |= 1 if mode == '1'
  length = length.to_i(16)
  # Missing type defaults to 0 (register)
  type = type ? type.to_i(16) : 0

  [dev, [offset, length, type]]
end

cslio = StringIO.new
cslio.set_encoding('binary')

payload_length = [0,0,0].pack('NNc').length

prev = ''

lines.each do |dev, entry|
  reuse = prev.length
  for i in 0...prev.length
    if prev[i] != dev[i]
      reuse = i
      break
    end
  end

  tail = dev[reuse..-1]
  entry.unshift(tail)
  entry.unshift(tail.length)
  entry.unshift(cslio.pos > 0 ? reuse : payload_length)
  cslio.print entry.pack('cca*NNc')
  #STDERR.puts entry.inspect

  prev[reuse..-1] = tail
end

# Output list terminator
cslio.print "\0\0"

# Output CSL
print [cslio.length].pack('n')
print cslio.string
