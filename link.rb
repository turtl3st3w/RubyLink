Plugin.is {
    name "Link"
    version "0.2"
    author "d4l3k"
    description "Advanced sign based mechanisms in Minecraft."
    commands :link => {
        :description => "Controls Link.",
        :usage => "/<command> edit/off",
    }
}

import 'java.util.logging.Logger'
import 'java.util.logging.Level'
import 'org.bukkit.event.Event'
import 'org.bukkit.event.player.PlayerInteractEvent'
import 'org.bukkit.event.block.SignChangeEvent'
import 'org.bukkit.block.Block'
import 'org.bukkit.entity.Player'
import 'org.bukkit.ChatColor'
import 'org.bukkit.Material'
import 'org.bukkit.event.block.Action'
import 'org.bukkit.craftbukkit.block.CraftSign'
import 'org.bukkit.event.block.SignChangeEvent'
import 'org.bukkit.Location'
import 'org.bukkit.util.Vector'

require 'yaml'

def add_type name, type
	$link.gate_ref.store name.downcase, type
end
def add_desc type, desc
	$link.gate_desc.store type, desc
end

class Link < RubyPlugin
	attr_accessor :gate_ref, :gate_desc
	#### I/O to Console ####
	# TODO: Set logger prefix & use @log.info, @log.debug, etc.
	def info msg # Standard output to console.
		# Uses bash escape codes for pretty colors.
		@logger.info "\e[36m[\e[32mLink\e[36m] #{msg}\e[0m"
	end
	def debug msg # Debug output to console.
		# Uses bash escape codes for pretty colors.
		@logger.info "\e[33m[\e[32mLink\e[33m] #{msg}\e[0m"
	end
	def err msg # Used for error messages.
		# Uses bash escape codes for pretty colors.
		@logger.log Level::WARNING, "\e[31m[\e[32mLink\e[31m] #{msg}\e[0m"
	end
	def load_gates
		gate_file = File.join(File.dirname(__FILE__),"./link/gates.yml")
		if File.exists?(gate_file)
			File.open(gate_file, "r") do |object|
				if object!=""
					$gates = YAML::load(object)
				end
			end
			if $gates==nil
				$gates = []
			end
			destroyed_types = []
			$gates.each do |gate|
				mat = gate.block.get_block.getType
				if !(mat==Material::WALL_SIGN||mat==Material::SIGN_POST||mat==Material::SIGN)
					destroyed_types.push gate.name
					gate.destroy	
				end
			end
			if destroyed_types!=[]
				debug "Relic Gates: #{destroyed_types.to_s}"
			end
			info "Loaded #{$gates.length} gates."
		else
			info "No gate file found."
		end
		$gates.each do |gate|
			gate.resume
		end
	end
	def save_gates
		gate_file = File.join(File.dirname(__FILE__),"./link/gates.yml")
		File.open(gate_file, "w") do |file|
			file.print YAML::dump($gates)
		end
		debug "Saved #{$gates.length} gates."
	end
	def generate_docs(player)
		debug "Generating Documents"
		gates = []
		world = player.getWorld()
		debug "World: #{world.getName}"
		block = world.getBlockAt(0,0,2)
		type = block.getType
		block.setType(Material::SIGN_POST)
		debug "Player: #{player.getName}"
		event = SignChangeEvent.new(block, player, ["","","",""])
		@gate_ref.values.uniq.each do |gatec|
			debug "Proccessing: #{gatec.to_s}"
			gate = gatec.new
			gate.init event
			info = "# "+gate.name+"  \n"
			desc = @gate_desc[gatec]
			if desc!=nil
				info+="__Description:__ #{desc}  \n"
			end
			info+= "__ID (Title on sign):__ `#{gate.id}`  \n"
			alia = []
			@gate_ref.each do |k, v|
				if v == gatec
					alia.push k
				end
			end
			info+= "__Creation Aliases:__ `#{alia.sort.join("`, `")}`  \n"
			input = gate.inputs.length>1?"\n":""
			gate.inputs.each do |k,v|
				defa = v.to_s
				if defa==""
					defa="<empty string>"
				end
				input += ((gate.inputs.length>1) ? " \n* " : "") + "`#{k}`, Type: `#{v.class.to_s}`, Default: `#{defa}`  "
			end
			if input!=""
				info+= "__#{gate.inputs.length>1?"Inputs":"Input"}:__ "+input+"#{gate.inputs.length>1?"\n":""}\n"
			end
			output = gate.outputs.length>1?"\n":""
			gate.outputs.each do |k,v|
				defa = v[0].to_s
				if defa==""
					defa="<empty string>"
				end
				output += ((gate.outputs.length>1)? " \n* ":"")+"`#{k}`, Type: `#{v[0].class.to_s}`, Default: `#{defa}`  "
			end
			if output!=""
				info+= "__#{gate.outputs.length>1?"Outputs":"Output"}:__ "+output+"#{gate.outputs.length>1?"\n":""}\n"
			end
			info+= "__Permissions:__ `#{"link."+gate.perms}`, `#{"link.gate."+gate.id.delete("[]").downcase}`  \n"
			debug info
			gates.push info
		end
		block.setType(type)
		final = "Case does not matter for gate creation.  \n"
		final += gates.sort.join
		gate_file = File.join(File.dirname(__FILE__),"./link_documentation.markdown")
		File.open(gate_file, "w") do |file|
			file.print final
		end
		debug "Documentation wrote: #{gates.length} gates."
	end
	def get_gate block
		b = nil
		$gates.each do |gate|
			if gate.block.get_block==block
				return gate
			end
		end
		return nil
	end
	def load_types
		req = lambda do |file|
			debug "Load: "+file
			load file
		end
		i = 0
		5.times {Dir.glob(File.absolute_path(File.join(File.dirname(__FILE__),"link/gates/*#{'/*'*i}.rb"))){|file| req.call(file)};i+=1}
		debug "Loaded: #{@gate_ref.length} gate references. #{@gate_ref.to_s}"
		debug "Loaded: #{@gate_ref.values.uniq.length} unique gates types. #{@gate_ref.values.uniq.to_s}"
	end
	def onEnable
		$link = self
		@logger = Logger.getLogger("Minecraft")
		@gate_ref = {}
		@gate_desc = {}
		@player_status = {}
		$gates=[]
		load_types
		load_gates
		registerEvent(Event::Type::SIGN_CHANGE, Event::Priority::Normal) do |event|
			type = event.getLine(0).strip.downcase
			gate_class = @gate_ref[type]
			if gate_class!=nil
				gate = gate_class.new
				blah = gate.init event
				if !(blah==false)
					$gates.push gate
					save_gates
				end
			end
		end
		registerEvent(Event::Type::BLOCK_BREAK, Event::Priority::Monitor) do |event|
			if event.isCancelled
				return
			end
			block = event.getBlock
			mat = block.getType
			if (mat==Material::WALL_SIGN||mat==Material::SIGN_POST)
				gate = get_gate block
				if gate!=nil
					event.getPlayer.sendMessage("[LINK] "+ChatColor::RED.toString+"Gate Destroyed! "+gate.name)
					gate.destroy
					save_gates
				end
			end
		end
		registerEvent(Event::Type::REDSTONE_CHANGE, Event::Priority::Monitor) do |event|
			block = event.getBlock
			mat = block.getType
			if (mat==Material::WALL_SIGN||mat==Material::SIGN_POST)
				gate = get_gate block
				if gate!=nil
					gate.redstone_change event, event.getOldCurrent.to_f, event.getNewCurrent.to_f
				end
			end

		end
		registerEvent(Event::Type::PLAYER_INTERACT, Event::Priority::Monitor) do |event|
   			player = event.getPlayer
			if !(event.getAction==Action::RIGHT_CLICK_BLOCK || event.getAction==Action::LEFT_CLICK_BLOCK)
				return
			end
			block = event.getClickedBlock()
			if !(block.getType==Material::WALL_SIGN || block.getType==Material::SIGN_POST)
				return
			end
			gate = get_gate block
			if gate==nil
				return
			end
			if @player_status[player]==nil
				@player_status.store player, [false, 0]
			end
			if @player_status[player][0]	
				event.setCancelled true
				mode = @player_status[player][1]
				if mode == 0
					if gate.inputs=={}
						player.sendMessage("[Link] "+ChatColor::RED.toString+"Gate has no Input Values. Canceling...")
						return
					end
					@player_status[player][2] = gate
					@player_status[player][3] = 0
					clr = ChatColor::RED
					if(gate.inputs.values[0])
						clr = ChatColor::GREEN
					end
					gate.set_line(2, clr.toString+gate.inputs.keys[0])
					gate.set_line(3, clr.toString+gate.inputs.values[0].class.to_s)
					@player_status[player][1]=1
				elsif mode == 1
					if event.getAction==Action::RIGHT_CLICK_BLOCK
						sgate = @player_status[player][2]
						index = @player_status[player][3]+1
						if !sgate.inputs.values[index]
							index = 0
						end
						@player_status[player][3] = index
						clr = ChatColor::RED
						if(sgate.inputs.values[index])
							clr = ChatColor::GREEN
						end
						sgate.set_line(2, clr.toString+sgate.inputs.keys[index])
						sgate.set_line(3, clr.toString+sgate.inputs.values[index].class.to_s)
					elsif event.getAction==Action::LEFT_CLICK_BLOCK
						player.sendMessage("[LINK] "+ChatColor::GOLD.toString+"First Gate Selected! Select second now!")
						sgate = @player_status[player][2]
						sgate.set_line(2, "")
						sgate.set_line(3, "")
						sgate.update_display
						@player_status[player][1]=2
					end
				elsif mode == 2
					if gate.outputs=={}
						player.sendMessage("[LINK] "+ChatColor::RED.toString+"Gate has no Output Values. Canceling...")
						@player_status[player]=[true,0]
						return
					end
					index = 0
					@player_status[player][4]=gate
					@player_status[player][5]=index
					gate.set_line(2, gate.outputs.keys[index])
					gate.set_line(3, gate.outputs.values[index][0].class.to_s)
					@player_status[player][1]=3
				elsif mode == 3
					if event.getAction==Action::RIGHT_CLICK_BLOCK
						#TODO: Stop wrong data types from linking.
						sgate = @player_status[player][4]
						index = @player_status[player][5]+1
						if !sgate.outputs.values[index]
							index = 0
						end
						@player_status[player][5] = index
						sgate.set_line(2, gate.outputs.keys[index])
						sgate.set_line(3, gate.outputs.values[index][0].class.to_s)
					elsif event.getAction==Action::LEFT_CLICK_BLOCK
						player.sendMessage("[LINK] "+ChatColor::GREEN.toString+"Gates Linked!")
						gate1 = @player_status[player][2]
						index1 = @player_status[player][3]
						gate2 = @player_status[player][4]
						index2 = @player_status[player][5]
						key1 = gate1.inputs.keys[index1]
						key2 = gate2.outputs.keys[index2]
						#Unlink gates
						$gates.each do |a|
							a.outputs.each do |name, value|
								gates = value[1]
								gates.each do |gate_dat|
									b = gate_dat[0]
									if b!=nil
										if b==gate1&&gate_dat[1]==key1
											gates.delete(gate_dat)
										end
									end
								end
							end
						end
						old_val = gate1.inputs[key1]
						new_val = gate2.outputs.values[index2][0]
						gate1.inputs[key1]=new_val
						output_data = [gate1,key1]
						if !gate2.outputs[key2].include?(output_data)
							gate2.outputs[key2][1].push output_data
						end
						gate1.try_update key1, old_val, new_val 
						gate2.set_line(2, "")
						gate2.set_line(3, "")
						gate2.update_display
						@player_status[player]=[true,0]
						save_gates
					end

				end
			else
				gate.clicked event
			end
		end

		info "Enabled."
	end
	def onDisable
		$gates.each do |gate|
			gate.pause
		end
		save_gates
		info "Disabled."
	end
	def onCommand sender, cmd, label, args
		player = sender.getPlayer
		if args.length>0&&player.hasPermission("link.dev.generate")
			if args[0] == "generate"
				generate_docs(player)
				return true
			end
		elsif player.hasPermission("link.edit")
			if @player_status[player]==nil
				@player_status.store player, [false, 0]
			end
			@player_status[player][0]=!@player_status[player][0]
			if @player_status[player][0]
				player.sendMessage("[LINK] "+ChatColor::GREEN.toString+"Edit mode enabled.")
			else
				@player_status.store player, [false, 0]
				player.sendMessage("[LINK] "+ChatColor::RED.toString+"Edit mode disabled.")
			end
			return true
		end
	end
end


