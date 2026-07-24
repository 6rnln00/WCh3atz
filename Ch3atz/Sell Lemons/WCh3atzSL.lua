local _0x5A7C91 = {
	KeySystem = "https://raw.githubusercontent.com/6rnln00/WCh3atz/refs/heads/main/Ch3atz/Sell%20Lemons/KeySystem.lua",
	Main = "https://raw.githubusercontent.com/6rnln00/WCh3atz/refs/heads/main/Ch3atz/Sell%20Lemons/WSL.lua",
}

local _0xD84E26 = (getgenv and getgenv()) or _G
_0xD84E26.KeySystemConfig = {
	MainScriptUrl = _0x5A7C91.Main,
}

local _0x39B6F2, _0xE17A4C = pcall(game.HttpGet, game, _0x5A7C91.KeySystem)
if not _0x39B6F2 or type(_0xE17A4C) ~= "string" or _0xE17A4C == "" then
	_0xD84E26.KeySystemConfig = nil
	error("WCheatz | Key system could not be downloaded")
end

local _0xC62D18, _0x71F9A3 = loadstring(_0xE17A4C)
if type(_0xC62D18) ~= "function" then
	_0xD84E26.KeySystemConfig = nil
	error("WCheatz | Key system could not be compiled: " .. tostring(_0x71F9A3))
end

return _0xC62D18()
