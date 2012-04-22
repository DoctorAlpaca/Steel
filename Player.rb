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
		# Cliff jumping not allowed.
		if @position[1] < 0
			@ground += 2 * dtime
			@position[1] = 0.0
			@speed[1] = 0.0
		end

		@ground = 0.1 if @ground > 0.1
		@ground = 0 if @ground < 0
	end

	def jump
		if @ground > 0.01
			@speed[1] = 15 
			@ground = 0
			$resource.play_sound("Jump.wav")
		end
	end

	def pos
		return position
	end
	def pos= (x)
		@position = x
	end

	def hitbox
		return SFML::Rect.new(@position[0] + 0.25, @position[1], 0.4, 0.8)
	end
end
