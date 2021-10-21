-- StartUp --

local function StartUp()
	-- Startup Checks: Drills
	if global.drillsList == nil then
		global.drillsList = {}
	end
	if global.drillCount == nil then
		global.drillCount = 0
	end

	-- Startup Checks: Chests
	if global.chestList == nil then
		global.chestList = {}
	end
	if global.chestCount == nil then
		global.chestCount = 0
	end

	-- Startup Checks: Transport
	if global.transportList == nil then
		global.transportList = {}
	end
	if global.transportCount == nil then
		global.transportCount = 0
	end

	-- Startup Checks: Miner Radius
	local drillTypes = game.get_filtered_entity_prototypes{
		{
			filter = 'type',
			type = 'mining-drill'
		}
	}
	if global.radius == nil then
		global.radius = 0
	end
	for _, prototype in pairs(drillTypes) do
		local radius = prototype.mining_drill_radius
		if radius > global.radius then
			global.radius = radius
		end
	end
	global.radius = math.ceil(global.radius)
end

-- Functions --

-- Determines if two entity positions are the same.
local function PosEquals(posOne, posTwo)
	if (posOne.x == posTwo.x and posOne.y == posTwo.y) then
		return true
	end
	return false
end

-- Checks if belt is empty and if so, will mark it for deconstruction.
local function CheckBelt(belt)
	-- If belt is still valid in the game...
	if belt.valid then
		-- And it has no transport entities inputting into it...
		if #(belt.belt_neighbours.inputs) == 0 then
			local max = belt.get_max_transport_line_index()
			local beltIsEmpty = true
			-- Check if the belt is empty.
			for i = 1, max, 1 do
				local contents = belt.get_transport_line(i).get_contents()
				local lineIsEmpty = true
				for _, _ in pairs(contents) do
					lineIsEmpty = false
					break
				end
				if not lineIsEmpty then
					beltIsEmpty = false
					break
				end
			end
			-- If it is empty...
			if beltIsEmpty then
				-- Grab the transport entity it outputs to.
				local outputs = belt.belt_neighbours.outputs
				-- Mark the belt for deconstruction.
				if belt.order_deconstruction(belt.force, belt.last_user) then
					log('Marked Belt for Deconstruction')
					-- If successful, check if outputs is greater than 0...
					if #(outputs) > 0 then
						-- Iterate through each output entity and add them to the end of a queue.
						for _, output in pairs(outputs) do
							table.insert(global.transportList, {entity = output, checks = 0})
						end
						-- Set transportCheck to true if it isn't already.
						if global.transportCheck ~= true then
							global.transportCheck = true
						end
					end
				else
					log('Failed to Mark Belt for Deconstruction')
				end
			else
				-- Return false if the belt wasn't empty.
				return false
			end
		end
	end
	-- Returns true if the belt was empty, was no longer valid, or had transport entities inputting into it.
	return true
end

-- Checks if underground belt is empty and if so, will mark it for deconstruction.
local function CheckTunnel(tunnel)
	-- If tunnel is still valid in the game...
	if tunnel.valid then
		-- And it doesn't have transport entities inputting into it...
		if #(tunnel.belt_neighbours.inputs) == 0 then
			-- And it is an output tunnel with no input tunnel or is an input tunnel...
			if tunnel.belt_to_ground_type == 'output' and tunnel.neighbours == nil or tunnel.belt_to_ground_type == 'input' then
				local max = tunnel.get_max_transport_line_index()
				local tunnelIsEmpty = true
				-- Check if it is empty.
				for i = 1, max, 1 do
					local contents = tunnel.get_transport_line(i).get_contents()
					local lineIsEmpty = true
					for _, _ in pairs(contents) do
						lineIsEmpty = false
						break
					end
					if not lineIsEmpty then
						tunnelIsEmpty = false
						break
					end
				end
				-- If it is empty...
				if tunnelIsEmpty then
					local outputs = {}
					-- If tunnel is an output tunnel...
					if tunnel.belt_to_ground_type == 'output' then
						-- Grab tunnel's output transport entities.
						outputs = tunnel.belt_neighbours.outputs
					else
						-- Else append tunnel's output entity to the queue.
						table.insert(outputs, tunnel.neighbours)
					end
					-- Mark tunnel for deconstruction.
					if tunnel.order_deconstruction(tunnel.force, tunnel.last_user) then
						log('Marked Tunnel for Deconstruction')
						-- If successful, check if outputs is greater than 0...
						if #(outputs) > 0 then
							-- Iterate through each output entity and add them to the end of the queue.
							for _, output in pairs(outputs) do
								table.insert(global.transportList, {entity = output, checks = 0})
							end
							-- Set transportCheck to true if it isn't already.
							if global.transportCheck ~= true then
								global.transportCheck = true
							end
						end
					else
						log('Failed to Mark Tunnel for Deconstruction')
					end
				else
					-- Return false if the tunnel wasn't empty.
					return false
				end
			end
		end
	end
	-- Return true if the tunnel was empty, was no longer valid, had transport entities inputting into it, or was an output tunnel and had an input tunnel.
	return true
