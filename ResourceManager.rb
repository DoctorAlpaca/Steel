require "sfml/graphics"
require "sfml/audio"

class ResourceManager
	attr_accessor :files, :sounds, :music

	def initialize()
		@files = Hash.new
		@sounds = Array.new
		@music = SFML::Music.new
		@music_loaded = false
	end

	def open(filename)
		return @files[filename] if @files.has_key? filename
		if filename =~ /\.png/
			@files[filename] = SFML::Texture.new
		elsif filename =~ /\.[(wav)(ogg)]/
			@files[filename] = SFML::SoundBuffer.new
		end
		@files[filename].loadFromFile("resource/" + filename)
		return @files[filename]
	end

	def [](file)
		return open(file)
	end

	def play_sound (filename, volume = 1)
		sound = SFML::Sound.new open(filename)
		@sounds.push(sound)
		sound.play
		sound.volume *= volume
		sound.pitch = rand(0.9..1.2)
	end

	def update
		@sounds.delete_if do |i|
			i.status == SFML::Sound::Stopped
		end
		@music.play if @music.status == SFML::Music::Stopped and @music_loaded
	end

	def play_music(filename)
		@music.stop
		@music.openFromFile "resource/" + filename
		@music.play
		@music_loaded = true
	end
end
