-- Functions --
local function calcRadius()
	local drillTypes = game.get_filtered_entity_prototypes {
		{
			filter = 'type',
			type = 'mining-drill'
		}
	}
	local radius = 0
	for _, prototype in pairs(drillTypes) do
		local r = prototype.mining_drill_radius
		if r > radius then
			radius = r
		end
	end
	global.radius = math.ceil(radius + 1)
end

local function miningDrill(drill, checks)
	if not drill.valid then
		return
	end

	if drill.status ~= defines.entity_status.no_minable_resources then
		if checks < 5 then
			table.insert(global.list, {
				entity = drill,
				checks = checks + 1
			})
		end
		return
	end

	if drill.drop_target ~= nil then
		table.insert(global.list, {
			entity = drill.drop_target,
			checks = 0
		})
	end

	local position = drill.position
	local name = drill.name
	if drill.order_deconstruction(drill.force, drill.last_user) then
		log('Marked '..name..' for Deconstruction | x: '..position.x..' | y: '..position.y)
	else
		log('Failed to Mark '..name..' for Deconstruction | x: '..position.x..' | y: '..position.y)
	end
end

local function transportBelt(belt, checks)
	if not belt.valid then
		return
	end

	if #(belt.belt_neighbours.inputs) > 0 then
		return
	end

	for _,drill in pairs(game.surfaces[belt.surface.index].find_entities_filtered {
		type = 'mining-drill',
		radius = global.radius,
		position = belt.position,
		to_be_deconstructed = false
	}) do
		if drill.valid and drill.drop_target ~= nil and drill.drop_target.position.x == belt.position.x and drill.drop_target.position.y == belt.position.y then
			return
		end
	end

	for i = 1, belt.get_max_transport_line_index(), 1 do
		local contents = belt.get_transport_line(i).get_contents()
		local key = next(contents)
		if key then
			if checks < 360 then
				table.insert(global.list, {
					entity = belt,
					checks = checks + 1
				})
			end
			return
		end
	end

	for _,output in pairs(belt.belt_neighbours.outputs) do
		table.insert(global.list, {
			entity = output,
			checks = 0
		})
	end

	local position = belt.position
	local name = belt.name
	if belt.order_deconstruction(belt.force, belt.last_user) then
		log('Marked ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	else
		log('Failed to Mark ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	end
end

local function undergroundBelt(tunnel, checks)
	if not tunnel.valid then
		return
	end

	if #(tunnel.belt_neighbours.inputs) > 0 then
		return
	end

	if tunnel.belt_to_ground_type == 'output' and tunnel.neighbours ~= nil then
		return
	end

	for _,drill in pairs(game.surfaces[tunnel.surface.index].find_entities_filtered {
		type = 'mining-drill',
		radius = global.radius,
		position = tunnel.position,
		to_be_deconstructed = false
	}) do
		if drill.valid and drill.drop_target ~= nil and drill.drop_target.position.x == tunnel.position.x and drill.drop_target.position.y == tunnel.position.y then
			return
		end
	end

	for i = 1, tunnel.get_max_transport_line_index(), 1 do
		local contents = tunnel.get_transport_line(i).get_contents()
		local key = next(contents)
		if key then
			if checks < 360 then
				table.insert(global.list, {
					entity = tunnel,
					checks = checks + 1
				})
			end
			return
		end
	end

	if tunnel.belt_to_ground_type == 'output' then
		for _,output in pairs(tunnel.belt_neighbours.outputs) do
			table.insert(global.list, {
				entity = output,
				checks = 0
			})
		end
	else
		table.insert(global.list, {
			entity = tunnel.neighbours,
			checks = 0
		})
	end

	local position = tunnel.position
	local name = tunnel.name
	if tunnel.order_deconstruction(tunnel.force, tunnel.last_user) then
		log('Marked ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	else
		log('Failed to Mark ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	end
end

local function splitter(splitter, checks)
	if not splitter.valid then
		return
	end

	if #(splitter.belt_neighbours.inputs) > 0 then
		return
	end

	for _, drill in pairs(game.surfaces[splitter.surface.index].find_entities_filtered {
		type = 'mining-drill',
		radius = global.radius,
		position = splitter.position,
		to_be_deconstructed = false
	}) do
		if drill.valid and drill.drop_target ~= nil and drill.drop_target.position.x == splitter.position.x and
			drill.drop_target.position.y == splitter.position.y then
			return
		end
	end

	for i = 1, splitter.get_max_transport_line_index(), 1 do
		local contents = splitter.get_transport_line(i).get_contents()
		local key = next(contents)
		if key then
			if checks < 360 then
				table.insert(global.list, {
					entity = splitter,
					checks = checks + 1
				})
			end
			return
		end
	end

	for _,output in pairs(splitter.belt_neighbours.outputs) do
		table.insert(global.list, {
			entity = output,
			checks = 0
		})
	end

	local position = splitter.position
	local name = splitter.name
	if splitter.order_deconstruction(splitter.force, splitter.last_user) then
		log('Marked ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	else
		log('Failed to Mark ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	end
end

local function container(chest, checks)
	if not chest.valid then
		return
	end

	for _,drill in pairs(game.surfaces[chest.surface.index].find_entities_filtered {
		type = 'mining-drill',
		radius = global.radius,
		position = chest.position,
		to_be_deconstructed = false
	}) do
		if drill.valid and drill.drop_target ~= nil and drill.drop_target.position.x == chest.position.x and drill.drop_target.position.y == chest.position.y then
			return
		end
	end


	if not chest.get_inventory(defines.inventory.chest).is_empty() then
		if checks < 3600 then
			table.insert(global.list, {
				entity = chest,
				checks = checks + 1
			})
		end
		return
	end

	local position = chest.position
	local name = chest.name
	if chest.order_deconstruction(chest.force, chest.last_user) then
		log('Marked ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	else
		log('Failed to Mark ' .. name .. ' for Deconstruction | x: ' .. position.x .. ' | y: ' .. position.y)
	end
end

-- Events --
script.on_init(function()
	global.list = {}
	calcRadius()
end)
script.on_configuration_changed(calcRadius)

script.on_event(defines.events.on_resource_depleted, function(event)
	local prototype = event.entity.prototype
	if prototype.infinite_resource then
		return
	end

	if prototype.resource_category == 'basic-solid' then
		local drills = game.surfaces[event.entity.surface.index].find_entities_filtered {
			type = 'mining-drill',
			radius = global.radius,
			position = event.entity.position,
			to_be_deconstructed = false
		}

		for _,drill in pairs(drills) do
			table.insert(global.list, {
				entity = drill,
				checks = 0
			})
		end
	end
end)

script.on_nth_tick(10, function()
	local key, value = next(global.list)
	if not key then
		return
	end
	global.list[key] = nil
	if not value.entity.valid then
		return
	end

	if value.entity.type == 'mining-drill' then
		miningDrill(value.entity, value.checks)
	elseif value.entity.type == 'transport-belt' and settings.global['blackaslight-belts'].value then
		transportBelt(value.entity, value.checks)
	elseif value.entity.type == 'underground-belt' and settings.global['blackaslight-belts'].value then
		undergroundBelt(value.entity, value.checks)
	elseif value.entity.type == 'splitter' and settings.global['blackaslight-belts'].value then
		splitter(value.entity, value.checks)
	elseif value.entity.type == 'container' and settings.global['blackaslight-chests'].value then
		container(value.entity, value.checks)
	else
		log('entity_name: ' .. value.entity.name .. ' | entity_type: ' .. value.entity.type)
	end
end)
