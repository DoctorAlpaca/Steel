require "sfml/graphics"

class Debug
	attr_accessor :list
	def initialize
		@list = Hash.new
	end
	
	def show (label, value)
		@list[label.to_s] = value.to_s
	end

	def text
		string = ""
		list.each_pair do |label, value|
			string += label + ": " + value + "\n"
		end
		txt = SFML::Text.new (string)
		txt.color = SFML::Color::White
		return txt
	end
end
