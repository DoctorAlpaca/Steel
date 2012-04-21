require "sfml/graphics"
require "sfml/audio"

class ResourceManager
	attr_accessor :files, :sounds

	def initialize()
		@files = Hash.new
		@sounds = Hash.new
		@music = SFML::Music.new
	end

	def open(filename)
		#debugger
		return @files[filename] if @files.has_key? filename
		puts "Loading file " + filename
		if filename =~ /\.png/
			@files[filename] = SFML::Texture.new
		elsif filename =~ /\.[(wav)(ogg)]/
			@files[filename] = SFML::SoundBuffer.new
		else
			puts "Can't do anything with file " + filename.to_s
		end
		@files[filename].loadFromFile(filename)
		return @files[filename]
	end

	def [](file)
		return open(file)
	end

	def play_music(filename)
		@music.stop
		@music.openFromFile filename
		@music.play
	end
end
