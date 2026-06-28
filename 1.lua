-- ============================================================
-- MODDED BY ADITYA_ORG + @ADITYA_ORG
-- Complete MOD with Bypass V2.0 (14 Modules)
-- All features: Aimbot, ESP, Wallhack, 165 FPS, No Grass, iPad View
-- Bypass activates on game start with popup
-- ============================================================

-- ============================================================
-- PER-MATCH GUARD (re-init when player controller changes)
-- ============================================================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

-- ============================================================
-- FEATURE TOGGLES (existing)
-- ============================================================
if not _G.Mod_Aimbot_Enabled then _G.Mod_Aimbot_Enabled = false end
if not _G.Mod_ESP_Enabled then _G.Mod_ESP_Enabled = false end
if _G.Mod_Wallhack_Enabled == nil then _G.Mod_Wallhack_Enabled = false end
if _G.Mod_FPS165_Enabled == nil then _G.Mod_FPS165_Enabled = true end
if _G.Mod_NoGrass_Enabled == nil then _G.Mod_NoGrass_Enabled = false end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end

if _G.Mod_iPadViewDistance == nil then _G.Mod_iPadViewDistance = 90 end

if _G.Mod_Chams_GreenEnabled == nil then _G.Mod_Chams_GreenEnabled = false end
if _G.Mod_Chams_YellowEnabled == nil then _G.Mod_Chams_YellowEnabled = false end
if _G.Mod_Chams_GreenRGB == nil then _G.Mod_Chams_GreenRGB = {R=0, G=255, B=0, A=255} end
if _G.Mod_Chams_YellowRGB == nil then _G.Mod_Chams_YellowRGB = {R=255, G=255, B=0, A=255} end

-- ESPConfig for wallhack (merged with Glow)
_G.ESPConfig = _G.ESPConfig or {
    Wallhack = false,
    WallhackVisibleColor = 1,
    WallhackInvisibleColor = 2,
    WallhackBrightness = 25,
    WallhackGlow = 3.0,          -- <--- NEW GLOW CONFIG
    ShowAI = true,
}

local require = require
local import  = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string
local os = os

-- ============================================================
-- NOP FUNCTIONS (used by bypass and mod)
-- ============================================================
local function nop() end
local function nopt() return {} end
local function nopnil() return nil end
local function noptrue() return true end
local function nopfalse() return false end
local function nopstr() return "" end
_G.CheatsEnabled = true

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

-- ============================================================
-- MODULE 1: DOMAIN BLOCKER (HTTP + SOCKET + WEBVIEW)
-- ============================================================
local blockedDomains = {
    "tss.tencent","syzsdk","gcloud.qq","reportlog","tdos","logupload","feedback.wh","crash2",
    "privacy.qq","privacy.tencent","oth.eve","mdt.qq","act.tencentyun","analytics","report.qq",
    "anticheatexpert","crashsight","wetest","log.tav","sngd","tracer","intlsdk","igamecj",
    "cdn.club","gpubgm","graph.facebook","calendarpushsubscription","googleads","doubleclick",
    "firebaselogging","firebaseremoteconfig","fonts.googleapis","abs.twimg","dl.listdl",
    "igame.gcloudcs","bugly","beacon","helpshift","tdm","apm","safeguard","weiyun","qzone",
    "tencent-cloud","myapp","idqqimg","gtimg","qqmail","tcdn","cloudctrl","sdkostrace",
    "103.134.189.146","mbgame","csoversea","igame","pubgmobile","down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com","log.tav.qq","syzsdk.qq","logiservice.qcloud",
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice"
}

local function InitDomainBlocker()
    pcall(function()
        if package.loaded["client.network.http.HttpClient"] then
            local hc = package.loaded["client.network.http.HttpClient"]
            if hc and hc.SendRequest then
                local orig = hc.SendRequest
                hc.SendRequest = function(self, url, cb, method, headers, content, timeout)
                    for _, host in ipairs(blockedDomains) do
                        if url and string.find(string.lower(url), string.lower(host)) then
                            return nil
                        end
                    end
                    return orig(self, url, cb, method, headers, content, timeout)
                end
            end
        end
        if NetUtil and NetUtil.SendHttpRequest then
            local orig = NetUtil.SendHttpRequest
            NetUtil.SendHttpRequest = function(url, cb, method, headers, content)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return orig(url, cb, method, headers, content)
            end
        end
        local wv = package.loaded["client.slua.logic.url.logic_webview_sdk"]
        if wv and wv.OpenURL then
            local orig = wv.OpenURL
            wv.OpenURL = function(url)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return orig(url)
            end
        end
        if socket and socket.connect then
            local orig = socket.connect
            socket.connect = function(host, port, timeout)
                for _, blocked in ipairs(blockedDomains) do
                    if host and string.find(string.lower(host), string.lower(blocked)) then
                        return nil, "blocked"
                    end
                end
                return orig(host, port, timeout)
            end
        end
    end)
end

-- ============================================================
-- MODULE 2: SKIN BYPASS
-- ============================================================
local function InitSkinBypass()
    pcall(function()
        local puf = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if puf then
            puf.ReportEvent = nop
            puf.ReportDownloadResult = nop
            puf.ReportODPTDError = nop
        end
        local au = package.loaded["AvatarUtils"]
        if au then
            au.CheckIsWeaponInBlackList = nopfalse
            au.IsValidAvatar = noptrue
        end
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local fcs = sm and sm:Get("FileCheckSubsystem")
        if fcs then
            fcs.StartCheck = nop
            fcs.ReportAbnormalFile = nop
        end
        local ee = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if ee then
            ee.Report = nop
        end
    end)
