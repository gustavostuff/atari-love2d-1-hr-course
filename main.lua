local bulletSpeed = 200
local enemySpawTimer = 0
local enemySpawDelay = 0.5
local enemySpeedFactor = 1
local score = 0
local enemyDeathSound = love.audio.newSource('assets/enemy-death.ogg','static')

bullets = {}
enemies = {}

ship = {
  img = love.graphics.newImage('assets/ship.png'),
  x = 80,
  y = 170,
  r = 3,
  speed = 100,
  bulletImg = love.graphics.newImage('assets/bullet.png')
}

-- colors in love are 0-1 instead of 0-255
local colors = {
  red = { love.math.colorFromBytes(208, 70, 72) },
  green = { love.math.colorFromBytes(109, 170, 44) },
  blue = { love.math.colorFromBytes(109, 194, 202) },
  yellow = { love.math.colorFromBytes(218, 212, 94) },
  white = { love.math.colorFromBytes(222, 238, 214) },
  black = { love.math.colorFromBytes(20, 12, 28) },
  orange = { love.math.colorFromBytes(210, 125, 44) }
}

local function resetGame()
  enemies = {} -- list of enemies
  bullets = {} -- bullets (lasers)
  ship.x = canvas:getWidth() / 2
  ship.y = 170
  gameover = false
  enemySpawTimer = 0
  enemySpawDelay = 0.5
  enemySpeedFactor = 1
  score = 0
end

local function fire(x, y)
  table.insert(bullets, {
    x = x,
    y = y,
    r = 2
  })
end

local function doTheyCollide(a, b)
  local hyp = math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
  return hyp < (a.r + b.r)
end

local function spawnEnemy(canvas)
  table.insert(enemies, {
    x = love.math.random(0, canvas:getWidth()),
    y = -love.math.random(0, canvas:getHeight()),
    speed = love.math.random(40, 50),
    r = 3,
    damage = 0,
    -- type 2 enemies = x10 the normal score
    type = (love.math.random(1, 20) == 1) and 2 or 1
  })
end

function love.load()
  canvas = love.graphics.newCanvas(160, 192)
  canvas:setFilter('nearest', 'nearest')
  scaleX = love.graphics.getWidth() / canvas:getWidth()
  scaleY = love.graphics.getHeight() / canvas:getHeight()

  font = love.graphics.newFont('assets/EightBit Atari-60zeich.ttf', 8)
  font:setFilter('nearest', 'nearest')
  love.graphics.setFont(font)
end

function love.update(dt)
  if gameover then
    return
  end

  -- move bullets
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.y = b.y - dt * bulletSpeed
    if b.dead or b.y < 0 then
      table.remove(bullets, i)
    end
  end

  -- move enemies
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    e.y = e.y + dt * e.speed * enemySpeedFactor
    if e.dead or e.y > canvas:getHeight() * 1.2 then --  a bit beyond the screen
      table.remove(enemies, i)
    end
  end

  -- ship movement
  if love.keyboard.isDown('a') then
    ship.x = ship.x - dt * ship.speed
    if ship.x < 0 then ship.x = 0 end
  elseif love.keyboard.isDown('d') then
    ship.x = ship.x + dt * ship.speed
    if ship.x > canvas:getWidth() then ship.x = canvas:getWidth() end
  end

  if love.keyboard.isDown('w') then
    ship.y = ship.y - dt * ship.speed
    if ship.y < 0 then ship.y = 0 end
  elseif love.keyboard.isDown('s') then
    ship.y = ship.y + dt * ship.speed
    if ship.y > canvas:getHeight() then ship.y = canvas:getHeight() end
  end

  -- enemy spawning
  enemySpawTimer = enemySpawTimer + dt
  if enemySpawTimer >= enemySpawDelay then
    enemySpawTimer = 0
    spawnEnemy(canvas)
  end

  -- collisions
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    for j = #bullets, 1, -1 do
      local b = bullets[j]
      if doTheyCollide(e, b) then
        b.dead = true
        e.damage = e.damage + 1
        if e.damage >= 3 then
          e.dead = true
          enemyDeathSound:play()
          score = score + 10 * (e.type == 2 and 10 or 1)
        end
      end
    end

    -- player collision
    if doTheyCollide(ship, e) then
      gameover = true
    end
  end

  -- spawn more and faster enemies:
  enemySpawDelay = enemySpawDelay - dt * 0.004
  if enemySpawDelay <= 0.02 then
    enemySpawDelay = 0.02
  end
  enemySpeedFactor = enemySpeedFactor + dt * 0.04
  if enemySpeedFactor > 5 then
    enemySpeedFactor = 5
  end
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(colors.black)
  if gameover then
    love.graphics.setColor(colors.red)
    love.graphics.rectangle('fill', 0, 0, canvas:getWidth(), canvas:getHeight())
  end
  -- draw ship
  love.graphics.setColor(colors.white)
  love.graphics.draw(
    ship.img, 
    math.floor(ship.x),
    math.floor(ship.y),
    0, 1, 1,
    ship.img:getWidth() / 2, ship.img:getHeight() / 2
  )

  -- draw bullets
  for i = 1, #bullets do
    local b = bullets[i]
    love.graphics.draw(ship.bulletImg,
      math.floor(b.x),
      math.floor(b.y),
      0, 1, 1,
      ship.bulletImg:getWidth() / 2, ship.bulletImg:getHeight() / 2
    )
  end

  -- draw enemies
  for i = 1, #enemies do
    local e = enemies[i]
    love.graphics.setColor(colors.green)
    if e.type == 2 then
      love.graphics.setColor(colors.orange)
    end
    love.graphics.circle('fill', math.floor(e.x), math.floor(e.y), e.r)
  end

  -- score
  love.graphics.setColor(colors.white)
  love.graphics.print(
    tostring(score),
    math.floor(canvas:getWidth() / 2 - font:getWidth(tostring(score)) / 2),
    10
  )

  love.graphics.setCanvas()
  love.graphics.setColor(colors.white)
  love.graphics.draw(canvas, 0, 0, 0, scaleX, scaleY)

  love.graphics.setColor(colors.white)
  if debug then
    love.graphics.print(
      'FPS: ' .. love.timer.getFPS() ..
      '\nenemies: ' .. #enemies ..
      '\nbullets: ' .. #bullets ..
      '\nspawn delay: ' .. string.format('%.3f', enemySpawDelay) ..
      '\nenemy speed factor: ' .. string.format('%.3f', enemySpeedFactor)
    )
  end
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end

  if gameover then
    if key == 'return' then
      resetGame()
    end
    return
  end

  if key == 'space' then
    fire(ship.x, ship.y)
  end

  if key == 'f1' then
    debug = not debug
  end
end
