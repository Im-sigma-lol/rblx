local src = game:HttpGet("https://raw.githubusercontent.com/TheMugenKing02/Troll-Tower/refs/heads/main/obfuscator", true)

-- Spoof the value of `validKey`
src = src:gsub('local%s+validKey%s*=%s*".-"', 'local validKey = "key"')

-- Execute the modified version
loadstring(src)()
