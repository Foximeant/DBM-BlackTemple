local mod	= DBM:NewMod("Illidan", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()
local LibGroupTalents = LibStub("LibGroupTalents-1.0", true)

mod:SetRevision("20260729000000")
mod:SetCreatureID(22917)

mod:SetModelID(21135)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 376244 376251 376259 376261 376285",
	"SPELL_AURA_APPLIED_DOSE 376244 376248 376259",
	"SPELL_AURA_REMOVED 376244 376251 376259 376261 376285",
	"SPELL_CAST_START 376243 376245 376249",
	"SPELL_CAST_SUCCESS 376250",
	"SPELL_DAMAGE 376262",
	"UNIT_HEALTH boss1"
)

local warnParasite		= mod:NewTargetAnnounce(376251, 3)

local warnPhase2Soon	= mod:NewPrePhaseAnnounce(2, 3)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnPhase3		= mod:NewPhaseAnnounce(3)
local warnDemon			= mod:NewSpellAnnounce(376285, 3)
local warnHuman			= mod:NewAnnounce("WarnHuman", 3)
local warnBombardment	= mod:NewAnnounce("WarnBombardment", 3)

local warnPierce		= mod:NewTargetAnnounce(376261, 3)

local specWarnParasite		= mod:NewSpecialWarningYou(376251, nil, nil, nil, 1, 2)
local yellParasiteFades		= mod:NewShortFadesYell(376251)
local specWarnShear			= mod:NewSpecialWarningTaunt(376244, nil, nil, nil, 1, 2)
local specWarnPhase2		= mod:NewSpecialWarning("SpecWarnPhase2", nil, nil, nil, 1, 2)
local specWarnPierce		= mod:NewSpecialWarning("SpecWarnPierce", nil, nil, nil, 1, 2)
local specWarnPierceYou		= mod:NewSpecialWarningYou(376261, nil, nil, nil, 1, 2)
local specWarnPierceGTFO	= mod:NewSpecialWarningGTFO(376262, nil, nil, nil, 1, 2)

local timerPierce		= mod:NewTargetTimer(10, 376261, nil, nil, nil, 3)

