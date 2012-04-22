require "sfml/graphics"
require "sfml/audio"

class ResourceManager
	attr_accessor :files, :sounds

	def initialize()
		@files = Hash.new
		@sounds = Array.new
		@music = SFML::Music.new
	end

	def open(filename)
		return @files[filename] if @files.has_key? filename
		puts "Loading file " + filename
		if filename =~ /\.png/
			@files[filename] = SFML::Texture.new
		elsif filename =~ /\.[(wav)(ogg)]/
			@files[filename] = SFML::SoundBuffer.new
		else
			puts "Can't do anything with file " + filename.to_s
		end
		@files[filename].loadFromFile("resource/" + filename)
		return @files[filename]
	end

	def [](file)
		return open(file)
	end

	def play_sound (filename)
		sound = SFML::Sound.new open(filename)
		@sounds.push(sound)
		sound.play
		sound.pitch = rand(0.9..1.2)
	end

	def update
		@sounds.delete_if do |i|
			i.status == SFML::Sound::Stopped
		end
		puts @sounds.length
	end

	def play_music(filename)
		@music.stop
		@music.openFromFile filename
		@music.play
	end
end
