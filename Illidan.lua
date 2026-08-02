local mod	= DBM:NewMod("Illidan", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260729000000")
mod:SetCreatureID(22917)

mod:SetModelID(21135)
mod:SetUsedIcons(4)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 376244 376251 376285",
	"SPELL_AURA_APPLIED_DOSE 376244 376248",
	"SPELL_AURA_REMOVED 376244 376251 376285",
	"SPELL_CAST_START 376243 376245 376249",
	"SPELL_CAST_SUCCESS 376250",
	"UNIT_DIED",
	"UNIT_HEALTH"
)

local CID_DARK_FLAME		= 70055
local CID_CORRUPT_FLAME	= 22997

local warnParasite		= mod:NewTargetAnnounce(376251, 3)

local warnPhase2Soon	= mod:NewPrePhaseAnnounce(2, 3)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnPhase3		= mod:NewPhaseAnnounce(3)
local warnDemon			= mod:NewSpellAnnounce(376285, 3)
local warnHuman			= mod:NewAnnounce("WarnHuman", 3)
local warnBombardment	= mod:NewAnnounce("WarnBombardment", 3)

local specWarnParasite		= mod:NewSpecialWarningYou(376251, nil, nil, nil, 1, 2)
local yellParasiteFades		= mod:NewShortFadesYell(376251)
local specWarnShear			= mod:NewSpecialWarningTaunt(376244, nil, nil, nil, 1, 2)

