require "sfml/graphics"
require_relative "ResourceManager"
require_relative "Level"

$resource = ResourceManager.new
$tex_size = 128
$tex_size.freeze

class Game
	def initialize
		@app = SFML::RenderWindow.new([800, 800], "Steel")
		@cam = SFML::View.new([0, 0], [40, 40])
		@timer = SFML::Clock.new
		@level = Level.new
		@level.load_from_file("test.txt")
	end

	def draw
		@level.each_block do |x, y, block|
			if block == :ground
				puts "Drawing block at " + x.to_s + ", " + y.to_s
				draw_block(x, y, $resource["Block.png"])
			end
		end
	end

	# Draws a single block with the given graphic, applying transformations.
	def draw_block (x, y, graphic)
		vertex = Array.new(4) { SFML::Vertex.new }
		
		vertex[0].position = [x, y]
		vertex[1].position = [x+1, y]
		vertex[2].position = [x+1, y+1]
		vertex[3].position = [x, y+1]

		vertex[0].tex_coords = [0, 0]
		vertex[1].tex_coords = [$tex_size, 0]
		vertex[2].tex_coords = [$tex_size, $tex_size]
		vertex[3].tex_coords = [0, $tex_size]

		vertex.each { |x| x.color = [255, 255, 255] }

		#debugger
		#state = SFML::RenderStates.new
		#state.texture = graphic
		@app.draw vertex, 4, SFML::LinesStrip #, state
	end

	def game_loop
		@timer.restart
		
		while @app.open?
			dtime = @timer.restart.asSeconds
		
			@app.each_event do |event|
				if event.type == SFML::Event::Closed
					@app.close
				end
			end

			@app.clear

			draw

			@app.display
		end
		
	end
end

steel = Game.new
steel.game_loop
