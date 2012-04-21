require "sfml/graphics"

class Player
	attr_accessor :position, :speed, :ground
	def initialize(pos = [0, 0])
		@position = pos
		@speed = [0, 0]
		@ground = 0.0
	end

	def update(dtime, obstacles)
		@ground -= 1 * dtime

		@speed[1] -= $grav * dtime
		
		@speed[0] += -$breakx * @speed[0] * dtime
		@speed[1] += -$breaky * @speed[1] * dtime
		
		@position[0] += @speed[0] * dtime
		if obstacles.collision? hitbox
			@position[0] -= @speed[0] * dtime
		end
		@position[1] += @speed[1] * dtime
		if obstacles.collision? hitbox
			@ground += 2 * dtime if @speed[1] < 0
			@position[1] -= @speed[1] * dtime
			@speed[1] = 0
		end

		@ground = 0.1 if @ground > 0.1
		@ground = 0 if @ground < 0
	end

	def jump
		@speed[1] = 15 if @ground > 0.01
		@ground = 0 if @ground > 0.01
	end

	def pos
		return position
	end
	def pos= (x)
		@position = x
	end

	def hitbox
		return SFML::Rect.new(@position[0] + 0.2, @position[1], 0.5, 0.8)
	end
end
