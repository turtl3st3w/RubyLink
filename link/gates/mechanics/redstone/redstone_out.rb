class RedstoneOut < Gate
	def setup event
		@name = "Redstone Power Output"
		@id = "[RedstoneOut]"
		add_input "Power", 0.0
		begin
			set_power false
		rescue Exception=>e
			return false
		end
	end
	def redstone_change event, old_val, new_val
	end
	def update input, old_val, new_val
		
		if new_val>=1.0
			set_power true
		else
			set_power false
		end

	end
	def set_power pow
		blk = @block.get_block.to_java(SpoutBlock)
		blk.setBlockPowered pow
		craft = blk.getWorld.to_java('org.bukkit.craftbukkit.CraftWorld').getHandle.to_java('net.minecraft.server.World')
		craft.applyPhysics(blk.getX, blk.getY, blk.getZ, blk.getTypeId)
	end
	def update_display
	end
end

add_desc RedstoneOut, "Outputs redstone power from an input. Powered if Power>=1.0. Requires Spout!"
add_type "[RedstoneOut]", RedstoneOut
add_type "[rout]", RedstoneOut
