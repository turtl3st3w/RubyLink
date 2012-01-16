class DivideFixnum < Gate
	def setup event
		@name = "Divide Fixnum"
		@id = "[Divide]"
		add_output "Product", 1.0
		add_input "Number1", 1.0
		add_input "Number2", 1.0
		add_input "Number3", 1.0
		add_input "Number4", 1.0
	end
	def update input, old_val, new_val
		data = get_input "Number1"
		data /= get_input "Number2"
		data /= get_input "Number3"
		data /= get_input "Number4"
		set_output "Product", data
		set_line 1, data.to_s
	end
	def update_display
		
	end
end

add_type "[/]", DivideFixnum
add_type "[Divide]", DivideFixnum