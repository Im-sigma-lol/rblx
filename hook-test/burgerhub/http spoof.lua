--burger hub
loadstring(game:HttpGet("https://raw.githubusercontent.com/BurgerMann/BurgerHub/refs/heads/main/BurgerHub"))()
-- Load HttpSpy with API support
local HttpSpy = loadstring(game:HttpGet("https://raw.githubusercontent.com/NotDSF/HttpSpy/main/init.lua"))({
    AutoDecode = false,       -- Automatically decode JSON responses
    Highlighting = false,     -- Syntax highlight requests/responses
    SaveLogs = false,         -- Save HTTP logs
    CLICommands = false,      -- Enable command line tools
    ShowResponse = false,     -- Display response content
    API = true,              -- Enable HttpSpy API (required for hooking)
    BlockedURLs = {}         -- Initial empty blocklist
})

-- Hook a specific request to pastebin
HttpSpy:HookSynRequest("https://pastebin.com/raw/kPmMiwnP", function(response)
    response.Body = "return false"  -- Replace actual response with fake code
    return response                 -- Return modified response to the game
end)
