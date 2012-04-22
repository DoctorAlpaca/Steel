require "sfml/graphics"
require_relative "ResourceManager"
require_relative "Level"
require_relative "Player"
require_relative "Debug"
require_relative "Star"
require_relative "util"
require_relative "Enemy"

$resource = ResourceManager.new
$tex_size = 32
$speed = 7
$grav = 50
$bug = Debug.new

class Game
	def initialize
		@app = SFML::RenderWindow.new([640, 640], "Steel")
		#@app.vertical_sync_enabled = true
		@cam = SFML::View.new([0, -10], [10, 10])
		@app.view = @cam
		@timer = SFML::Clock.new
		@level_nr = 6
		@level = Level.new
		@level.load_from_file(@level_nr.to_s + ".lvl")
		@player = Player.new
		@checkpoint = [@player.pos[0], @player.pos[1]]
		@stars = Array.new(30) { Star.new(-5.0..5.0, -5.0..5.0) }
		# TODO enable title
		@title = false
		@title_fade = 2.0
	end

	def draw_title
		kitten = SFML::Sprite.new $resource["kitten.png"]
		kitten.position = [640 - 58, 640 - 26 - 125]
		
		rbSFML = SFML::Sprite.new $resource["rbSFML.png"]
		rbSFML.position = [640 - 200, 640 - 150]

		rbSFML.color = kitten.color = [255, 255, 255, (@title_fade / 2.0 * 255).to_i]
		
		view = SFML::View.new
		view.viewport = [0, 0, 640, 640]
		@app.view = @app.default_view

		@app.draw kitten
		@app.draw rbSFML
		
		@app.view = @cam
	end

	def draw
		# Draw stars
		@app.view = SFML::View.new([0, 0], [10, 10])
		@stars.each do |star|
			@app.draw star.sprite
		end
		@app.view = @cam
		
		# Draw level
		@level.each_block -10..30 do |x, y, block|
			m = block[:morph]
			x = x.to_f
			if block[:old_type] == :air
				y *= m
			end
			if block[:type] == :ground
				if block[:old_type] == :bg
					draw_object(x, y, :ground, [(255 * m + 100 * (1-m)).to_i]*3)
				else
					draw_object(x, y, :ground)
				end
			elsif block[:type] == :bg
				if block[:old_type] == :ground
					draw_object(x, y, :bg, [(255 * (1-m) + 100 * m).to_i]*3)
				else
					draw_object(x, y, :bg)
				end
			elsif block[:type] == :air
				y *= (1-m)
				draw_object(x, y, block[:old_type])
			else
				draw_object(x, y, :bg)
				draw_object(x, y, block[:type])
			end
		end
		# Draw ground of planet
		(-10..30).each do |x|
			draw_object(x, -1, :planet_ground)
		end
		rect = SFML::RectangleShape.new([40, 40])
		rect.position = [-10, 1]
		rect.fill_color = [0, 0, 0]
		@app.draw rect

		# Draw enemies
		@level.enemies.each do |x|
			draw_object(x.position[0], x.position[1], x.type)
			draw_object(x.position[0] - 20, x.position[1], x.type)
			draw_object(x.position[0] + 20, x.position[1], x.type)
		end
		
		# Draw player
		draw_object(@player.pos[0], @player.pos[1], :player)

		# Draw debug text TODO remove
		txt = $bug.text
		@app.view = SFML::View.new([320, 320], [640, 640])
		txt.scale = [0.5, 0.5]
		@app.draw txt
		@app.view = @cam

		# Guess.
		draw_title unless @title_fade < 0
	end

	# Draws a single graphic, applying transformations (not much anymore).
	def draw_object (x, y, type, color = nil)

		y = -y - 1

		sprite = SFML::Sprite.new
		case type
			when :ground
				sprite.texture = $resource["BlockLow.png"]
			when :bg
				sprite.texture = $resource["BlockLow.png"]
				sprite.color = [100, 100, 100]
			when :air
				return
			when :player
				sprite.texture = $resource["Player.png"]
			when :planet_ground
				sprite.texture = $resource["Ground.png"]
			when :lever
				sprite.texture = $resource["Lever.png"]
			when :robot
				sprite.texture = $resource["Robot.png"]
			when :energy
				sprite.texture = $resource["Energy.png"]
		end
		if not color.nil?
			sprite.color = color
		end
		sprite.scale = [1.0/$tex_size]*2
		sprite.position = [x, y]
		@app.draw sprite
	end

	def update (dtime)
		if @title
			@title = false if SFML::Keyboard.key_pressed? SFML::Keyboard::Return
		else
			# Update title screen
			@title_fade -= dtime
			@title_fade = -1 if @title_fade < -1
			
			# Update player
			@player.speed[0] = 0
			@player.speed[0] = $speed if SFML::Keyboard.key_pressed? SFML::Keyboard::Right
			@player.speed[0] = -$speed if SFML::Keyboard.key_pressed? SFML::Keyboard::Left
			@player.jump if SFML::Keyboard.key_pressed? SFML::Keyboard::Up
			@player.update dtime, @level
			if @player.pos[0] > 20
				@player.pos[0] -= 20
				@cam.center = [@cam.center.x - 20, @cam.center.y]
			elsif @player.pos[0] < 0
				@player.pos[0] += 20
				@cam.center = [@cam.center.x + 20, @cam.center.y]
			end
		end

		# Advance level?
		if @level.collision?(@player.hitbox, :lever)
			@level_nr += 1
			@level.load_from_file(@level_nr.to_s + ".lvl")
			$resource.play_sound("Change.wav")
		@checkpoint = [@player.pos[0], @player.pos[1]]
		end
		
		# Update stars
		@stars.each_index do |i|
			@stars[i].update dtime
			@stars[i] = Star.new if @stars[i].position[0] < -5.5
		end
		
		# Update blocks
		@level.update dtime

		# Check for enemy collision
		hit = false
		@level.enemies.each do |x|
			if x.hitbox.intersects? @player.hitbox
				hit = true
			end
		end
		restart if hit

		restart(false) if SFML::Keyboard.key_pressed? SFML::Keyboard::R
		
		# Update camera
		@cam.center = [@cam.center.x, -@cam.center.y]
		@cam.center += SFML::Vector2.new((@player.pos[0] - @cam.center.x) * dtime * 10, (@player.pos[1] - @cam.center.y) * dtime * 10)
		@cam.center = [@cam.center.x, -@cam.center.y]
		
		# Update resources
		$resource.update
		
		# Debug display TODO remove
		$bug.show "Checkpoint", @checkpoint
	end

	def restart (sound = true)
		@player.position = [@checkpoint[0], @checkpoint[1]]
		@cam.center = [@cam.center.x - 20, @cam.center.y] if (@cam.center.x - @player.pos[0]).abs > 10
		@level.load_from_file(@level_nr.to_s + ".lvl")
		$resource.play_sound("Hit.wav") if sound
	end

	def game_loop
		@timer.restart
		
		while @app.open?
			dtime = @timer.restart.asSeconds

			$bug.show "FPS", 1/dtime
			
			dtime = 0.1 if dtime > 0.1

			dtime *= 0.1 if SFML::Keyboard.key_pressed? SFML::Keyboard::Space
			
			@app.each_event do |event|
				if event.type == SFML::Event::Closed
					@app.close
				end
				if event.type == SFML::Event::KeyPressed and event.key.code == SFML::Keyboard::F
					@level.load_from_file("test.txt")
				end
			end

			update dtime

			@app.clear [0, 10, 20]

			draw

			@app.display
		end
		
	end
end

steel = Game.new
steel.game_loop unless defined?(Ocra)
