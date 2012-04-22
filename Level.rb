require "sfml/graphics"

class Level

	attr_reader :width, :height, :enemies

	def initialize (width = 20, height = 20)
		@width = width
		@height = height
		@level = Array.new(@width * @height) { { :type => :air, :morph => 0, :old_type => :air } }
		@heights = Array.new(@width)
		@enemies = Array.new
	end

	def load_from_file (filename)
		@enemies.clear
		filename = "resource/" + filename
		puts "Loading level"
		File.open(filename, "r") do |file|
			x = 0
			y = 19

			@width.times do |i|
				@heights[i] = 0
			end
			
			file.each_line do |line|
				line.each_char do |char|
					break if char == "\n"
					char.upcase!
					if char == "O"
						set_block_type(x, y, :ground)
						@heights[x] = y if @heights[x] <= y
					elsif char == "I"
						set_block_type(x, y, :ground)
					elsif char == "L"
						set_block_type(x, y, :lever)
						@heights[x] = y if @heights[x] <= y
					elsif char == "R"
						set_block_type(x, y, :air)
						@enemies.push(Enemy.new([x, y], :robot))
					elsif char == "E"
						set_block_type(x, y, :air)
						@enemies.push(Enemy.new([x, y], :energy))
					elsif char == "K"
						set_block_type(x, y, :cat)
					elsif char == "X"
						set_block_type(x, y, :air)
						@enemies.push(Enemy.new([x, y], :rocket))
					else
						set_block_type(x, y, :air)
					end
					x += 1
				end
				x = 0
				y -= 1
			end

			@heights.each_index do |x|
				@heights[x].times do |i|
					# set_block_type overrides the :old_type flag, so it is preserved here.
					old = get_block(x, i)[:old_type]
					set_block_type(x, i, :bg) if get_block_type(x, i) == :air
					get_block(x, i)[:old_type] = old
				end
			end
						
		end
		each_block do |x, y, block|
			block[:morph] = 0.0
		end
	end

	def get_block(x, y)
		x %= width
		y = [y, 19].min
		return @level[x + y * width]
	end
	def get_block_type(x, y)
		return get_block(x, y)[:type]
	end

	def set_block(x, y, value)
		throw "Level address out of bounds!" if x > width or y > height
		@level[x + y * width] = value
	end
	def set_block_type(x, y, value) 
		get_block(x, y)[:old_type] = get_block(x, y)[:type]
		get_block(x, y)[:type] = value
	end

	def each_block (range_x = 0..(@width), range_y = 0..(@height-1))
		range_x.each do |x|
			range_y.to_a.reverse.each do |y|
				yield x, y, get_block(x, y)
			end
		end
	end

	def collision? (with, blockType = :ground)
		range_x = with.left.to_i
		range_x = (range_x-1)..(range_x+1)
		range_y = with.top.to_i
		range_y = (range_y-1)..(range_y+1)
		range_x.each do |x|
			range_y.to_a.reverse.each do |y|
				block = get_block(x, y)
				if block[:type] == blockType
					if blockType == :lever
						if with.intersects? (SFML::Rect.new(x+0.4, y, 0.2, 1))
							return true
						end
					else
						if with.intersects? (SFML::Rect.new(x, y, 1, 1))
							return true
						end
					end
				end
			end
		end
		return false 
	end

	def update dtime
		each_block do |x, y, block|
			block[:morph] += dtime * 2
			block[:morph] = 1.0 if block[:morph] > 1.0
		end
		@enemies.each { |e| e.update dtime, self }
	end
end
