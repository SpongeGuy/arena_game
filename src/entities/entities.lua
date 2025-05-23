-- organization file for entity scripts
anim8 = require('lib/anim8')
sfxr = require('lib/sfxr')

require("src/StateMachine")
require("src/SpatialManager")

-- plants
require("src/entities/bromeliad")

-- creatures
require("src/entities/captain")
require("src/entities/drone")

-- spawners
require("src/entities/spawn_pit")

-- used for communication between entities, determines which type of entity
-- set this ideally in the entity creation function
EntityType = {
	fruit_plant = "fruit_plant",
	normal_plant = "normal_plant",
	creature = "creature",
	bullet = "bullet",
	fruit = "fruit",
	spawner = "spawner",
}

creatures = {}
collectibles = {}
bullets = {}
plants = {}
spawners = {}

function create_new_entity(posX, posY, e_type)
	entity = {
		state_machine = StateMachine.new(),
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		entity_type = e_type,
		_destroy_this = false,
	}

	entity.state_machine.entity = entity
	SpatialManager:register_entity(entity)
	return entity
end


-- called in main
function update_all_entities(dt)
	for i = #bullets, 1, -1 do
		local bullet = bullets[i]
		bullet:update(dt)
		SpatialManager:update_entity(bullet)
		-- _destroy_this flag
		if bullet._destroy_this then
			table.remove(bullets, i)
			SpatialManager:remove_entity(bullet)
		end
	end

	for i = #spawners, 1, -1 do
		local spawner = spawners[i]
		spawner:update(dt)
		SpatialManager:update_entity(spawner)
		-- _destroy_this flag
		if spawner._destroy_this then
			table.remove(spawners, i)
			SpatialManager:remove_entity(spawner)
		end
	end

	for i = #creatures, 1, -1 do
		local creature = creatures[i]
		creature:update(dt)
		SpatialManager:update_entity(creature)
		-- _destroy_this flag
		if creature._destroy_this then
			table.remove(creatures, i)
			SpatialManager:remove_entity(creature)
		end
	end

	for i = #collectibles, 1, -1 do
		local collectible = collectibles[i]
		collectible:update(dt)
		SpatialManager:update_entity(collectible)
		-- _destroy_this flag
		if collectible._destroy_this then
			table.remove(collectibles, i)
			SpatialManager:remove_entity(collectible)
		end
	end

	for i = #plants, 1, -1 do
		local plant = plants[i]
		plant:update(dt)
		SpatialManager:update_entity(plant)
		-- _destroy_this flag
		if plant._destroy_this then
			table.remove(plants, i)
			SpatialManager:remove_entity(plant)
		end
	end
end

function draw_all_entities()
	for i = #spawners, 1, -1 do
		spawners[i]:draw()
	end

	for i = #collectibles, 1, -1 do
		collectibles[i]:draw()
	end
	
	for i = #creatures, 1, -1 do
		creatures[i]:draw()
	end

	for i = #plants, 1, -1 do
		plants[i]:draw()
	end

	for i = #bullets, 1, -1 do
		bullets[i]:draw()
	end
end

function face_towards_coordinate(ex, ey, x, y)
	-- ex, ey are coordinates of entity (these should probably be the entity's center)
	local original_angle = math.atan2(y - ey, x - ex)
	original_angle = original_angle % (2 * math.pi) -- normalize angle to [0, 2pi)
	local snap_step = math.rad(11.25)
	local snapped_angle = math.floor(original_angle / snap_step + 0.5) * snap_step -- compute snap step to nearest angle of snap step
	snapped_angle = snapped_angle % (2 * math.pi) -- normalize new angle to [0, 2pi)
	return snapped_angle
end

function random_float(min, max)
		return math.random() * (max - min) + min
	end

-- cool vector/entity functions (important)
function lerp_vector(current, target, t)
	-- t is a value between 0 and 1 that controls the blend amount
	-- t is typically multiplied by dt
	return {
		x = current.x + (target.x - current.x) * t,
		y = current.y + (target.y - current.y) * t
	}
end

function compute_desired_velocity(self, speed)
	local dist_x = self.target.pos.x - self.pos.x
	local dist_y = self.target.pos.y - self.pos.y
	local norm = vector_normalize({x = dist_x, y = dist_y})
	return {x = norm.x * speed, y = norm.y * speed}
end

function compute_desired_velocity(self, target_position, speed)
	local dist_x = target_position.x - self.pos.x
	local dist_y = target_position.y - self.pos.y
	local norm = vector_normalize({x = dist_x, y = dist_y})
	return {x = norm.x * speed, y = norm.y * speed}
end

function reflect_velocity(velocity, normal)
	local dot = velocity.x * normal.x + velocity.y * normal.y
	return {
		x = velocity.x - (2 * dot * normal.x),
		y = velocity.y - (2 * dot * normal.y),
	}
end

function AABB_collision(self, target)
	if not target.hitbox then
		return false
	end
	if self.hitbox.x + self.hitbox.w < target.hitbox.x or
		target.hitbox.x + target.hitbox.w < self.hitbox.x or
		self.hitbox.y + self.hitbox.h < target.hitbox.y or
		target.hitbox.y + target.hitbox.h < self.hitbox.y then
			return false
	end
	return true
end

function get_collision_normal(self, target)
	local self_center_x = self.hitbox.x + self.hitbox.w / 2
	local self_center_y = self.hitbox.y + self.hitbox.h / 2
	local target_center_x = target.hitbox.x + target.hitbox.w / 2
	local target_center_y = target.hitbox.y + target.hitbox.h / 2

	local dx = self_center_x - target_center_x
	local dy = self_center_y - target_center_y

	local combined_half_width = (self.hitbox.w + target.hitbox.w) / 2
	local combined_half_height = (self.hitbox.h + target.hitbox.h) / 2

	local overlap_x = combined_half_width - math.abs(dx)
	local overlap_y = combined_half_height - math.abs(dy)

	if overlap_x < overlap_y then
		if dx < 0 then
			return {x = -1, y = 0}
		else
			return {x = 1, y = 0}
		end
	else
		if dy < 0 then
			return {x = 0, y = -1}
		else
			return {x = 0, y = 1}
		end
	end
end

function vector_normalize(vector)
	local length = math.sqrt(vector.x^2 + vector.y^2)
	if length == 0 then
		return {x = 0, y = 0}
	else
		return {x = vector.x / length, y = vector.y / length}
	end
end

function vector_scalar_multiply(vector, multiplier)
	return {x = vector.x * multiplier, y = vector.y * multiplier}
end