end

-- ============================================================
-- MODULE 3: TSS + SDK BLOCKER
-- ============================================================
local function InitTssBlocker()
    pcall(function()
        local tss = package.loaded["TssSdk"] or _G.TssSdk
        if tss then
            if tss.OnRecvData then tss.OnRecvData = nop end
            if tss.SendReportInfo then tss.SendReportInfo = nop end
            if tss.ReportData then tss.ReportData = nop end
            tss.ScanMemory = noptrue
            tss.IsEmulator = nopfalse
            tss.GetTssSdkReportInfo = nopstr
        end
        local beacon = package.loaded["BeaconSDK"] or _G.BeaconSDK
        if beacon then
            beacon.Report = nop
            beacon.ReportEvent = nop
            beacon.ReportData = nop
        end
        local bugly = package.loaded["BuglySDK"] or _G.BuglySDK
        if bugly then
            bugly.ReportException = nop
            bugly.ReportError = nop
            bugly.SetUserData = nop
        end
        local helpshift = package.loaded["HelpShift"] or _G.HelpShift
        if helpshift then
            helpshift.Report = nop
            helpshift.SendFeedback = nop
            helpshift.ReportUser = nop
        end
    end)
end

-- ============================================================
-- MODULE 4: LOG BLOCKER
-- ============================================================
local function InitLogBlocker()
    pcall(function()
        local ssm = import("ScreenshotMTDer")
        if ssm then
            ssm.MTDePicture = nopstr
            ssm.ReMTDePicture = nopstr
            ssm.HasCaptured = noptrue
        end
        local tlog = package.loaded["TLog"] or _G.TLog
        if tlog then
            for _, f in ipairs({"Info","Warning","Error","Debug","Report"}) do
                if tlog[f] then tlog[f] = nop end
            end
        end
        local cs = package.loaded["CrashSight"] or _G.CrashSight
        if cs then
            cs.ReportException = nop
            cs.SetCustomData = nop
            cs.Log = nop
        end
        local gru = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if gru then
            gru.BugglyPostExceptionFull = nopfalse
            gru.CheckCanBugglyPostException = nopfalse
            gru.ReplayReportData = nop
            gru.ReportGameException = nop
        end
        local ctr = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ctr then
            ctr.SendReport = nop
            ctr.SendException = nop
        end
        local tru = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tru then
            tru.ReportTLogEvent = nop
        end
    end)
end

-- ============================================================
-- MODULE 5: SCANNER BLOCKER
-- ============================================================
local function InitScannerBlocker()
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local afk = sm:Get("AFKReportorSubsystem")
            if afk then
                afk.PlayerHaveAction = nop
                afk.ReportAFK = nop
            end
            local ds = sm:Get("ClientDataStatistcsSubsystem")
            if ds then
                ds.StartToCheck = nop
                ds.DelayCount = 0
                if ds.ReportPingDelayTimer then
                    ds:RemoveGameTimer(ds.ReportPingDelayTimer)
                    ds.ReportPingDelayTimer = nil
                end
            end
            local ae = sm:Get("AvatarExceptionSubsystem")
            if ae then
                ae.ReportException = nop
                ae.BindPlayerCharacter = nop
                ae.CheckAvatarValid = noptrue
            end
            local sv = sm:Get("ShootVerifySubSystemClient")
            if sv then
                sv.ReportVerifyFail = nop
                sv.OnVerifyFailed = nop
            end
        end
        local cmbl = import("CreativeModeBlueprintLibrary")
        if cmbl then
            cmbl.MD5HashByteArray = function() return "BYPASSED" end
            cmbl.GetContentDiffData = function() return true, "BYPASSED" end
        end
        local aepi = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if aepi then
            aepi.CheckAvatarException = nop
            aepi.CheckAvatarExceptionOnce = nop
            aepi.ReportAvatarException = nop
            aepi.CheckSlotMeshVisible = nopfalse
            aepi.CheckPawnVisible = nopfalse
            aepi.CheckCanBugglyPostException = nopfalse
        end
        local acm = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if acm then
            acm.CheckAvatar = noptrue
            acm.ReportException = nop
        end
        local lmw = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if lmw then
            lmw.OnMemoryWarning = nop
            lmw.ReportMemoryWarning = nop
        end
    end)
end

-- ============================================================
-- MODULE 6: REPLAY TELEMETRY BLOCKER
-- ============================================================
local function InitReplayBlocker()
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local rbrt = sm:Get("RescueBtnReplayTraceSubsystem")
            if rbrt then
                rbrt.ReportTrace = nop
                rbrt.StartTickMonitor = nop
                rbrt.TickMonitorCheck = nop
                rbrt.ReportTickMonitorHeartbeat = nop
            end
            local grs = sm:Get("GameReportSubsystem")
            if grs then
                grs.ReplayReportData = nopfalse
                grs.CheckCanBugglyPostException = nopfalse
                grs.BugglyPostExceptionFull = nopfalse
                grs.GetClientReplayDataReporter = nopnil
                if grs.Reporter then
                    for _, f in ipairs({"ReportIntArrayData","ReportUInt8ArrayData","ReportFloatArrayData"}) do
                        if grs.Reporter[f] then grs.Reporter[f] = nop end
                    end
                end
            end
        end
        local lrr = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if lrr then
            lrr.ReportReplay = nop
            lrr.SendReportReq = nop
        end
        local lhr = package.loaded["client.slua.logic.home.logic_home_report"]
        if lhr then
            lhr.ShowInGameReportUI = nop
            lhr.SendReport = nop
        end
    end)
