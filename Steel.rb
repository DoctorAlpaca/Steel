require "sfml/graphics"
require_relative "ResourceManager"
require_relative "Level"
require_relative "Player"
require_relative "Debug"

$resource = ResourceManager.new
$tex_size = 32
$tex_size.freeze
$accel = 400
$grav = 50
$breakx = 50
$breaky = 0
$bug = Debug.new

class Game
	def initialize
		@app = SFML::RenderWindow.new([640, 640], "Steel")
		@cam = SFML::View.new([0, 0], [10, 10])
		@app.view = @cam
		@timer = SFML::Clock.new
		@level = Level.new
		@level.load_from_file("test.txt")
		@player = Player.new [1, 1]
	end

	def draw
		# Axis
		shape = SFML::RectangleShape.new
		shape.size = [40, 0]
		shape.position = [-20, 0]
		shape.outline_thickness = 0.05
		shape.outline_color = [255, 0, 0]
		@app.draw shape
		shape.size = [0, 40]
		shape.position = [0, -20]
		@app.draw shape

		# Draw level
		@level.each_block do |x, y, block|
			if block == :ground
				draw_transformed(x, y, $resource["BlockLow.png"])
			end
		end
		# Draw Player
		draw_transformed(@player.pos[0], @player.pos[1], $resource["Player.png"])

		# Draw debug text
		txt = $bug.text
		txt.position = [-5, -5]
		txt.scale = [0.01, 0.01]
		@app.draw txt
	end

	# Draws a single graphic, applying transformations.
	def draw_transformed (x, y, graphic)
		y = -y - 1
		# Temp soluion
		sprite = SFML::Sprite.new graphic
		sprite.scale = [1.0/$tex_size, 1.0/$tex_size]
		sprite.position = [x, y]
		@app.draw sprite
=begin
		vertices = Array.new(4) { SFML::Vertex.new }
		
		vertices[0].position = [x, y]
		vertices[1].position = [x+1, y]
		vertices[2].position = [x+1, y+1]
		vertices[3].position = [x, y+1]

		vertices[0].tex_coords = [0, 0]
		vertices[1].tex_coords = [$tex_size, 0]
		vertices[2].tex_coords = [$tex_size, $tex_size]
		vertices[3].tex_coords = [0, $tex_size]

		state = SFML::RenderStates.new
		state.texture = graphic
		@app.draw vertices, 4, SFML::LinesStrip #, state
=end
	end

	def update (dtime)
		@player.speed[0] += $accel * dtime if SFML::Keyboard.key_pressed? SFML::Keyboard::Right
		@player.speed[0] -= $accel * dtime if SFML::Keyboard.key_pressed? SFML::Keyboard::Left
		@player.jump if SFML::Keyboard.key_pressed? SFML::Keyboard::Up
		@player.update dtime, @level
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
			end

			update dtime

			@app.clear [0, 10, 20]

			draw

			@app.display
		end
		
	end
end

steel = Game.new
steel.game_loop
