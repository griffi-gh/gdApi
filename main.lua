gd = require'gdApi'

local level = gd.downloadLevel(64774656)

--64774656 "wave challenge"
--4454123  "Sonar"
--182      "Automatic level"
--64761839 Test Level

local cx=0 --camera x
function love.update()
  if love.keyboard.isDown('left')then
    cx=cx-5
  end
  if love.keyboard.isDown('right')then
    cx=cx+5
  end
end

function love.draw()
  local g = love.graphics
  local w,h = g.getDimensions()
  
  g.print(love.timer.getFPS())
  for i,v in ipairs(level.data.objects) do
    local ow,oh=30,30 --obj size
    
    local rx = v.x-ow/2-cx
    local ry = h-v.y-oh/2 --screen pos
    
    if rx>-ow and rx<w then
      g.rectangle('line',rx-0.5,ry-0.5,ow,oh)
      g.print(v.id,rx,ry) --id
    end
  end
  
end