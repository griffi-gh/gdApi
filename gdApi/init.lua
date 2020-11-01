local path =  (.....'.')
local zzlib  = require(path..'lib.zzlib')
local base64 = require(path..'lib.base64')
local http   = require('socket.http')

local gdApi={}

local b64d = base64.makedecoder('-','_','=')
local secret = 'Wmfd2893gb7'

local function parts(i,s)
  return string.gmatch(i..s,'(.-)'..s)
end
local function unzip(d)
  local k,a=pcall(zzlib.gunzip,d)
  if k then
    return a
  else
    print('gunzip failed (?!!)',a)
    return zzlib.inflate(d) --Try inflate
  end
end

function gdApi.decryptLevel(l)
  return unzip(base64.decode(l,b64d))
end

function gdApi.parseLevel(d)
  if d:sub(1,2)~='kS' then --If level is encrypted
    d = gdApi.decryptLevel(d)
  end
  local t = {}
  local h
  local i = 0
  for v in parts(d,';') do
    i=i+1
    
    local pargs = 0
    local part = {}
    do --parse object data (key1,value1,key2,value2;)
      local j=0 --TODO make fn
      local p
      for d in parts(v,',') do 
        j=j+1
        if j%2==0 then
          part[p]=d
          pargs=pargs+1
        end
        p=d
      end 
    end
    
    if pargs>0 then
      local ipart={}
      setmetatable(ipart,{__index=part})
      if i==1 then
        --TODO Parse Header
        h = part
      else
        ipart.id    = part['1']
        ipart.x     = part['2']
        ipart.y     = part['3']
        ipart.vflip = part['4']==1
        ipart.hflip = part['5']==1
        ipart.angle = part['6'] or 0
        t[#t+1]=ipart
      end
    end
  end

  return {
    objects = t,
    header = h
  }
end

function gdApi.downloadLevelRaw(id,server)
  server = server or 'http://boomlings.com'
  local reqbody = (
    'secret='..secret..
    '&levelID='..tonumber(id)
  )
  local resp = {}
  http.request{
    url = server..'/database/downloadGJLevel22.php',
    method = 'POST',
    source = ltn12.source.string(reqbody),
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded",
      ["Content-Length"] = #reqbody
    },
    sink=ltn12.sink.table(resp),
  }
  local raw = resp[1]  
  assert(raw,'No data')
  assert(raw~='-1','Err -1 (Nope.)')
  return raw
end

function gdApi.downloadLevel(id,server)
  local raw = gdApi.downloadLevelRaw(id,server)
  
  local data = {}
  do
    local p
    local i=0
    for str in parts(raw,':') do
      i=i+1
      if i%2==0 then
        data[tonumber(p) or p]=str
      end
      p=str
    end
  end
  
  local level = {
    id = data[1],
    name = data[2],
    raw_data = data[4],
    data = gdApi.parseLevel(data[4])
  }
  setmetatable(level, {__index=data})
  
  return level
end

return gdApi