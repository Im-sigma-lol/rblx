-- Load HttpSpy with API support
local HttpSpy = loadstring(game:HttpGet("https://raw.githubusercontent.com/NotDSF/HttpSpy/main/init.lua"))({
    AutoDecode = true,       -- Automatically decode JSON responses
    Highlighting = true,     -- Syntax highlight requests/responses
    SaveLogs = true,         -- Save HTTP logs
    CLICommands = true,      -- Enable command line tools
    ShowResponse = true,     -- Display response content
    API = true,              -- Enable HttpSpy API (required for hooking)
    BlockedURLs = {}         -- Initial empty blocklist
})

-- Hook a specific request to pastebin
HttpSpy:HookSynRequest("https://pastebin.com/raw/kPmMiwnP", function(response)
    response.Body = "return false"  -- Replace actual response with fake code
    return response                 -- Return modified response to the game
end)