end

-- ============================================================
-- MODULE 7: ANTI-REPORT SYSTEM
-- ============================================================
local function InitAntiReport()
    pcall(function()
        local paths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem"
        }
        local crp = nil
        for _, p in ipairs(paths) do
            if package.loaded[p] then
                crp = package.loaded[p]
                break
            end
            local ok, m = pcall(require, p)
            if ok and m then
                crp = m
                break
            end
        end
        if crp then
            local funcs = {
                "OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager",
                "_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData",
                "_RecordTeammatePlayerInfo","_OnBattleResult",
                "_OnShowQuickReportMutualExclusiveUI"
            }
            for _, f in ipairs(funcs) do
                if crp[f] then crp[f] = nop end
            end
            crp.GetFatalDamagerMap = nopt
            crp.GetCachedTeammateName2InfoMap = nopt
            crp.GetTeammateName2InfoMapDuringBattle = nopt
            crp.GetCurrentNotInTeamHistoricalTeammateMap = nopt
            crp.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
end

-- ============================================================
-- MODULE 8: GAMEPLAY BYPASS (DS State + Network Packets)
-- ============================================================
local function InitGameplayBypass()
    pcall(function()
        if _G.GameplayCallbacks and not _G.GameplayCallbacks.IsBypassed then
            local GC = _G.GameplayCallbacks
            local orig = GC.OnDSPlayerStateChanged
            GC.OnDSPlayerStateChanged = function(uid, state, ...)
                if state and string.lower(tostring(state)) == "cheatdetected" then
                    return
                end
                if orig then
                    return orig(uid, state, ...)
                end
            end
            local blocklist = {
                "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow",
                "ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow",
                "ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate",
                "ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition",
                "ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData",
                "SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby",
                "SendDSErrorLogToLobbyOnece","SendDSHawkEyePatrolLogToLobby",
                "ReportEquipmentFlow","ReportAimFlow",
                "ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow",
                "ReportHeavyWeaponBoxOpenPlayerFlow","ReportHeavyWeaponBoxItemFlow",
                "ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
                "OnDSConnectionSaturated","ReportDSNetSaturation",
                "ReportNetContinuousSaturate","ReportDSNetRate",
                "SendClientStats","SendServerAvgTickDelta",
                "ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow",
                "ReportAIStrategyInfo","SendAIDeliveryInfo","ReportDailyTaskInfo",
                "ReportMatchRoomData","SendPlayerSpectatingLog",
                "ReportIDCardProduceFlow","ReportIDCardPickUpFlow",
                "ReportIDCardDestroyFlow","ReportRevivalFlow",
                "ReportGameSetting","ReportGameSettingNew",
                "ReportAntsVoiceTeamCreate","ReportAntsVoiceTeamQuit",
                "ReportCommonInfo","ReportLightweightStat",
                "SendSecTLog","SendDataMiningTLog","SendActivityTLog"
            }
            for _, f in ipairs(blocklist) do
                if GC[f] then GC[f] = nop end
            end
            GC.GetWeaponReport = nopt
            GC.GetOneWeaponReport = nopt
            GC.GetGeneralTLogData = nopnil
            GC.IsBypassed = true
        end
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local orig = NetUtil.SendPacket
            local bp = {
                ReportAttackFlow=1, ReportSecAttackFlow=1, ReportHurtFlow=1,
                ReportFireArms=1, ReportVerifyInfoFlow=1, ReportMrpcsFlow=1,
                ReportPlayerBehavior=1, ReportTeammatHurt=1,
                on_tss_sdk_anti_data=1, report_parachute_data=1,
                ReportAimFlow=1, ReportHitFlow=1,
                ReportCircleFlow=1, ReportJumpFlow=1,
                ReportGameStartFlow=1, ReportGameEndFlow=1,
                report_players_ping=1, report_player_ip=1,
                tss_sdk_report=1, report_memory_exception=1,
                report_avatar_exception=1
            }
            NetUtil.SendPacket = function(n, ...)
                if bp[n] then return end
                return orig(n, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

-- ============================================================
-- MODULE 9: CONNECTION GUARD
-- ============================================================
local function InitConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then
            return
        end
        local GC = _G.GameplayCallbacks
        local orig = GC.OnDSPlayerStateChanged
        local blockedStates = {
            cheatdetected = true,
            connectionlost = true,
            connectiontimeout = true,
            connectionexception = true,
            netdrivererror = true
        }
        GC.OnDSPlayerStateChanged = function(uid, state, ...)
            local s = state and string.lower(tostring(state)) or ""
            if blockedStates[s] then return end
            if orig then pcall(orig, uid, state, ...) end
        end
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        _G.ConnectionGuardInitialized = true
    end)
end

-- ============================================================
-- MODULE 10: HIGGS BOSON DISABLER
-- ============================================================
local function InitHiggsBoson()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end
        local hbc = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if hbc then
            if hbc.StaticShowSecurityAlertInDev then
                hbc.StaticShowSecurityAlertInDev = nop
            end
            if hbc.BlackList then
                for k in pairs(hbc.BlackList) do
                    hbc.BlackList[k] = nil
                end
            end
        end
        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = nop
            _G.AvatarCheckCallback.OnReportItemID = nop
            _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(pc)
                if slua.isValid(pc) and pc.HiggsBosonComponent then
                    pc.HiggsBosonComponent:ControlMHActive(0)
                    pc.HiggsBosonComponent.bMHActive = false
                end
            end
        end
        _G.BlackList = {}
        if _G.GameSafeCallbacks then
            if _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
                _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = nop
            end
            _G.GameSafeCallbacks.DoAttackFlowStrategy = nop
            _G.GameSafeCallbacks.GetScriptReportContent = nopstr
        end
        local stebp = import("STExtraBlueprintFunctionLibrary")
        if stebp then
            stebp.IsDevelopment = nopfalse
        end
    end)