end

-- Checks if splitter is empty and if so, will mark it for deconstruction.
local function CheckSplitter(splitter)
	-- If splitter is still valid in the game...
	if splitter.valid then
		-- And it has no inputting transport entities...
		if #(splitter.belt_neighbours.inputs) == 0 then
			local max = splitter.get_max_transport_line_index()
			local splitterIsEmpty = true
			-- Check if splitter is empty.
			for i = 1, max, 1 do
				local contents = splitter.get_transport_line(i).get_contents()
				local lineIsEmpty = true
				for _, _ in pairs(contents) do
					lineIsEmpty = false
					break
				end
				if not lineIsEmpty then
					splitterIsEmpty = false
					break
				end
			end
			-- If it is empty...
			if splitterIsEmpty then
				-- Grab its output entities.
				local outputs = splitter.belt_neighbours.outputs
				-- Mark it for deconstruction.
				if splitter.order_deconstruction(splitter.force, splitter.last_user) then
					log('Marked Splitter for Deconstruction')
					-- If successfully, check if outputs is greater than 0...
					if #(outputs) > 0 then
						-- Iterate over each output transport entity and append them to the end of a queue.
						for _, output in pairs(outputs) do
							table.insert(global.transportList, {entity = output, checks = 0})
						end
						-- Set transportCheck to true if it isn't already.
						if global.transportCheck ~= true then
							global.transportCheck = true
						end
					end
				else
					log('Failed to Mark Splitter for Deconstruction')
				end
			else
				-- Return false if splitter isn't empty.
				return false
			end
		end
	end
	-- Returns true if splitter isn't empty, is no longer valid, or has transport entities inputting into it.
	return true
end

-- Check if transport entity has a drill inserting into it, and if not checks if it can be deconstructed.
local function CheckTransport(entity)
	-- If mod settings, Remove Belts, is set to true...
	if settings.global['Remove Belts'].value then
		-- And if transport entity is valid in the game...
		if entity.valid then
			-- Grab drills within radius of the transport entity's position that isn't marked for deconstruction.
			local drills = game.surfaces[entity.surface.index].find_entities_filtered {
				type = 'mining-drill',
				radius = global.radius,
				position = entity.position,
				to_be_deconstructed = false
			}
			-- Iterate over each one.
			for _, drill in pairs(drills) do
				-- If drill is valid in the game...
				if drill.valid then
					-- And if it has a drop target...
					if drill.drop_target ~= nil then
						-- And its drop target's position is equal to the entities position...
						if PosEquals(drill.drop_target.position, entity.position) then
							-- Return true as a drill is still outputting onto said transport entity.
							return true
						end
					end
				end
			end
			-- If entity is a belt...
			if entity.type == 'transport-belt' then
				return CheckBelt(entity)
			end
			-- If entity is an underground belt...
			if entity.type == 'underground-belt' then
				return CheckTunnel(entity)
			end
			-- If entity is a splitter...
			if entity.type == 'splitter' then
				return CheckSplitter(entity)
			end
		end
	end
	-- Return true if entity is no longer valid in the game, mod setting, Remove Belts, has been set to false, or the entity isn't of the transport nature.
	return true
end

-- Marks chest for deconstruction.
local function RemoveChest(chest)
	if chest.order_deconstruction(chest.force, chest.last_user) then
		log('Marked Chest for Deconstruction')
	else
		log('Dailed to Mark Chest for Deconstruction')
	end
end

-- Checks if a chest needs to be removed depending on mod settings.
local function CheckChest(chest)
	-- If mod settings isn't set to No on Remove Chests...
	if settings.global['Remove Chests'].value ~= 'No' then
		-- Get an array of all mining drills within radius of said chest's position that isn't marked for deconstruction.
		local drills = game.surfaces[chest.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = global.radius,
			position = chest.position,
			to_be_deconstructed = false
		}
		-- Iterate over each drill.
		for _, drill in pairs(drills) do
			-- If drill is still valid...
			if drill.valid then
				-- And it has an output entity...
				if drill.drop_target ~= nil then
					-- And that entity is this chest...
					if PosEquals(drill.drop_target.position, chest.position) then
						-- Stop check as the chest still has a drill depositing resources into it.
						return
					end
				end
			end
		end
		-- Else if chest has no more drills depositing into it...
		-- If mod settings is set it If Empty...
		if settings.global['Remove Chests'].value == 'If Empty' then
			-- If chest is empty then mark it for deconstruction it now.
			if chest.get_inventory(defines.inventory.chest).is_empty() then
				RemoveChest(chest)
			else
				-- Otherwise, append it to the end of a queue.
				table.insert(global.chestList, {entity = chest, checks = 0})
				-- Set chestCheck to true if it isn't already.
				if global.chestCheck ~= true then
					global.chestCheck = true
				end
			end
		else
			-- Marks chest for deconstruction as mod settings is set to Yes.
			RemoveChest(chest)
		end
	end
