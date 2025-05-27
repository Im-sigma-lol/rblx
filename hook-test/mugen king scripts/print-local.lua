local src = game:HttpGet("https://raw.githubusercontent.com/TheMugenKing02/Troll-Tower/refs/heads/main/obfuscator", true)

-- Replace with global
src = src:gsub("local%s+validKey%s*=", "validKey =")
src = 'validKey = nil\n' .. src .. '\nprint("VALID KEY =", validKey)'

loadstring(src)()
