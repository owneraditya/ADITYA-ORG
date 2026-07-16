do
    local hud = slua_GameFrontendHUD
    if not hud then return end
    local pc = hud:GetPlayerController()
    if not pc then return end
    local pawn = pc:GetCurPawn()
    if not pawn then return end
    if _G._MOD_LOADED and _G._MOD_PAWN == pawn then return end
    _G._MOD_LOADED = true
    _G._MOD_PAWN = pawn
end

-- Expiration check (always return true - no expiry)
local function CheckExpiration()
    return true
end

-- Show expire popup (disabled)
local function ShowExpirePopup()
end

-- Show days remaining (disabled)
local function ShowDaysRemainingPopup()
end

-- MAIN FUNCTION - Without emojis
function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then
        ShowExpirePopup()
        return
    end
    pcall(function()
        ShowDaysRemainingPopup()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] or require("client.slua.logic.url.logic_webview_sdk")

        local function onClickDirect()
            pcall(function()
                if Web and Web.OpenURL then
                    Web:OpenURL("https://t.me/ADITYA_ORG")
                end
                local OpenURL = import("OpenURL")
                if OpenURL and OpenURL.Open then
                    OpenURL:Open("tg://resolve?domain=ADITYA_ORG")
                end
                if slua and slua.openURL then
                    slua.openURL("https://t.me/ADITYA_ORG")
                end
            end)
            
            local UIUtils = require("GameLua.Util.UIUtils")
            if UIUtils and UIUtils.ShowNotice then
                UIUtils:ShowNotice("[ADITYA_ORG] Opening Telegram...")
            end
        end

        Msg.Show(4, "[@ADITYA_ORG]", 
            "================================\n" ..
            "MOD PAK EXPIRED\n" ..
            "================================\n\n" ..
            "MOD PAK DISABLED \n" ..
            "FREE TRIAL KATAM\n" ..
            "DM TO BUY\n\n" ..
            "JOIN TELEGRAM:\n" ..
            "   @ADITYA_ORG\n\n" ..
            "CLICK OK TO OPEN DM\n" ..
            "================================", 
            onClickDirect)
        _G.WelcomeShown = true
    end)
end

-- ALL CHEATS COMPLETELY DISABLED
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end

_G.CheatsEnabled = false

-- Disable all ESP/Aimbot/Wallhack
_G._ESPTimerHandle = nil
_G._ESPTimerChar = nil
_G._AimbotCurrentPC = nil
_G._FeaturesTimerPC = nil

if _G._ESPWatchdogHandle then
    pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end)
    _G._ESPWatchdogHandle = nil
end

-- Disable all functions
local function disableAll()
    pcall(function()
        local funcs = {
            "ApplyWallHack", "ESPTick", "ApplyHardAimbot", "Enable165FPSLogic", "EnableiPadViewUI",
            "InitializeLogBlocker", "InitializeScannerBlocker", "InitializeAntiReport", 
            "InitializeAntiCheatHooks", "InitializeConnectionGuard", "InitializeSkinBypass",
            "InitializeReplayTelemetryBlocker", "DisableHiggsBoson"
        }
        for _, f in ipairs(funcs) do
            if _G[f] then _G[f] = nop end
        end
    end)
end

disableAll()

-- Auto show welcome popup
pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and pc.AddGameTimer then
        pc:AddGameTimer(2.0, false, function()
            _G.TryShowWelcome()
        end)
    else
        _G.TryShowWelcome()
    end
end)

-- Timer to keep disabled
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if pc and pc.AddGameTimer then
    pc:AddGameTimer(5.0, true, function()
        _G.CheatsEnabled = false
        disableAll()
    end)
end

print("[@ADITYA_ORG] ==================================")
print("[@ADITYA_ORG] MOD DISABLED - Update Mode Only")
print("[@ADITYA_ORG] Telegram: @ADITYA_ORG")
print("[@ADITYA_ORG] ==================================")