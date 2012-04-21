require "sfml/graphics"

class Level

	attr_reader :width, :height

	def initialize (width = 20, height = 20)
		@width = width
		@height = height
		@level = Array.new(@width * @height) { :air }
	end

	def load_from_file (filename)
		File.open(filename, "r") do |file|
			x = 0
			y = 19
			
			file.each_line do |line|
				line.each_char do |char|
					break if char == "\n"
					puts x.to_s + ": " + char
					char.upcase!
					if char == "O"
						set_block(x, y, :ground)
					else
						set_block(x, y, :air)
					end
					x += 1
				end
				x = 0
				y -= 1
			end
						
		end
	end

	def get_block(x, y)
		x %= width
		y %= height
		return @level[x + y * width]
	end

	def set_block(x, y, value) 
		throw "Can't set level type to " + value.inspect if not value.is_a? Symbol
		if y > @height
			@height = y
		end
		@level[x + y * width] = value
	end

	def each_block
		@width.times do |x|
			@height.times do |y|
				yield x, y, get_block(x, y)
			end
		end
	end

	def collision? (with, blockType = :ground)
		each_block do |x, y, block|
			if block == blockType
				if with.intersects? (SFML::Rect.new(x, y, 1, 1))
					return true
				end
			end
		end
		return false 
	end
	
end
