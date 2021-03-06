class FloatSubtract < Gate
	def setup event
		@name = "Float: Subtract"
		@id = "[F.Subtract]"
		add_output "Out", 0.0
		add_input "A", 0.0
		add_input "B", 0.0
		add_input "C", 0.0
		add_input "D", 0.0
		add_input "E", 0.0
		add_input "F", 0.0
		add_input "G", 0.0
		add_input "H", 0.0
	end
	def update input, old_val, new_val
		data =  get_input "A"
		data -= get_input "B"
		data -= get_input "C"
		data -= get_input "D"
		data -= get_input "E"
		data -= get_input "F"
		data -= get_input "G"
		data -= get_input "H"
		set_output "Out", data
	end
	def update_display
		
	end
end

add_desc FloatSubtract, "Returns the sum of `A` minus `B-H`."
add_type "[F.Subtract]", FloatSubtract
