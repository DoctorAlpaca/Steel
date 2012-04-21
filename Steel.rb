require "pry" # TODO remove!

require "sfml/graphics"
require_relative "ResourceManager"
require_relative "Level"
require_relative "Player"
require_relative "Debug"
require_relative "Star"
require_relative "util"

$resource = ResourceManager.new
$tex_size = 32
$speed = 7
$grav = 50
$bug = Debug.new

class Game
	def initialize
		@app = SFML::RenderWindow.new([640, 640], "Steel")
		#@app.vertical_sync_enabled = true
		@cam = SFML::View.new([0, -10], [20, 10])
		@app.view = @cam
		@timer = SFML::Clock.new
		@level = Level.new
		@level.load_from_file("test.txt")
		@player = Player.new [1, 1]
		@stars = Array.new(30) { Star.new(-5.0..5.0, -5.0..5.0) }
		# TODO enable title
		@title = false
		@title_fade = 2.0

		@view_angle
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
		# Axis
		shape = SFML::RectangleShape.new
		shape.size = [40, 0]
		shape.position = [-20, 0]
		shape.outline_thickness = 0.05
		shape.outline_color = [255, 0, 0]
		#@app.draw shape
		shape.size = [0, 40]
		shape.position = [0, -20]
		#@app.draw shape

		# Draw stars
		@stars.each do |star|
			@app.draw star.sprite
		end
		# Draw level
		@level.each_block do |x, y, block|
			m = block[:morph]
			x = x.to_f
			if block[:old_type] == :air
				y /= (1.0-m)
			end
			if block[:type] == :ground
				if block[:old_type] == :bg
					draw_transformed(x, y, $resource["BlockLow.png"], [(100 * m + 255 * (1-m)).to_i]*3)
				else
					draw_transformed(x, y, $resource["BlockLow.png"])
				end
			elsif block[:type] == :bg
				if block[:old_type] == :ground
					draw_transformed(x, y, $resource["BlockLow.png"], [(255 * m + 100 * (1-m)).to_i]*3)
				else
					draw_transformed(x, y, $resource["BlockLow.png"], [100, 100, 100])
				end
			end
		end
		# Draw player
		draw_transformed(@player.pos[0], @player.pos[1], $resource["Player.png"])

		# Draw debug text
		txt = $bug.text
		@app.view = SFML::View.new([320, 320], [640, 640])
		txt.scale = [0.5, 0.5]
		@app.draw txt
		@app.view = @cam

		# Guess.
		draw_title unless @title_fade < 0
	end

	# Draws a single graphic, applying transformations.
	def draw_transformed (x, y, graphic, color = [255, 255, 255, 255])

=begin
		y += 2
	
		angle = -(x+0.5) / 20.0 * 360
		sprite = SFML::Sprite.new graphic
		sprite.color = color
		sprite.scale = [1.0/$tex_size]*2
		sprite.origin = [$tex_size/2]*2
		sprite.position = [Math.cos(angle.radians) * y, -Math.sin(angle.radians) * y]
		sprite.rotation = -angle + 90
		@app.draw sprite
=end

		y += 10
		
		vertices = Array.new(4) { SFML::Vertex.new }
		
		vertices[0].position = [x, y]
		vertices[1].position = [x+1, y]
		vertices[2].position = [x+1, y+1]
		vertices[3].position = [x, y+1]

		vertices.each do |v|
			angle = -v.position[0] / 20.0 * (2 * Math::PI) + @view_angle
			v.position[1] = 0 if v.position[1] < 0
			v.position = [Math.cos(angle) * v.position[1], v.position[1] * -Math.sin(angle)]
		end

		vertices[0].tex_coords = [0, $tex_size]
		vertices[1].tex_coords = [$tex_size, $tex_size]
		vertices[2].tex_coords = [$tex_size, 0]
		vertices[3].tex_coords = [0, 0]

		vertices.each { |x| x.color = color }

		state = SFML::RenderStates.new
		state.texture = graphic 
		@app.draw vertices, SFML::Quads, state
	end

	def update (dtime)
		if @title
			@title = false if SFML::Keyboard.key_pressed? SFML::Keyboard::Return
		else
			@title_fade -= dtime
			@title_fade = -1 if @title_fade < -1
			# Update player
			@player.speed[0] = 0
			@player.speed[0] = $speed if SFML::Keyboard.key_pressed? SFML::Keyboard::Right
			@player.speed[0] = -$speed if SFML::Keyboard.key_pressed? SFML::Keyboard::Left
			@player.jump if SFML::Keyboard.key_pressed? SFML::Keyboard::Up
			@player.update dtime, @level
		end
		# Update stars
		@stars.each_index do |i|
			@stars[i].update dtime
			@stars[i] = Star.new if @stars[i].position[0] < -5.5
		end
		# Update blocks
		@level.update dtime
		# Update camera
		@view_angle = (@player.pos[0]+0.5) / 20.0 * (2 * Math::PI) + (Math::PI/2)
		@cam.center = [0, -@player.pos[1] - 10]
		# Debug display
		$bug.show "Touching ground", @player.ground
		$bug.show "Pos", @player.pos
		$bug.show "Speed", @player.speed
	end

	def game_loop
		@timer.restart
		
		while @app.open?
			dtime = @timer.restart.asSeconds

			$bug.show "FPS", 1/dtime

			dtime = 0.1 if dtime > 0.1
		
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
