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
	sprite = 1,
}

-- variables of physics
gravity = 0.3
friction = 0.8

-- plataforms
plataforms = {
 {x=40, y=110, w=48, h=8},
 {x=20, y=90, w=32, h=8},
 {x=70, y=70, w=40, h=8},
 {x=10, y=50, w=30, h=8},
 {x=90, y=30, w=35, h=8},
 {x=50, y=10, w=28, h=8},
}

-- camera
cam_y = 0

function _init()
	-- start basics sprites
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
		rectfill(p.x, p.y, p.x + p.w, p.y + p.h, 3)
		rect(p.x, p.y, p.x + p.w, p.y + p.h, 2)
	end
	
	-- draw player
	rectfill(player.x, player.y, player.x + player.w, player.y + player.h, 8)
	rect(player.x, player.y, player.x + player.w, player.y + player.h, 0)
	
	-- draw eyes
	pset(player.x + 2, player.y + 2, 0)
	pset(player.x + 5, player.y + 2, 0)
	
	-- reset camera for ui
	camera()
	
	-- instructions
	print("⬅️➡️ move", 2, 2, 7)
	print("z jump", 2, 8, 7)
	print("height: " .. flr(-player.y), 2, 116,7)
	
	-- jump indicator
	if player.grounded then
		print("ground", 2, 122, 11)
	else
		print("air", 2, 122, 8)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