end

-- ============================================================
-- MODULE 11: ZR/PR BYPASSES
-- ============================================================
local function InitZRPRBypasses()
    pcall(function()
        local STExtraLib = import("STExtraBlueprintFunctionLibrary")
        if STExtraLib then
            STExtraLib.IsDevelopment = noptrue
        end
        local hiaPath = "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"
        local hia = package.loaded[hiaPath] or require(hiaPath)
        if hia then
            hia.CheckHitIntegrity = noptrue
        end
        local securityPath = "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"
        local security = package.loaded[securityPath] or require(securityPath)
        if security then
            security.ClientRPC_SyncBanID = nop
            security.ClientRPC_StrongTips = nop
            security.ClientRPC_NormalTips = nop
        end
        local dsFightPath = "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"
        local dsFight = package.loaded[dsFightPath] or require(dsFightPath)
        if dsFight then
            dsFight.GetSimpleFightData = nopt
        end
        local dsReportPath = "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        local dsReport = package.loaded[dsReportPath] or require(dsReportPath)
        if dsReport then
            dsReport._AddEnemyMapToBattleResult = nop
        end
    end)
end

-- ============================================================
-- MODULE 12: MEMORY BYPASS
-- ============================================================
local function InitMemoryBypass()
    pcall(function()
        if not _G.old_print then
            _G.old_print = print
            print = nop
        end
        local function pmt(t)
            if not t then return end
            local mt = getmetatable(t) or {}
            mt.__metatable = "protected"
            setmetatable(t, mt)
        end
        pmt(_G)
        pmt(debug)
    end)
end

-- ============================================================
-- MODULE 13: INTEGRITY OVERRIDES
-- ============================================================
local function InitIntegrityOverrides()
    pcall(function()
        if Game and Game.CheckIntegrity then
            Game.CheckIntegrity = noptrue
        end
        if slua and slua.check_integrity then
            slua.check_integrity = noptrue
        end
        local modules = {
            "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
            "GameLua.Mod.BaseMod.Common.Security.TssSecurityModule",
            "GameLua.Mod.BaseMod.Common.Security.AntiCheatModule",
            "GameLua.Mod.BaseMod.Common.Security.MemoryIntegrityModule"
        }
        for _, mn in ipairs(modules) do
            pcall(function()
                if package.loaded[mn] then
                    local m = package.loaded[mn]
                    m.ControlMHActive = nop
                    m.Tick = nop
                    m.Report = nop
                    m.Check = noptrue
                    m.Validate = noptrue
                end
            end)
        end
    end)
end

-- ============================================================
-- INITIALIZE ALL BYPASSES (AUTO-RUN on game start)
-- ============================================================
local function InitAllBypasses()
    if _G.Bypassed then return end
    pcall(function()
        print("[BYPASS V2.0] Starting All Bypasses...")
        InitDomainBlocker()
        InitSkinBypass()
        InitTssBlocker()
        InitLogBlocker()
        InitScannerBlocker()
        InitReplayBlocker()
        InitAntiReport()
        InitGameplayBypass()
        InitConnectionGuard()
        InitHiggsBoson()
        InitZRPRBypasses()
        InitMemoryBypass()
        InitIntegrityOverrides()
        _G.Bypassed = true
        print("[BYPASS V2.0] All 14 Bypasses Activated Successfully! - @ADITYA_ORG")
    end)
end

-- ============================================================
-- RUN BYPASS IMMEDIATELY (on script load)
-- ============================================================
InitAllBypasses()

-- ============================================================
-- WELCOME POP-UP (replaces the old bypass popup)
-- ============================================================
pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
    if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
    local Web = require("client.slua.logic.url.logic_webview_sdk")
    local function onClick() if Web then Web:OpenURL("https://t.me/ADITYA_ORG") end end
    if Msg and Msg.Show then
        Msg.Show(4, "✦ ADITYA_ORG – ELITE ULTIMATE ✦",
        "\n★ Developer : @ADITYA_ORG\n" ..
        "★ Status    : UNDETECTED & OPTIMIZED\n" ..
        "★ Bypass    : 5-Layer Deep Shield + All Visuals\n\n" ..
        "✓ Premium Build Loaded Successfully!", onClick)
    end
end)