local timerParasite		= mod:NewTargetTimer(10, 376251, nil, false, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerNextParasite	= mod:NewCDTimer(60, 376250, nil, nil, nil, 1)
local timerNextCleave	= mod:NewCDTimer(8.5, 376243, "ShearCount", nil, nil, 2)
local timerNextFlameCrash	= mod:NewCDTimer(13.5, 376245, "FlameCrashCount", nil, nil, 3)
local timerNextDrawSoul	= mod:NewCDTimer(23, 376249, nil, nil, nil, 3)
local timerDemonForm	= mod:NewBuffActiveTimer(75, 376285, nil, nil, nil, 4)

local timerCombatStart	= mod:NewCombatTimer(38)
local berserkTimer		= mod:NewBerserkTimer(720)

mod:AddSetIconOption("ParasiteIcon", 376251)
mod:AddRangeFrameOption(30, 376251)
mod:AddBoolOption("SpacingRadar", true, "misc")
mod:GroupSpells(376251, 376250)
mod:GroupSpells(376244, 376243)

-- Radar spacing distance per phase (independent mechanic from parasite carrier range check)
local spacingRangeByPhase = {
	[1] = 7,
	[2] = 8,
	[3] = 8,
}

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

local function classColorName(unit, name)
	local _, class = UnitClass(unit)
	local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if color then
		local hex = color.colorStr or string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
		return "|c"..hex..name.."|r"
	end
	return name
end

local function isExcludedRole(unit)
	if LibGroupTalents then
		local role = LibGroupTalents:GetUnitRole(unit)
		if role == "melee" or role == "tank" then
			return true
		end
	end
	return false
end

local function getTopThreatTargets(n)
	local list = {}
	for _, unit in ipairs(getRaidUnits()) do
		if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			local name = UnitName(unit)
			if name and not isExcludedRole(unit) then
				local isTanking, _, _, _, threatValue = UnitDetailedThreatSituation(unit, "boss1")
				if threatValue and not isTanking then
					list[#list + 1] = { name = name, threat = threatValue, unit = unit }
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.threat > b.threat end)
	local names = {}
	for i = 1, math.min(n, #list) do
		names[#names + 1] = classColorName(list[i].unit, list[i].name)
	end
	return names
end

mod.vb.shearStacks = 0
mod.vb.shearCount = 0
mod.vb.demonicFury = 0
mod.vb.flameCrashCount = 0
mod.vb.corruptionStacks = 0
mod.vb.warned_preP2 = false
mod.vb.inDemonForm = false
mod.vb.parasiteCarrier = false

-- Single shared DBM.RangeCheck frame: parasite carrier range (30yd) takes priority while active,
-- otherwise fall back to the phase-based spacing radar. Never Hide() unconditionally mid-combat
-- or it will kill whichever of the two is currently relying on the frame.
function mod:UpdateRangeDisplay()
	if self.vb.parasiteCarrier and self.Options.RangeFrame then
		DBM.RangeCheck:Show(30)
	elseif self.Options.SpacingRadar and self.vb.phase and self.vb.phase >= 1 then
		DBM.RangeCheck:Show(spacingRangeByPhase[self.vb.phase] or 8)
	else
		DBM.RangeCheck:Hide()
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.shearStacks = 0
	self.vb.shearCount = 0
	self.vb.demonicFury = 0
	self.vb.flameCrashCount = 0
	self.vb.corruptionStacks = 0
	self.vb.warned_preP2 = false
	self.vb.inDemonForm = false
	self.vb.parasiteCarrier = false
	berserkTimer:Start(-delay)
	timerNextDrawSoul:Start(20 - delay)
	timerNextParasite:Start(-delay)
	self:UpdateRangeDisplay()
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	DBM.RangeCheck:Hide()
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 376251 then
		timerParasite:Start(args.destName)
		if args:IsPlayer() then
			specWarnParasite:Show()
			specWarnParasite:Play("targetyou")
			yellParasiteFades:Countdown(spellId)
			self.vb.parasiteCarrier = true
			self:UpdateRangeDisplay()
		else
			warnParasite:Show(args.destName)
		end
		if self.Options.ParasiteIcon then
			self:SetIcon(args.destName, 8)
		end
	elseif spellId == 376244 then
		self.vb.shearStacks = 1
	elseif spellId == 376259 then
		self.vb.corruptionStacks = 1
	elseif spellId == 376261 then
		self.vb.corruptionStacks = 0
		warnPierce:Show(args.destName)
		timerPierce:Start(args.destName)
		if args:IsPlayer() then
			specWarnPierceYou:Show()
			specWarnPierceYou:Play("runout")
		end
	elseif spellId == 376285 then
		self.vb.inDemonForm = true
		warnDemon:Show()
		timerDemonForm:Start()
		timerNextCleave:Cancel()
		timerNextFlameCrash:Start()
		timerNextDrawSoul:Start()
		timerNextParasite:Start(45)
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
	elseif spellId == 376259 then
		self.vb.corruptionStacks = args.amount or (self.vb.corruptionStacks + 1)
		if self.vb.corruptionStacks >= 95 then
			specWarnPierce:Show()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 376251 then
		timerParasite:Stop(args.destName)
		if args:IsPlayer() then
			yellParasiteFades:Cancel()
			self.vb.parasiteCarrier = false
			self:UpdateRangeDisplay()
		end
		if self.Options.ParasiteIcon then
			self:RemoveIcon(args.destName)
		end
	elseif spellId == 376244 then
		self.vb.shearStacks = 0
	elseif spellId == 376259 then
		self.vb.corruptionStacks = 0
	elseif spellId == 376261 then
		timerPierce:Stop(args.destName)
	elseif spellId == 376285 then
		self.vb.inDemonForm = false
		warnHuman:Show()
		timerNextFlameCrash:Start()
		timerNextDrawSoul:Start()
		timerNextParasite:Start(60)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 376243 then
		self.vb.shearCount = self.vb.shearCount + 1
		if self.vb.shearCount > 2 then
			self.vb.shearCount = 1
		end
		local nextCount = self.vb.shearCount + 1
		if nextCount > 2 then
			nextCount = 1
		end
		timerNextCleave:Start(nil, nextCount)
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
		timerNextParasite:Start(self.vb.inDemonForm and 45 or 60)
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if spellId == 376262 and destGUID == UnitGUID("player") and DBM:AntiSpam(2, "Pierce") then
		specWarnPierceGTFO:Show()
		specWarnPierceGTFO:Play("runaway")
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
	end
	if self.vb.phase < 2 and pct <= 0.68 then
		self:SetStage(2)
		warnPhase2:Show()
		specWarnPhase2:Show()
		timerNextCleave:Cancel()
		timerNextFlameCrash:Cancel()
		timerNextDrawSoul:Cancel()
		timerNextParasite:Cancel()
		self:UpdateRangeDisplay()
		self:Schedule(5, function()
			local targets = getTopThreatTargets(5)
			if #targets > 0 then
				warnBombardment:Show(table.concat(targets, ", "))
			end
		end)
	end
	if self.vb.phase < 3 and pct <= 0.67 then
		self:SetStage(3)
		warnPhase3:Show()
		timerNextCleave:Start()
		timerNextFlameCrash:Start()
		timerNextDrawSoul:Start()
		timerNextParasite:Start(60)
		self:UpdateRangeDisplay()
	end
end
