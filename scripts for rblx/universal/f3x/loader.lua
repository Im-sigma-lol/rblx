local path = "F3X/F3X.rbxm"
local url = "https://github.com/Im-sigma-lol/rblx/raw/refs/heads/main/scripts%20for%20rblx/universal/F3X/F3X.rbxm"

-- Download if not already saved
if not isfile(path) then
    writefile(path, game:HttpGet(url))
end

-- Load model from file
local objects = { LoadCustomInstance(path) }

-- Run the first object's Source (just like game:GetObjects()[1].Source)
loadstring(objects[1].Source)()
