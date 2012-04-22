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
$bug = :bug_was_removed

class Game
	def initialize
		@app = SFML::RenderWindow.new([640, 640], "Steel")
		@app.vertical_sync_enabled = true
		@cam = SFML::View.new([0, -10], [10, 10])
		@app.view = @cam
		@timer = SFML::Clock.new
		@level_nr = 10
		@level = Level.new
		@level.load_from_file(@level_nr.to_s + ".lvl")
		@player = Player.new
		@checkpoint = [@player.pos[0], @player.pos[1]]
		@stars = Array.new(30) { Star.new(-5.0..5.0, -5.0..5.0) }
		@title = true
		@title_fade = 2.0

		@rocket_launched = false
		@rocket_timer = 0.0
		@last_noise = 0.0
		@vic_played
	end

	def draw_title
		kitten = SFML::Sprite.new $resource["kitten.png"]
		kitten.position = [640 - 58, 640 - 26 - 125]
		
		rbSFML = SFML::Sprite.new $resource["rbSFML.png"]
		rbSFML.position = [640 - 200, 640 - 150]

		logo = SFML::Sprite.new $resource["Logo.png"]
		logo.position = [(640-54*8)/2, 100]
		logo.scale = [8, 8]

		instr = SFML::Sprite.new $resource["Instruction.png"]
		instr.position = [(640-54*2)/2, 380]
		instr.scale = [2, 2]

		instr.color = logo.color = rbSFML.color = kitten.color = [255, 255, 255, (@title_fade / 2.0 * 255).to_i]
		
		view = SFML::View.new
		view.viewport = [0, 0, 640, 640]
		@app.view = @app.default_view

		@app.draw kitten
		@app.draw rbSFML
		@app.draw logo
		@app.draw instr
		
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
		draw_object(@player.pos[0], @player.pos[1], :player) unless @rocket_launched

		# Guess.
		draw_title unless @title_fade < 0
	end

	# Draws a single Object.
	def draw_object (x, y, type, color = nil)

		y = -y - 1

		sprite = SFML::Sprite.new
		sprite.scale = [1.0/$tex_size]*2
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
			when :cat
				sprite.texture = $resource["Cat.png"]
			when :rocket
				sprite.texture = $resource["Rocket.png"] unless @rocket_launched
				sprite.scale = [1.0/$tex_size * 4]*2
				y -= 3
			when :rocket_launched
				sprite.texture = $resource["Rocket_Launched.png"]
				sprite.scale = [1.0/$tex_size * 4]*2
				y -= 2.25
		end
		if not color.nil?
			sprite.color = color
		end
		sprite.position = [x, y]
		@app.draw sprite
	end

	def update (dtime)
		if @title
			if SFML::Keyboard.key_pressed? SFML::Keyboard::Return
				@title = false 
				$resource.play_music("Music.wav")
			end
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
				if x.type == :rocket
					@rocket_launched = true
				else
					hit = true
				end
			end
		end
		restart if hit

		restart(false) if SFML::Keyboard.key_pressed? SFML::Keyboard::R
		
		# Update camera
		@cam.center = [@cam.center.x, -@cam.center.y]
		@cam.center += SFML::Vector2.new((@player.pos[0] + 0.5 - @cam.center.x) * dtime * 10, (@player.pos[1] - @cam.center.y) * dtime * 10)
		@cam.center = [@cam.center.x, -@cam.center.y]
		
		# Update resources
		$resource.update
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
			
			dtime = 0.1 if dtime > 0.1
			
			@app.each_event do |event|
				if event.type == SFML::Event::Closed
					@app.close
				end
			end

			update dtime unless @rocket_launched

			@app.clear [0, 10, 20]
			
			draw

			if @rocket_launched
				@rocket_timer += dtime
				x = 12
				y = 1
				if @rocket_timer < 0.5
					y -= @rocket_timer / 4
				else
					y += -(0.5/4) + (@rocket_timer - 0.5) * 5
				end

				if @rocket_timer < 4
					$resource.music.volume = (4 - @rocket_timer) / 4.0 * 100
				end

				@app.view = @app.default_view
				if @rocket_timer > 8
					$resource.play_music("Victory.wav") if not @vic_played
					$resource.music.volume = 100
					@vic_played = true
					spr = SFML::Sprite.new $resource["End.png"]
					spr.scale = [8, 8]
					spr.position = [50, 180]
					@app.draw spr
				end
				@app.view = @cam
				
				if @rocket_timer - @last_noise > 0.1
					@last_noise = @rocket_timer
					$resource.play_sound("Rocket.wav", 0.5**@rocket_timer)
				end
				@cam.center = [x + rand(-0.5..0.5) - 0.5, -y + rand(-0.5..0.5) - 1]
				draw_object x, y, :rocket_launched
			end

			@app.display
		end
		
	end
end

steel = Game.new
steel.game_loop unless defined?(Ocra)
