#!/usr/bin/env ruby
#
# FF3 Intro Screen text tool
#
# Copyright (c) 2014, Tim Hentenaar
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Text translation table
xlate = {
	'0'  => 0x01, '1'  => 0x02, '2'  => 0x03, '3'  => 0x04, '4'  => 0x05,
	'5'  => 0x06, '6'  => 0x07, '7'  => 0x08, '8'  => 0x09, '9'  => 0x0a,
	'A'  => 0x0b, 'B'  => 0x0c, 'C'  => 0x0d, 'D'  => 0x0e, 'E'  => 0x0f,
	'F'  => 0x10, 'G'  => 0x11, 'H'  => 0x12, 'I'  => 0x13, 'J'  => 0x14,
	'K'  => 0x15, 'L'  => 0x16, 'M'  => 0x17, 'N'  => 0x18, 'O'  => 0x19,
	'P'  => 0x1a, 'Q'  => 0x1b, 'R'  => 0x1c, 'S'  => 0x1d, 'T'  => 0x1e,
	'U'  => 0x1f, 'V'  => 0x20, 'W'  => 0x21, 'X'  => 0x22, 'Y'  => 0x23,
	'Z'  => 0x24, 'a'  => 0x25, 'b'  => 0x26, 'c'  => 0x27, 'd'  => 0x28,
	'e'  => 0x29, 'f'  => 0x2a, 'g'  => 0x2b, 'h'  => 0x2c, 'i'  => 0x2d,
	'j'  => 0x2e, 'k'  => 0x2f, 'l'  => 0x30, 'm'  => 0x31, 'n'  => 0x32,
	'o'  => 0x33, 'p'  => 0x34, 'q'  => 0x35, 'r'  => 0x36, 's'  => 0x37,
	't'  => 0x38, 'u'  => 0x39, 'v'  => 0x3a, 'w'  => 0x3b, 'x'  => 0x3c,
	'y'  => 0x3d, 'z'  => 0x3e, '\'' => 0x40, ','  => 0x41, '.'  => 0x42,
	'-'  => 0x43, '!'  => 0x45, '?'  => 0x46, '%'  => 0x47, '/'  => 0x48,
	':'  => 0x49, '"'  => 0x4b, '@'  => 0x4d
}

text    = []    # Array of output bytes
dq_flag = false # True, if we have encountered a "

# Read and translate the text from STDIN
$stdin.each_char do |c|
	case c
	when "\n" # End of Line
		text << 0xaa if text[-1] != 0xac
	when '$'  # End of Page
		text << 0xac
	else
		if xlate.has_key?(c)
			text << xlate[c]
		else
			text << 0
		end

		# Check for " and "
		if c == '"' and dq_flag
			dq_flag = false
			text[-1] = 0x4c
		elsif c == '"'
			dq_flag = true
		end

		# Check for '...'
		if text.length > 2 and c == '.'
			if text[-2] == 0x42 and text[-3] == 0x42
				text[-3] = 0x4a
				text.delete_at(-2)
				text.delete_at(-1)
			end
		end
	end
end

# Now, write the text out to text.bin
File.open('text.bin', 'w+') do |fp|
	fp.write text.pack('C*')
end

# vi:set ts=2 sw=2:
