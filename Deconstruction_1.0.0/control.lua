script.on_event(defines.events.on_player_mined_entity,
	function(event)
		game.print(event.entity.type)
	end
)

script.on_event(defines.events.on_resource_depleted,
	function(event)
		if event.entity.prototype.resource_category == 'basic-solid' then
			local drills = game.surfaces[event.entity.surface.index].find_entities_filtered{type = 'mining-drill', radius = 3, position = event.entity.position}
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
	end
)

script.on_event(defines.events.on_tick,
	function()
		if global.drillCheck then
			global.drillCount = (global.drillCount + 1) % 5
			if global.drillCount == 0 then
				local drills = table.remove(global.drillsList, 1);
				for _,drill in pairs(drills) do
					checkDrill(drill)
				end
				if #(global.drillsList) == 0 then
					global.drillCheck = false
				end
			end
		elseif global.chestCheck then
			global.chestCount = (global.chestCount + 1) % 60
			if global.chestCount == 0 then
				local obj = table.remove(global.chestList, 1)
				if obj.entity.get_inventory(defines.inventory.chest).is_empty() then
					removeChest(obj.entity)
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
	end
)

function checkDrill(drill)
	if drill.valid then
		if drill.status == defines.entity_status.no_minable_resources then
			local entity = nil
			if drill.drop_target ~= nil then
				entity = drill.drop_target
				if entity.type == 'container' then
					checkChest(entity, drill.position)
				-- elseif entity.type == 'transport-belt' then

				-- elseif entity.type == 'underground-belt' then

				-- elseif entity.type == 'splitter' then

				end
			end
			if drill.order_deconstruction(drill.force, drill.last_user) then
				game.print('Marked Drill for Deconstruction')
			else
				game.print('Failed to Mark Drill for Deconstruction')
			end
		end
	end
end

function checkChest(chest, position)
	local drills = game.surfaces[chest.surface.index].find_entities_filtered{type = 'mining-drill', radius = 3, position = chest.position}
	for _, drill in pairs(drills) do
		if drill.valid then
			if drill.position ~= position then
				if drill.drop_target.position == chest.position then
					return
				end
			end
		end
	end
	if settings.global['Remove Chests'].value == 'If Empty' then
		if chest.get_inventory(defines.inventory.chest).is_empty() then
			removeChest(chest)
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
	elseif settings.global['Remove Chests'].value == 'Yes' then
		removeChest(chest)
	end
end

function removeChest(chest)
	if chest.order_deconstruction(chest.force, chest.last_user) then
		game.print('Marked Chest for Deconstruction')
	else
		game.print('Dailed to Mark Chest for Deconstruction')
	end
end