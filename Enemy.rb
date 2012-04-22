class Enemy
	attr_accessor :type, :position
	def initialize (position, type = :robot, speed = nil)
		@type = type
		@position = position
		@speed = [0, 0]
		case @type
			when :robot
				@speed = [-3, 0]
			when :energy
				@speed = [-4, 0]
		end
		@speed = speed if not speed.nil?
	end

	def update (dtime, obstacles)
		case @type
			when :robot
				@position[0] += @speed[0] * dtime
				if obstacles.collision? hitbox
					@position[0] -= 2 * @speed[0] * dtime
					@speed[0] *= -1
				end
				@position[0] %= 20

				@position[1] += @speed[1] * dtime
				if obstacles.collision? hitbox or position[1] < 0
					@position[1] -= @speed[1] * dtime
					@speed[1] = 0
				else
					@speed[1] -= $grav * dtime
				end
			when :energy
				@position[0] += @speed[0] * dtime
				if obstacles.collision? hitbox
					@position[0] -= 2 * @speed[0] * dtime
					@speed[0] *= -1
				end
				@position[0] %= 20
		end
		$bug.show "Enemy", @position
	end

	def hitbox
		case type
			when :robot then SFML::Rect.new(@position[0] + 0.25, @position[1], 0.4, 0.8)
			when :energy then SFML::Rect.new(@position[0] + 0.25, @position[1] + 0.25, 0.5, 0.5)
			when :rocket then SFML::Rect.new(@position[0] + 0.25, @position[1] + 0.25, 2, 4)
		end
	end
end
