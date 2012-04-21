require "sfml/graphics"

class Star
	attr_accessor :position, :type
	def initialize (range_x = 5.0..5.5, range_y = -5.0..5.0)
		@position = [rand(range_x), rand(range_y)]
		@speed = -rand(0.01..0.1)
		@type = rand(0..4)
		@scale = rand(1..3)/2.0
	end

	def update dtime
		@position[0] += @speed * dtime
	end

	def sprite
		spr = SFML::Sprite.new $resource["Stars.png"]
		spr.texture_rect = [@type * 16, 0, 16, 16]
		spr.scale = [1/32.0*@scale, 1/32.0*@scale]
		spr.position = @position
		return spr
	end
end