-- ============================================================
-- WALLHACK (MERGE WITH GLOW)
-- ============================================================
function ApplyWallhack()
    if not _G.ESPConfig.Wallhack then return end
    pcall(function()
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local myTeam = localPlayer.TeamID or 0
        local allCharacters = Game:GetAllPlayerPawns()
        if not allCharacters then return end
        local brightness = _G.ESPConfig.WallhackBrightness or 25
        local visibleColorIndex = _G.ESPConfig.WallhackVisibleColor or 1
        local invisibleColorIndex = _G.ESPConfig.WallhackInvisibleColor or 2
        local glow = _G.ESPConfig.WallhackGlow or 3.0   -- <-- GLOW ADDED
        local colorMap = {
            [1] = {R=brightness, G=0, B=0, A=1},
            [2] = {R=brightness, G=brightness, B=brightness, A=1},
            [3] = {R=brightness, G=brightness, B=0, A=1},
            [4] = {R=0, G=brightness, B=0, A=1},
            [5] = {R=0, G=brightness, B=brightness, A=1},
            [6] = {R=0, G=0, B=brightness, A=1},
            [7] = {R=brightness, G=0, B=brightness, A=1}
        }
        for _, enemy in pairs(allCharacters) do
            if slua.isValid(enemy) and enemy ~= localPlayer then
                local targetTeam = enemy.TeamID or 0
                if targetTeam ~= myTeam then
                    local isAI = enemy.TeamID and enemy.TeamID > 100
                    if not _G.ESPConfig.ShowAI and isAI then goto continue end
                    local isAlive = false
                    pcall(function() isAlive = enemy:IsAlive() end)
                    if not isAlive then goto continue end
                    local meshes = {}
                    pcall(function()
                        if slua.isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
                        local SkelClass = import("SkeletalMeshComponent")
                        if SkelClass then
                            local childs = enemy:GetComponentsByClass(SkelClass)
                            if childs then
                                local count = childs:Num()
                                for i = 0, count - 1 do
                                    local comp = childs:Get(i)
                                    if slua.isValid(comp) and comp ~= enemy.Mesh then
                                        table.insert(meshes, comp)
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function()
                        for _, comp in ipairs(meshes) do
                            if slua.isValid(comp) then
                                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                                if ok and slua.isValid(mat) then
                                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                                    if ok2 and slua.isValid(base) then
                                        base.bDisableDepthTest = true
                                        base.BlendMode = 2
                                    end
                                end
                                comp.UseScopeDistanceCulling = false
                                comp.PrimitiveShadingStrategy = 1
                                comp.ShadingRate = 6
                            end
                        end
                        local isVisible = false
                        if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                            pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
                        end
                        local finalColor = isVisible and colorMap[visibleColorIndex] or colorMap[invisibleColorIndex]
                        local scale = {R=3, G=3, B=0, A=0}
                        enemy.WH_MIDs = enemy.WH_MIDs or {}
                        local stateChanged = (enemy.WH_LastColorR ~= finalColor.R)
                        for _, comp in ipairs(meshes) do
                            if slua.isValid(comp) then
                                local compKey = tostring(comp)
                                enemy.WH_MIDs[compKey] = enemy.WH_MIDs[compKey] or {}
                                for i = 0, 10 do
                                    local ok, mat = pcall(function() return comp:GetMaterial(i) end)
                                    if not mat or not slua.isValid(mat) then break end
                                    local currentCached = enemy.WH_MIDs[compKey][i]
                                    if not slua.isValid(currentCached) then
                                        local ok2, newMid = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                                        if newMid and slua.isValid(newMid) then
                                            enemy.WH_MIDs[compKey][i] = newMid
                                            currentCached = newMid
                                        end
                                    end
                                    if slua.isValid(currentCached) and (stateChanged or not enemy._midColorSet) then
                                        pcall(function()
                                            currentCached:SetVectorParameterValue("颜色", finalColor)
                                            currentCached:SetVectorParameterValue("Extra Light Color", finalColor)
                                            currentCached:SetVectorParameterValue("Para_Color", finalColor)
                                            currentCached:SetVectorParameterValue("Para_ColorTint", finalColor)
                                            currentCached:SetVectorParameterValue("Para_Color_1", finalColor)
                                            currentCached:SetVectorParameterValue("Tint", finalColor)
                                            currentCached:SetVectorParameterValue("Color", finalColor)
                                            currentCached:SetVectorParameterValue("BaseColor", finalColor)
                                            currentCached:SetVectorParameterValue("BodyColor", finalColor)
                                            currentCached:SetVectorParameterValue("MainColor", finalColor)
                                            currentCached:SetVectorParameterValue("DiffuseColor", finalColor)
                                            currentCached:SetVectorParameterValue("EmissiveColor", finalColor)
                                            currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                                            -- GLOW PARAMETERS ADDED
                                            currentCached:SetScalarParameterValue("Glow", glow)
                                            currentCached:SetScalarParameterValue("Emissive", glow)
                                        end)
                                        enemy._midColorSet = true
                                    end
                                end
                            end
                        end
                        if stateChanged then
                            enemy.WH_LastColorR = finalColor.R
                        end
                    end)
                end
            end
            ::continue::
        end
    end)
end

-- Start wallhack timer
local function StartWallhackTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        if _G._WallhackTimer then pc:RemoveGameTimer(_G._WallhackTimer) end
        _G._WallhackTimer = pc:AddGameTimer(0.1, true, ApplyWallhack)
    end
end
pcall(function() StartWallhackTimer() end)

-- ============================================================
-- ESP (unchanged)
-- ============================================================
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")

local cachedPawns     = {}
local lastPawnRefresh = 0

local function IsPawnAlive(p)
    if not slua.isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local boneList = {"head","neck_01","spine_01","spine_02","spine_03","pelvis",
    "upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r",
    "calf_l","calf_r","foot_l","foot_r"}
local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "▬" or " ") end
    return s
end

local function ESPTick()
    if not _G.CheatsEnabled then return end
    if _G.Mod_ESP_Enabled == false then return end
    if _G._ESPTimerHandle and _G._ESPTimerChar and not slua.isValid(_G._ESPTimerChar) then _G._ESPTimerHandle = nil; _G._ESPTimerChar = nil end
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (slua.isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not slua.isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if slua.isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)
    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end
    local myEyePos = myPos
    pcall(function()
        if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end
    end)
    HUD = uCon:GetHUD()
    local now      = os.clock()

    if now - lastPawnRefresh > 1.0 then
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end

    local botCount = 0
    local playerCount = 0

    local totalAlive = 0
    for _, p in pairs(cachedPawns) do
        if slua.isValid(p) and p ~= currentPawn and p.TeamID ~= myTeamId and IsPawnAlive(p) then
            totalAlive = totalAlive + 1
        end
    end
    local crowded = totalAlive > 20

    for _, tPawn in pairs(cachedPawns) do
        if slua.isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                local isBot = false
                pcall(function() isBot = Game:IsAI(tPawn) end)
                if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end

                if dist < 600000 and HUD then
                    local name = tPawn.PlayerName or "UNKNOWN"
                    local distM = dist / 100

                    local hp = tPawn.Health
                    local maxHp = tPawn.HealthMax
                    local isKnock = false
                    local hpPercent = 0
                    if not hp or not maxHp or maxHp <= 0 then
                        isKnock = true
                    elseif hp <= 0 then
                        isKnock = true
                    else
                        hpPercent = hp / maxHp
                    end
                    local hpColor = {R=0,G=255,B=0,A=255}
                    if hpPercent < 0.3 then
                        hpColor = {R=255,G=0,B=0,A=255}
                    elseif hpPercent < 0.7 then
                        hpColor = {R=255,G=255,B=0,A=255}
                    end
                    if isKnock then
                        hpColor = {R=255,G=0,B=0,A=255}
                    end

                    local bones = {}
                    local mesh = tPawn.Mesh
                    if slua.isValid(mesh) then
                        for _, bn in ipairs(boneList) do
                            bones[bn] = mesh:GetSocketLocation(bn)
                        end
                    end
                    local origin = enemyPos
                    local oz = origin.Z
                    local headPos = bones["head"]
                    local footPos = bones["foot_l"]
                    local footRPos = bones["foot_r"]
                    local topZ = headPos and (headPos.Z - oz) or 90
                    local botZ = footPos and math.min(footPos.Z, footRPos and footRPos.Z or footPos.Z) - oz or -85

                    local headZ = headPos and (headPos.Z - oz) or 90
                    local hpOffset = headZ + 70 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                    local nameOffset = -80 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1

                    if crowded then
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz then HUD:AddDebugText("●", tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end
                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                    else
                        local hz = headPos and (headPos.Z - oz + 15)
                        local headChar = distM <= 25 and "❄" or "●"
                        if hz then HUD:AddDebugText(headChar, tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end

                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)

                        local nameColor = {R=0,G=255,B=0,A=255}
                        local targetPos = headPos or tPawn:K2_GetActorLocation()
                        pcall(function()
                            if Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) then
                                if _G.Mod_Chams_GreenEnabled then
                                    nameColor = _G.Mod_Chams_GreenRGB or {R=0,G=255,B=0,A=255}
                                else
                                    nameColor = {R=0,G=255,B=0,A=255}
                                end
                            else
                                if _G.Mod_Chams_YellowEnabled then
                                    nameColor = _G.Mod_Chams_YellowRGB or {R=255,G=255,B=0,A=255}
                                else
                                    nameColor = {R=255,G=255,B=0,A=255}
                                end
                            end
                        end)

                        HUD:AddDebugText(string.format("[%.0fm] %s", distM, name), tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)
                    end
                end
            end
        end
    end

    if not crowded and HUD and currentPawn then
        HUD:AddDebugText(string.format("BOT : %d     PLAYER : %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=155}, {X=0,Y=0,Z=155}, {R=255,G=255,B=0,A=255}, true, false, true, nil, 1.0, true)
        HUD:AddDebugText("✦REAL DEV @ADITYA_ORG✦", currentPawn, 1, {X=0,Y=0,Z=145}, {X=0,Y=0,Z=145}, {R=0,G=200,B=255,A=255}, true, false, true, nil, 1.0, true)
    end
end

pcall(function()
    if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end

    local function StartESP(targetActor)
        if not slua.isValid(targetActor) then return end
        cachedPawns = {}; lastPawnRefresh = 0
        _G._ESPTimerChar = targetActor
        _G._ESPTimerHandle = targetActor:AddGameTimer(0.2, true, function()
            pcall(ESPTick)
        end)
    end

    local function Watchdog()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and pc:GetCurPawn()
            if slua.isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
                if _G._ESPTimerHandle and slua.isValid(_G._ESPTimerChar) then
                    pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                end
                _G._ESPTimerHandle = nil
                StartESP(curPawn)
            elseif not _G._ESPTimerHandle then
                StartESP(curPawn)
            end
        end)
    end

    _G._ESPWatchdogHandle = Game:SetTimer(1.0, true, Watchdog)
    Watchdog()
end)

-- ============================================================
-- AIMBOT + FEATURES (unchanged)
-- ============================================================
_G.Enable165FPSLogic = function()
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if graphics then
      local orig = graphics.SetFPS
      function graphics:SetFPS(lvl)
        if orig then orig(self, lvl) end
        if lvl == 8 and _G.Mod_FPS165_Enabled ~= false then
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel() return 8, 8 end
      function impl:InitRealSupportFPS()
        local t = {}; for i = 1, 8 do t[i] = {true, true} end
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
        return t
      end
      function impl:UpdateSelectedFPSState(lvl)
        local fps = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
        for i = 2, 8 do
          local node = self.UIRoot["NodeFps"..tostring(fps[i] or 120)]
          if slua.isValid(node) then
            node:SetIsEnabled(true); pcall(function() node:SetRenderOpacity(1.0) end)
            local sw = self.UIRoot["WidgetSwitcher_"..tostring(i)]
            if slua.isValid(sw) then sw:SetActiveWidgetIndex(i == lvl and 0 or 1) end
          end
        end
      end
    end
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl; local MIN = 90
      function impl:ShowOrHide() self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
      function impl:InitFPSFTSwitch()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
        if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
        if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      function impl:InitFPSFTValue165()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local r = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch); local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          r.Slider_screen3:SetLocked(false); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
        else
          r.Slider_screen3:SetLocked(true); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
        end
        local norm = (val - MIN) / (165 - MIN)
        r.Veihclescreen3:SetText(tostring(val)); r.Slider_screen3:SetValue(norm); r.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        db:UpdateUIData(db.FPSFineTuneNum, val); if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
      end
      function impl:OnFPSFTAdd3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.min(165, cur)) end
      function impl:OnFPSFTMinus3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.max(MIN, 5)) end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3; impl.OnFPSFTMinus = impl.OnFPSFTMinus3
    end
  end)
end

_G.EnableiPadViewUI = function()
  pcall(function()
    local sc = require("client.logic.setting.setting_config")
    if sc then
      if sc.TpViewValue then sc.TpViewValue.max = 140 end
      if sc.FpViewValue then sc.FpViewValue.max = 140 end
    end
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if db and db.TpViewValue then db.TpViewValue.max = 140 end
  end)
end

if _G.Mod_FPS165_Enabled ~= false then _G.Enable165FPSLogic() end
if _G.Mod_iPadView_Enabled ~= false then _G.EnableiPadViewUI() end

-- iPad View + No Grass (realtime)
local pc = slua_GameFrontendHUD:GetPlayerController()
if slua.isValid(pc) and pc.AddGameTimer and pc ~= _G._FeaturesTimerPC then
  _G._FeaturesTimerPC = pc
  local SubsystemMgr = nil
  local lastViewDistance = nil
  _G._originalTPPFOV = nil

  pc:AddGameTimer(0.1, true, function()
    pcall(function()
      if not _G.CheatsEnabled then return end
      local pc = slua_GameFrontendHUD:GetPlayerController()
      if not slua.isValid(pc) then return end
      local char = pc:GetPlayerCharacterSafety()
      if not slua.isValid(char) then return end
      local lp = GameplayData.GetPlayerCharacter()
      if not slua.isValid(lp) then return end

      SubsystemMgr = SubsystemMgr or package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"] or require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
      if SubsystemMgr then
        local SettingSubsystem = SubsystemMgr:Get("SettingSubsystem")
        if SettingSubsystem then
          local rawSliderValue = _G.Mod_iPadViewDistance or (SettingSubsystem:GetUserSettings_Int("TpViewValue") or 90)
          local targetTPP = rawSliderValue
          if rawSliderValue > 80 and rawSliderValue <= 90 then
              targetTPP = 80 + (rawSliderValue - 80) * 6.0
          elseif rawSliderValue > 90 then
              targetTPP = rawSliderValue
          end

          local uTPPCam = char.ThirdPersonCameraComponent
          if slua.isValid(uTPPCam) and not char.bIsWeaponAiming then
              if _G._originalTPPFOV == nil then
                  _G._originalTPPFOV = uTPPCam.FieldOfView or 90
              end

              if _G.Mod_iPadView_Enabled ~= false then
                  if lastViewDistance ~= targetTPP then
                      uTPPCam.FieldOfView = targetTPP
                      lastViewDistance = targetTPP
                  end
              else
                  if lastViewDistance ~= _G._originalTPPFOV then
                      uTPPCam.FieldOfView = _G._originalTPPFOV
                      lastViewDistance = _G._originalTPPFOV
                  end
              end
          end
        end
      end

      local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
      if not gi then
        local SettingUtil = require("client.slua.logic.setting.setting_util")
        gi = SettingUtil and SettingUtil.GetGameInstance()
      end
      if gi and _G.Mod_NoGrass_Enabled ~= false then
        if not _G._NoGrassApplied then
          gi:ExecuteCMD("grass.DensityScale", "0")
          gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
          _G._NoGrassApplied = true
        end
      end
    end)
  end)
end

_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not _G.CheatsEnabled then return end
    if _G.Mod_Aimbot_Enabled == false then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not slua.isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not slua.isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) then return end
        entity.GameDeviationFactor = 0.2
        entity.WeaponAimInTime = 20
        entity.SwitchFromIdleToBackpackTime = 0.15
        entity.SwitchFromBackpackToIdleTime = 0.15
        entity.ShotGunHorizontalSpread = 0.0
        entity.ShotGunVerticalSpread = 0.0
        entity.RecoilKickADS = 0.020
        entity.AccessoriesVRecoilFactor = 0.30
        entity.AccessoriesHRecoilFactor = 0.35
        entity.ExtraHitPerformScale = 10
        if entity.RecoilInfo then
            entity.RecoilInfo.VerticalRecoilMin = 0.2
            entity.RecoilInfo.VerticalRecoilMax = 0.5
            entity.RecoilInfo.RecoilSpeedVertical = 0.2
            entity.RecoilInfo.RecoilSpeedHorizontal = 0.15
            entity.RecoilInfo.VerticalRecoveryMax = 0.2
        end
        entity.RecoilModifierStand = 0.1
        entity.RecoilModifierCrouch = 0.1
        entity.RecoilModifierProne = 0.1
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 8
                    cfg.RangeRate = 5
                    cfg.SpeedRate = 5
                    cfg.RangeRateSight = 4
                    cfg.SpeedRateSight = 4
                    cfg.CrouchRate = 4
                    cfg.ProneRate = 4
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C
                         or char.BP_AutoAimingComponent
                         or char.AutoAimingComponent
            if slua.isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "neck_01" end)
                pcall(function() aimComp.Bones[1] = "neck_01" end)
                pcall(function() aimComp.Bones[2] = "neck_01" end)
                pcall(function() aimComp.Bones:Set(0, "neck_01") end)
                pcall(function() aimComp.Bones:Set(1, "neck_01") end)
                pcall(function() aimComp.Bones:Set(2, "neck_01") end)
            end
        end)
    end)
end

local function AttachAimbotTimer()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        if pc == _G._AimbotCurrentPC then return end
        _G._AimbotCurrentPC = pc
        if pc.AddGameTimer then
            pc:AddGameTimer(0.1, true, function()
                if not slua.isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                    return
                end
                ApplyHardAimbot()
            end)
        end
    end)
end

AttachAimbotTimer()

pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not slua.isValid(_G._AimbotCurrentPC) then
                _G._AimbotCurrentPC = nil
                AttachAimbotTimer()
            end
        end)
    end
end)

-- ============================================================
-- MENU (with Wallhack + Glow settings)
-- ============================================================
_G.InitModMenuTab = function()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end

    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        local ModMenuStack = {
            { UI = AliasMap.Title, Text = "ADITYA_ORG SETTINGS" },

            {
                Key = "ModMenu_Aimbot",
                UI = AliasMap.Switcher,
                Text = "AIMBOT",
                GetFunc = function() return _G.Mod_Aimbot_Enabled or false end,
                SetFunc = function(_, value)
                    _G.Mod_Aimbot_Enabled = value
                    print("[MOD] AIMBOT: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "ESP",
                UI = AliasMap.Switcher,
                Text = "WALL ESP",
                GetFunc = function() return _G.Mod_ESP_Enabled or false end,
                SetFunc = function(_, value)
                    _G.Mod_ESP_Enabled = value
                    print("[MOD] WALL ESP: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "FPS165",
                UI = AliasMap.Switcher,
                Text = "165 FPS",
                GetFunc = function() return _G.Mod_FPS165_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_FPS165_Enabled = value
                    if value then _G.Enable165FPSLogic() end
                    print("[MOD] 165 FPS: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "NoGrass",
                UI = AliasMap.Switcher,
                Text = "NO GRASS",
                GetFunc = function() return _G.Mod_NoGrass_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_NoGrass_Enabled = value
                    if value then
                        pcall(function()
                            local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                            if gi then
                                gi:ExecuteCMD("grass.DensityScale", "0")
                                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                            end
                        end)
                    end
                    print("[MOD] NO GRASS: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "iPadView",
                UI = AliasMap.Switcher,
                Text = "IPAD VIEW",
                GetFunc = function() return _G.Mod_iPadView_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_iPadView_Enabled = value
                    if value then _G.EnableiPadViewUI() end
                    print("[MOD] IPAD VIEW: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },

            -- Wallhack section (merged with Glow)
            { UI = AliasMap.Title, Text = "--- WALLHACK ---" },
            {
                Key = "WH_Enabled",
                UI = AliasMap.TitleSwitcher,
                Text = "Wallhack",
                GetFunc = function() return _G.ESPConfig.Wallhack end,
                SetFunc = function(_, value)
                    _G.ESPConfig.Wallhack = value
                    print("[MOD] WALLHACK: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "WH_VisibleColor",
                UI = AliasMap.Switcher,
                Text = "Visible Color",
                SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
                SwitcherValue = {1,2,3,4,5,6,7},
                GetFunc = function() return _G.ESPConfig.WallhackVisibleColor or 1 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackVisibleColor = value
                    return true
                end
            },
            {
                Key = "WH_InvisibleColor",
                UI = AliasMap.Switcher,
                Text = "Invisible Color",
                SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
                SwitcherValue = {1,2,3,4,5,6,7},
                GetFunc = function() return _G.ESPConfig.WallhackInvisibleColor or 2 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackInvisibleColor = value
                    return true
                end
            },
            {
                Key = "WH_Brightness",
                UI = AliasMap.Slider,
                Text = "Brightness",
                Min = 1,
                Max = 50,
                Step = 1,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackBrightness or 25 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackBrightness = value
                    return true
                end
            },
            -- NEW GLOW SLIDER
            {
                Key = "WH_Glow",
                UI = AliasMap.Slider,
                Text = "Glow Intensity",
                Min = 0,
                Max = 10,
                Step = 0.5,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackGlow or 3.0 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackGlow = value
                    return true
                end
            },
            {
                Key = "WH_ShowAI",
                UI = AliasMap.TitleSwitcher,
                Text = "Show AI",
                GetFunc = function() return _G.ESPConfig.ShowAI end,
                SetFunc = function(_, value)
                    _G.ESPConfig.ShowAI = value
                    return true
                end
            }
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "ADITYA_ORG MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                {
                    Key = "ModMenu_Main",
                    loc = "ALL FEATURES",
                    Stack = ModMenuStack
                }
            }
        }

        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local hasModMenu = false
                    local newCatalog = {}
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then
                            hasModMenu = true
                        end
                    end
                    if not hasModMenu then
                        table.insert(newCatalog, SettingPageDefine.ModMenu)
                        args[1] = newCatalog
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end
end

_G.InitModMenuTab()

-- ============================================================
-- END OF SCRIPT (REMOVED DUPLICATE STANDALONE MODULE)
-- ============================================================