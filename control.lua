script.on_event(defines.events.on_resource_depleted, function(event)
	if event.entity.prototype.resource_category == 'basic-solid' then
		local drills = game.surfaces[event.entity.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = 3,
			position = event.entity.position,
			to_be_deconstructed = false
		}
		if global.drillsList == nil then
			global.drillsList = {}
		end
		table.insert(global.drillsList, drills)
		if global.drillCount == nil then
			global.drillCount = 0
		end
		if global.drillCheck ~= true then
			global.drillCheck = true
		end
	end
end)

script.on_event(defines.events.on_tick, function()
	if global.drillCheck then
		global.drillCount = (global.drillCount + 1) % 5
		if global.drillCount == 0 then
			local drills = table.remove(global.drillsList, 1);
			for _, drill in pairs(drills) do
				CheckDrill(drill)
			end
			if #(global.drillsList) == 0 then
				global.drillCheck = false
			end
		end
	end
	if global.chestCheck then
		global.chestCount = (global.chestCount + 1) % 60
		if global.chestCount == 0 then
			local obj = table.remove(global.chestList, 1)
			if obj.entity.get_inventory(defines.inventory.chest).is_empty() then
				RemoveChest(obj.entity)
			else
				obj.checks = obj.checks + 1
				if obj.checks < 60 then
					table.insert(global.chestList, obj)
				end
			end
			if #(global.chestList) == 0 then
				global.chestCheck = false
			end
		end
	end
	if global.transportCheck then
		global.transportCount = (global.transportCount + 1) % 10
		if global.transportCount == 0 then
			local obj = table.remove(global.transportList, 1)
			if not CheckEntity(obj.entity) then
				obj.checks = obj.checks + 1
				if obj.checks < 360 then
					table.insert(global.transportList, obj)
				end
			end
			if #(global.transportList) == 0 then
				global.transportCheck = false
			end
		end
	end
end)

function CheckDrill(drill)
	if drill.valid then
		if drill.status == defines.entity_status.no_minable_resources then
			local entity = nil
			if drill.drop_target ~= nil then
				entity = drill.drop_target
			end
			if drill.order_deconstruction(drill.force, drill.last_user) then
				log('Marked Drill for Deconstruction')
			else
				log('Failed to Mark Drill for Deconstruction')
			end
			if entity ~= nil then
				if entity.type == 'container' then
					CheckChest(entity)
				elseif not CheckEntity(entity) then
					if global.transportList == nil then
						global.transportList = {}
					end
					table.insert(global.transportList, {entity = entity, checks = 0})
					if global.transportCount == nil then
						global.transportCount = 0
					end
					if global.transportCheck ~= true then
						global.transportCheck = true
					end
				end
			end
		end
	end
end

function CheckChest(chest)
	if settings.global['Remove Chests'].value ~= 'No' then
		local drills = game.surfaces[chest.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = 3,
			position = chest.position,
			to_be_deconstructed = false
		}
		for _, drill in pairs(drills) do
			if drill.valid then
				if drill.drop_target ~= nil then
					if PosEquals(drill.drop_target.position, chest.position) then
						return
					end
				end
			end
		end
		if settings.global['Remove Chests'].value == 'If Empty' then
			if chest.get_inventory(defines.inventory.chest).is_empty() then
				RemoveChest(chest)
			else
				if global.chestList == nil then
					global.chestList = {}
				end
				table.insert(global.chestList, {entity = chest, checks = 0})
				if global.chestCount == nil then
					global.chestCount = 0
				end
				if global.chestCheck ~= true then
					global.chestCheck = true
				end
			end
		else
			RemoveChest(chest)
		end
	end
end

function RemoveChest(chest)
	if chest.order_deconstruction(chest.force, chest.last_user) then
		log('Marked Chest for Deconstruction')
	else
		log('Dailed to Mark Chest for Deconstruction')
	end
end

function CheckEntity(entity)
	if settings.global['Remove Belts'].value then
		local drills = game.surfaces[entity.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = 3,
			position = entity.position,
			to_be_deconstructed = false
		}
		for _, drill in pairs(drills) do
			if drill.valid then
				if drill.drop_target ~= nil then
					if PosEquals(drill.drop_target.position, entity.position) then
						return true
					end
				end
			end
		end
		if entity.type == 'transport-belt' then
			return CheckBelt(entity)
		end
		if entity.type == 'underground-belt' then
			return CheckTunnel(entity)
		end
		if entity.type == 'splitter' then
			return CheckSplitter(entity)
		end
	end
	return true
end

function CheckBelt(belt)
	if belt.valid then
		if #(belt.belt_neighbours.inputs) == 0 then
			local max = belt.get_max_transport_line_index()
			local beltIsEmpty = true
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
			if beltIsEmpty then
				local outputs = belt.belt_neighbours.outputs
				if belt.order_deconstruction(belt.force, belt.last_user) then
					log('Marked Belt for Deconstruction')
					if #(outputs) > 0 then
						if global.transportList == nil then
							global.transportList = {}
						end
						for _, output in pairs(outputs) do
							table.insert(global.transportList, {entity = output, checks = 0})
						end
						if global.transportCount == nil then
							global.transportCount = 0
						end
						if global.transportCheck ~= true then
							global.transportCheck = true
						end
					end
				else
					log('Failed to Mark Belt for Deconstruction')
				end
			else
				return false
			end
		end
	end
	return true
end

function CheckTunnel(tunnel)
	if tunnel.valid then
		if #(tunnel.belt_neighbours.inputs) == 0 then
			if tunnel.belt_to_ground_type == 'output' and tunnel.neighbours == nil or tunnel.belt_to_ground_type == 'input' then
				local max = tunnel.get_max_transport_line_index()
				local tunnelIsEmpty = true
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
				if tunnelIsEmpty then
					local outputs = {}
					if tunnel.belt_to_ground_type == 'output' then
						outputs = tunnel.belt_neighbours.outputs
					else
						table.insert(outputs, tunnel.neighbours)
					end
					if tunnel.order_deconstruction(tunnel.force, tunnel.last_user) then
						log('Marked Tunnel for Deconstruction')
						if #(outputs) > 0 then
							if global.transportList == nil then
								global.transportList = {}
							end
							for _, output in pairs(outputs) do
								table.insert(global.transportList, {entity = output, checks = 0})
							end
							if global.transportCount == nil then
								global.transportCount = 0
							end
							if global.transportCheck ~= true then
								global.transportCheck = true
							end
						end
					else
						log('Failed to Mark Tunnel for Deconstruction')
					end
				else
					return false
				end
			end
		end
	end
	return true
end

function CheckSplitter(splitter)
	if splitter.valid then
		if #(splitter.belt_neighbours.inputs) == 0 then
			local max = splitter.get_max_transport_line_index()
			local splitterIsEmpty = true
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
			if splitterIsEmpty then
				local outputs = splitter.belt_neighbours.outputs
				if splitter.order_deconstruction(splitter.force, splitter.last_user) then
					log('Marked Splitter for Deconstruction')
					if #(outputs) > 0 then
						if global.transportList == nil then
							global.transportList = {}
						end
						for _, output in pairs(outputs) do
							table.insert(global.transportList, {entity = output, checks = 0})
						end
						if global.transportCount == nil then
							global.transportCount = 0
						end
						if global.transportCheck ~= true then
							global.transportCheck = true
						end
					end
				else
					log('Failed to Mark Splitter for Deconstruction')
				end
			else
				return false
			end
		end
	end
	return true
end

function PosEquals(posOne, posTwo)
	if (posOne.x == posTwo.x and posOne.y == posTwo.y) then
		return true
	end
	return false
end