local timerParasite		= mod:NewTargetTimer(10, 376251, nil, false, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerNextParasite	= mod:NewCDTimer(60, 376250, nil, nil, nil, 1)
local timerNextCleave	= mod:NewCDTimer(8.5, 376243, nil, nil, nil, 2)
local timerNextFlameCrash	= mod:NewCDTimer(13.5, 376245, "FlameCrashCount", nil, nil, 3)
local timerNextDrawSoul	= mod:NewCDTimer(23, 376249, nil, nil, nil, 3)
local timerDemonForm	= mod:NewBuffActiveTimer(75, 376285, nil, nil, nil, 4)

local timerCombatStart	= mod:NewCombatTimer(38)
local berserkTimer		= mod:NewBerserkTimer(720)

mod:AddSetIconOption("ParasiteIcon", 376251)
mod:AddRangeFrameOption(30, 376251)

mod.vb.excludedNames = mod.vb.excludedNames or {}

SLASH_ILLIDANEXCLUDE1 = "/illidanex"
SlashCmdList["ILLIDANEXCLUDE"] = function(msg)
	local cmd, name = msg:match("^(%S*)%s*(.-)$")
	cmd = (cmd or ""):lower()
	if cmd == "add" and name ~= "" then
		mod.vb.excludedNames[name] = true
		DBM:AddMsg("Illidan: excluded "..name)
	elseif cmd == "remove" and name ~= "" then
		mod.vb.excludedNames[name] = nil
		DBM:AddMsg("Illidan: removed "..name)
	elseif cmd == "clear" then
		wipe(mod.vb.excludedNames)
		DBM:AddMsg("Illidan: excluded list cleared")
	elseif cmd == "list" then
		local names = {}
		for n in pairs(mod.vb.excludedNames) do
			names[#names + 1] = n
		end
		DBM:AddMsg("Illidan excluded: "..table.concat(names, ", "))
	else
		DBM:AddMsg("Usage: /illidanex add|remove|clear|list [name]")
	end
end

local function getRaidUnits()
	local units = {}
	if IsInRaid() then
		for i = 1, GetNumRaidMembers() do
			units[#units + 1] = "raid"..i
		end
	else
		units[#units + 1] = "player"
		for i = 1, GetNumPartyMembers() do
			units[#units + 1] = "party"..i
		end
	end
	return units
end

local function getTopThreatTargets(n)
	local list = {}
	for _, unit in ipairs(getRaidUnits()) do
		if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			local name = UnitName(unit)
			if name and not mod.vb.excludedNames[name] then
				local isTanking, _, _, _, threatValue = UnitDetailedThreatSituation(unit, "boss1")
				if threatValue and not isTanking then
					list[#list + 1] = { name = name, threat = threatValue }
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.threat > b.threat end)
	local names = {}
	for i = 1, math.min(n, #list) do
		names[#names + 1] = list[i].name
	end
	return names
end

mod.vb.shearStacks = 0
mod.vb.demonicFury = 0
mod.vb.flameCrashCount = 0
mod.vb.warned_preP2 = false
mod.vb.addsKilled = {}
mod.vb.inDemonForm = false

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.shearStacks = 0
	self.vb.demonicFury = 0
	self.vb.flameCrashCount = 0
	self.vb.warned_preP2 = false
	self.vb.addsKilled = {}
	self.vb.inDemonForm = false
	berserkTimer:Start(-delay)
	timerNextDrawSoul:Start(20 - delay)
	timerNextParasite:Start(-delay)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 376251 then
		timerParasite:Start(args.destName)
		if args:IsPlayer() then
			specWarnParasite:Show()
			specWarnParasite:Play("targetyou")
			yellParasiteFades:Countdown(spellId)
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(30)
			end
		else
			warnParasite:Show(args.destName)
		end
		if self.Options.ParasiteIcon then
			self:SetIcon(args.destName, 8)
		end
	elseif spellId == 376244 then
		self.vb.shearStacks = 1
	elseif spellId == 376285 then
		self.vb.inDemonForm = true
		warnDemon:Show()
		timerDemonForm:Start()
		timerNextCleave:Cancel()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	local spellId = args.spellId
	if spellId == 376244 then
		self.vb.shearStacks = args.amount or (self.vb.shearStacks + 1)
		if self.vb.shearStacks >= 2 then
			specWarnShear:Show(args.destName)
			specWarnShear:Play("taunt")
		end
	elseif spellId == 376248 then
		self.vb.demonicFury = args.amount or (self.vb.demonicFury + 1)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 376251 then
		timerParasite:Stop(args.destName)
		if args:IsPlayer() then
			yellParasiteFades:Cancel()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Hide()
			end
		end
		if self.Options.ParasiteIcon then
			self:RemoveIcon(args.destName)
		end
	elseif spellId == 376244 then
		self.vb.shearStacks = 0
	elseif spellId == 376285 then
		self.vb.inDemonForm = false
		warnHuman:Show()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 376243 then
		timerNextCleave:Start()
	elseif spellId == 376245 then
		self.vb.flameCrashCount = self.vb.flameCrashCount + 1
		if self.vb.flameCrashCount > 3 then
			self.vb.flameCrashCount = 1
		end
		local nextCount = self.vb.flameCrashCount + 1
		if nextCount > 3 then
			nextCount = 1
		end
		timerNextFlameCrash:Start(nil, nextCount)
	elseif spellId == 376249 then
		timerNextDrawSoul:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 376250 then
		timerNextParasite:Start()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == CID_DARK_FLAME or cid == CID_CORRUPT_FLAME then
		self.vb.addsKilled[cid] = true
		if self.vb.addsKilled[CID_DARK_FLAME] and self.vb.addsKilled[CID_CORRUPT_FLAME] then
			self:SetStage(3)
			warnPhase3:Show()
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Pull or msg:find(L.Pull) then
		timerCombatStart:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	local cid = self:GetUnitCreatureId(uId)
	if not cid or cid ~= 22917 then return end
	local pct = UnitHealth(uId) / UnitHealthMax(uId)

	if not self.vb.warned_preP2 and pct <= 0.70 then
		self.vb.warned_preP2 = true
		warnPhase2Soon:Show()
		local targets = getTopThreatTargets(5)
		if #targets > 0 then
			warnBombardment:Show(table.concat(targets, ", "))
		end
	end
	if self.vb.phase < 2 and pct <= 0.67 then
		self:SetStage(2)
		warnPhase2:Show()
		timerNextCleave:Cancel()
		timerNextFlameCrash:Cancel()
		timerNextDrawSoul:Cancel()
		timerNextParasite:Cancel()
	end
end
