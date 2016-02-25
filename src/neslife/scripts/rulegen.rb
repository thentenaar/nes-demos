#!/usr/bin/env ruby
#
# neslife Rule Table Generator
#
# This script expects that a list of rules will
# be passed in on the command line, for example:
#
# tablegen.rb B3S23 B34S34 ...
#
# It will then generate a seperate .asm file for each
# rule, containing a set of tables for that rule; as
# well as a .inc file assigning the bank number used
# to a symbolic constant for the given rule.
#
# All rule tables are page-aligned.
#

bank      = 0
tables    = [ '16', '25', '34' ]
subtables = [ 'all_dead', 'both_alive', 'left_only', 'right_only' ]
tabline   = "\t.byte $%02x, $%02x, $%02x, $%02x, $%02x, $%02x, $%02x, $%02x\n"

#
# Parse a string in the form "BxSx" and return a hash table
# containing two arrays, one for the "B" state, and one for
# the "S" state with the counts needed for each state.
#
def parse_rule_string(str)
	ret = { 'B' => [], 'S' => [] }
	b, s = str.split('S')
	b.gsub!(/^[BS]/, '')
	b.each_char { |c| ret['B'].push(c.to_i) }
	s.each_char { |c| ret['S'].push(c.to_i) }
	ret
end

#
# The table must be able to handle each
# possible number of neighbors for each
# rule.
#
# Each table will range from $00 - $8f (144 bytes.)
#
def build_rule_table(tab, stab, rule)
	xtab = [ 0 ] * 144
	rval = parse_rule_string(rule)

	case tab
	when '16'
		(0..8).each do |i|
			(0..8).each do |j|
				case stab
				when 'all_dead'
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x40
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x02
					end
				when 'both_alive'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x40
					end
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x02
					end
				when 'left_only'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x40
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x02
					end
				when 'right_only'
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x02
					end
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x40
					end
				end
			end
		end
	when '25'
		(0..8).each do |i|
			(0..8).each do |j|
				case stab
				when 'all_dead'
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x20
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x04
					end
				when 'both_alive'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x20
					end
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x04
					end
				when 'left_only'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x20
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x04
					end
				when 'right_only'
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x04
					end
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x20
					end
				end
			end
		end
	when '34'
		(0..8).each do |i|
			(0..8).each do |j|
				case stab
				when 'all_dead'
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x10
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x08
					end
				when 'both_alive'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x10
					end
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x08
					end
				when 'left_only'
					if rval['S'].include?(i) || rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x10
					end
					if rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x08
					end
				when 'right_only'
					if rval['S'].include?(j) || rval['B'].include?(j)
						xtab[(i << 4) + j] |= 0x08
					end
					if rval['B'].include?(i)
						xtab[(i << 4) + j] |= 0x10
					end
				end
			end
		end
	end
	xtab
end

#
# Generate the table files
#
table_inc = File.open('rules.inc', 'w+')
table_inc.write(";\n; neslife - Conway's Game of Life for the NES\n")
table_inc.write("; Copyright (C) 2016 Tim Hentenaar.\n")
table_inc.write("; See the LICENSE file for details.\n")
table_inc.write(";\n; These defines map the rules to their respective\n")
table_inc.write("; banks.\n;\n\n")

ARGV.each do |rule|
	unless rule.match(/^B\d+(S\d+)?/)
		puts "Invalid Rule: #{rule}"
		next
	end

	table_inc.write(".define BANK_#{rule} $#{'%02X' % bank}\n")
	File.open("rules/#{rule}.asm", 'w+') do |fp|
		fp.write(";\n; neslife - Conway's Game of Life for the NES\n")
		fp.write("; Copyright (C) 2016 Tim Hentenaar.\n")
		fp.write("; See the LICENSE file for details.\n;\n\n")

		# The code will import these symbols from the table on
		# the first bank, since the others will be at the same
		# addresses.
		unless bank > 0
			fp.write(".export table_16_all_dead, table_16_both_alive\n")
			fp.write(".export table_16_left_only, table_16_right_only\n")
			fp.write(".export table_25_all_dead, table_25_both_alive\n")
			fp.write(".export table_25_left_only, table_25_right_only\n")
			fp.write(".export table_34_all_dead, table_34_both_alive\n")
			fp.write(".export table_34_left_only, table_34_right_only\n\n")
		end

		# Set the segment to the proper bank
		fp.write(".segment \"BANK#{'%X' % bank}\"\n")

		# Write the tables, ensuring page alignment
		tables.each { |tab|
			subtables.each { |stab|
				fp.write("\n.align 256\ntable_#{tab}_#{stab}:\n")
				xtab = build_rule_table(tab, stab, rule)
				(0..17).each { |x|
					fp.write(tabline % [
						xtab[x*8],   xtab[x*8+1], xtab[x*8+2], xtab[x*8+3],
						xtab[x*8+4], xtab[x*8+5], xtab[x*8+6], xtab[x*8+7]
					])
				}
			}
		}

		fp.write("\n; vi:set ft=ca65:")
	end
	bank += 1
end

table_inc.write("\n; vi:")
table_inc.write("set ft=ca65:")
table_inc.close

# vi:set ft=ruby ts=2 sw=2:

