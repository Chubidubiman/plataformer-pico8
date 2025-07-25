pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- plataform game
-- jump to up

-- game variables
player = {
	x = 60,
	y = 100,
	w = 8,
	h = 8,
	dx = 0,
	dy = 0,
	grounded = false,
	jump_power = -4,
	speed = 2,
	sprite = 0,
}

-- variables of physics
gravity = 0.3
friction = 0.7

-- plataforms
plataforms = {
 {x=0, y=110, w=125, h=8, sprite=63},
 {x=20, y=90, w=32, h=8, sprite=63},
 {x=70, y=70, w=40, h=8, sprite=63},
}

-- enemies
enemies = {}
enemy_spawn_chance = 0.3 -- probability that an enemy appears on a platform
enemy_speed = 0.5 -- enemy's movement speed

-- plataform generation
highest_platform_y = 70 -- height of the highest platform
generation_distance = 50 -- distance to generate new platforms
platform_spacing = 15 -- vertical spacing between platforms
platform_spacing_x = 90 -- horizontal spacing between platforms (0-100)
max_platforms = 20 -- maximum number of platforms in memory

-- camera
cam_y = 0

function generate_platforms()
	-- generate platforms when the player approaches the upper limit
	while player.y < highest_platform_y + generation_distance do
		-- create new platform
		local new_platform = {
			x = rnd(platform_spacing_x),  -- position x random (0-100)
			y = highest_platform_y - platform_spacing - rnd(10), -- altura con variaciれはn
			w = 20 + rnd(40), -- random width between 20-60
			h = 8,
			sprite = 63
		}
		
		-- ensure that the platform is within the limits
		if new_platform.x + new_platform.w > 128 then
			new_platform.x = 128 - new_platform.w
		end
		
		-- add platform to array
		add(plataforms, new_platform)
		
		-- possibility of generating enemy on this platform
		if rnd() < enemy_spawn_chance and new_platform.w >= 16 then
			create_enemy(new_platform)
		end
		
		-- update higher height
		highest_platform_y = new_platform.y
	end
end

function create_enemy(platform)
	local enemy = {
		x = platform.x + rnd(platform.w - 8),
		y = platform.y - 8,
		w = 8,
		h = 8,
		dx = (rnd() > 0.5) and enemy_speed or -enemy_speed, -- random direction
		sprite = 16, -- enemy sprite
		platform = platform, -- reference to the platform
		alive = true
	}
	add(enemies, enemy)
end

function cleanup_platforms()
	-- delete platforms that are very down to save memory
	local cutoff_y = player.y + 200
	
	for i = #plataforms, 1, -1 do
		if plataforms[i].y > cutoff_y then
			del(plataforms, plataforms[i])
		end
	end
	
	-- limit total number of platforms
	while #plataforms > max_platforms do
		-- eliminate the lowest platform
		local lowest_platform = plataforms[1]
		local lowest_index = 1
		
		for i = 2, #plataforms do
			if plataforms[i].y > lowest_platform.y then
				lowest_platform = plataforms[i]
				lowest_index = i
			end
		end
		
		del(plataforms, lowest_platform)
	end
end

function cleanup_enemies_for_platform(platform)
	-- eliminate enemies that are on this platform
	for i = #enemies, 1, -1 do
		if enemies[i].platform == platform then
			del(enemies, enemies[i])
		end
	end
end

function update_enemies()
	for enemy in all(enemies) do
		if enemy.alive then
			-- move enemy
			enemy.x = enemy.x + enemy.dx
			
			-- check platform limits
			if enemy.x <= enemy.platform.x then
				enemy.x = enemy.platform.x
				enemy.dx = -enemy.dx -- change direction
			elseif enemy.x + enemy.w >= enemy.platform.x + enemy.platform.w then
				enemy.x = enemy.platform.x + enemy.platform.w - enemy.w
				enemy.dx = -enemy.dx -- change direction
			end
			
			-- check collision with player
			if player.x < enemy.x + enemy.w and
						player.x + player.w > enemy.x and
						player.y < enemy.y + enemy.h and
						player.y + player.h > enemy.y then
				
				-- the player plays the enemy - restart game
				player.x = 60
				player.y = 100
				player.dx = 0
				player.dy = 0
				-- opcional: eliminate all enemies
				-- enemies = {}
			end
		end
	end
end

function _init()
	-- start basics sprites
	-- initialize random seed
	srand(stat(0))
end

function _update()
	--input of game
	if btn(0) then --left
		player.dx = -player.speed
	elseif btn(1) then --rigth
		player.dx = player.speed
	else
		player.dx = player.dx * friction	
	end

	-- jump
	if btnp(4) and player.grounded then
		player.dy = player.jump_power
		player.grounded = false
	end

	-- apply gravity
	player.dy = player.dy + gravity
	
	-- move player
	player.x = player.x +player.dx
	player.y = player.y +player.dy
	
	-- horizontal limit
	if player.x < 0 then player.x = 0 end
	if player.x > 120 then player.x = 120 end
	
	-- colisions with plataforms
	player.grounded = false
	
	for p in all(plataforms) do
		if player.x < p.x + p.w and
					player.x + player.w > p.x and
					player.y < p.y + p.h and
					player.y + player.h > p.y then
	
			-- collitions up
			if player.dy > 0 and player.y < p.y then
						player.y = p.y - player.h 
						player.dy = 0
						player.grounded = true
			end
		end
	end
	
	-- update camera
	target_cam_y = player.y - 64
	cam_y = cam_y + (target_cam_y - cam_y) * 0.1
	
	-- generate new plataforms
	generate_platforms()
	
	-- update enemies
	update_enemies()
	
	-- clean up lod plataforms
	cleanup_platforms()
	
	--limit down (restar if fall)
	if player.y > cam_y + 150 then
		player.x = 60
		player.y = 100
		player.dx = 0
		player.dy = 0
	end
end

function _draw()
	cls(12) -- celeste color
	
	-- apply camera
	camera(0, cam_y)
	
	-- draw plataforms
	for p in all(plataforms) do
	
		local tiles_x = ceil(p.w/8)
		local tiles_y = ceil(p.h/8)
		
		for tx = 0, tiles_x - 1 do
			for ty = 0, tiles_y - 1 do
				spr(p.sprite, p.x + tx * 8, p.y + ty * 8)
			end
		end
	end
	
	-- draw player
	spr(player.sprite, player.x, player.y)
	
	-- draw enemies
	for enemy in all(enemies) do
		if enemy.alive then
			spr(enemy.sprite, enemy.x, enemy.y)
		end
	end

	-- reset camera for ui
	camera()
	
	-- instructions
	print("⬅️➡️ move", 2, 2, 7)
	print("z jump", 2, 8, 7)
	print("height: " .. flr(-player.y), 2, 116,7)
	print("platforms: " .. #plataforms, 2, 14, 7)
 print("enemies: " .. #enemies, 2, 20, 7)

	-- jump indicator
	if player.grounded then
		print("ground", 2, 122, 11)
	else
		print("air", 2, 122, 8)
	end
end
__gfx__
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08088080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
75722757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77222277000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002e2200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333333b3
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043344344
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044344445
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045444444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444544
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044445444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045444444