end

-- Checks if a drill needs to be removed and adds its output entity (if any) to the end of their respective queue. **Depending** on mod settings.
local function CheckDrill(drill)
	-- If drill is still valid in the game...
	if drill.valid then
		-- And, if drill has no resources left to mine...
		if drill.status == defines.entity_status.no_minable_resources then
			local entity = nil
			-- Check if it has a output entity.
			if drill.drop_target ~= nil then
				-- If so, grab it.
				entity = drill.drop_target
			end
			-- Mark drill for deconstruction.
			if drill.order_deconstruction(drill.force, drill.last_user) then
				log('Marked Drill for Deconstruction')
			else
				log('Failed to Mark Drill for Deconstruction')
			end
			-- If drill did have an output entity...
			if entity ~= nil then
				-- Check if it's a container entity, and if so check if it needs to be marked for deconstruction.
				if entity.type == 'container' then
					CheckChest(entity)
				-- Else check if it's a transport entity, and if so, but isn't ready to be marked for deconstruction yet...
				elseif not CheckTransport(entity) then
					-- Append transport entity to the end of a queue.
					table.insert(global.transportList, {entity = entity, checks = 0})
					-- Set transportCheck to true if it isn't already.
					if global.transportCheck ~= true then
						global.transportCheck = true
					end
				end
			end
		end
	end
end

-- Events --

-- Makes Sure needed global variables exist.
script.on_init(StartUp)
script.on_configuration_changed(StartUp)

-- Run when a resource is depleted.
script.on_event(defines.events.on_resource_depleted, function(event)
	-- If the resource was a basic-solid then...
	if event.entity.prototype.resource_category == 'basic-solid' then
		-- Get an array of all mining drills within radius on said depleted position that isn't marked to be deconstructed.
		local drills = game.surfaces[event.entity.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = global.radius,
			position = event.entity.position,
			to_be_deconstructed = false
		}
		-- Append that array to the end of a queue to be dealt with somewhere else.
		table.insert(global.drillsList, drills)
		-- Set drillCheck to true if it isn't already.
		if global.drillCheck ~= true then
			global.drillCheck = true
		end
	end
end)

-- Run every tick.
script.on_event(defines.events.on_tick, function()
	-- If drillCheck is true...
	if global.drillCheck then
		-- Increase drillCount by 1 and keep within the range of 0-4.
		global.drillCount = (global.drillCount + 1) % 5
		-- So on every 5th tick in game...
		if global.drillCount == 0 then
			-- Get the array of drills in the front of the queue.
			local drills = table.remove(global.drillsList, 1);
			-- Iterate over each one and run a check on each of them to see if they need to be marked for deconstruction, in which case they will be marked for deconstruction.
			for _, drill in pairs(drills) do
				CheckDrill(drill)
			end
			-- Check if the queue is empty, and if so make drillCheck false.
			if #(global.drillsList) == 0 then
				global.drillCheck = false
			end
		end
	end

	-- If chestCheck is true...
	if global.chestCheck then
		-- Increase chestCount by 1 and keep within the range of 0-59.
		global.chestCount = (global.chestCount + 1) % 60
		-- So on every 60th tick in game...
		if global.chestCount == 0 then
			-- Get the chest in front of the queue.
			local obj = table.remove(global.chestList, 1)
			-- Check if its contents is empty...
			if obj.entity.get_inventory(defines.inventory.chest).is_empty() then
				-- If so, mark it for deconstruction.
				RemoveChest(obj.entity)
			else
				-- If not, increase the number of times it has been checked by 1.
				obj.checks = obj.checks + 1
				-- If it has been checked less than 60 times...
				if obj.checks < 60 then
					-- Add it back to the end of the queue.
					table.insert(global.chestList, obj)
				end
			end
			-- Check if the queue is empty, and if so make chestCheck false.
			if #(global.chestList) == 0 then
				global.chestCheck = false
			end
		end
	end

	-- If transportCheck is true...
	if global.transportCheck then
		-- Increase transportCount by 1 and keep within the range of 0-9.
		global.transportCount = (global.transportCount + 1) % 10
		-- So on every 10th tick in game...
		if global.transportCount == 0 then
			-- Get the transport entity in front of the queue.
			local obj = table.remove(global.transportList, 1)
			-- Check if it can be removed, and if not...
			if not CheckTransport(obj.entity) then
				-- Increase the number of times it has been checked by 1.
				obj.checks = obj.checks + 1
				-- If it has been checked less than 360 times...
				if obj.checks < 360 then
					-- Add it back to the end of the queue.
					table.insert(global.transportList, obj)
				end
			end
			-- Check if the queue is empty, and if so make transportCheck false.
			if #(global.transportList) == 0 then
				global.transportCheck = false
			end
		end
	end
end)