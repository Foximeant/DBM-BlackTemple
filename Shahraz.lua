local mod = DBM:NewMod("Shahraz", "DBM-BlackTemple")
local L = mod:GetLocalizedStrings()

mod:SetRevision("2026070101")
mod:SetCreatureID(22947)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 374706 374699 374696",
	"SPELL_AURA_APPLIED 374693 374707 374701 374690 374623",
	"SPELL_AURA_APPLIED_DOSE 374690",
	"SPELL_AURA_REMOVED 374619 374693 374707 374701 374623"
)

mod:AddBoolOption("DebugMode", false)
mod:AddInfoFrameOption(374690)
mod:AddRangeFrameOption(8)

local PassionBuff = DBM:GetSpellInfo(374690)
local specWarnPassion = mod:NewSpecialWarningStack(374690, nil, 70, nil, nil, 1, 3)
local specWarnPhaseMobs = mod:NewSpecialWarning("Фаза мобов!", nil, nil, nil, 1, 2)
local timerBossPhase = mod:NewPhaseTimer(120, nil, "Фаза мобов", nil, nil, 3)

local wishTargets = {}
local warnWish = mod:NewTargetNoFilterAnnounce(374693, 4)
local specWish = mod:NewSpecialWarningYou(374693, nil, nil, nil, 1, 2)
local yellWish = mod:NewYell(374693)
local timerWish = mod:NewCDTimer(40, 374693, nil, nil, nil, 3)

local doomTargets = {}
local warnDoom = mod:NewTargetNoFilterAnnounce(374707, 4)
local specDoom = mod:NewSpecialWarning("СБЕГИСЬ", nil, nil, nil, 1, 2, nil, nil, 374707)
local yellDoom = mod:NewYell(374707)
local timerDoom = mod:NewCDTimer(40, 374707, nil, nil, nil, 3)

local gripTargets = {}
local warnGrip = mod:NewTargetNoFilterAnnounce(374701, 4)
local specGrip = mod:NewSpecialWarning("РАЗБЕГИСЬ", nil, nil, nil, 1, 2, nil, nil, 374701)
local yellGrip = mod:NewYell(374701)
local timerGrip = mod:NewCDTimer(40, 374701, nil, nil, nil, 3)

local specWarnPunishment = mod:NewSpecialWarning("Наказание!", nil, nil, nil, 1, 2)
local timerPunishment = mod:NewCDTimer(40, 374696, "PunishmentCount", nil, nil, 3)

local specWarnPain = mod:NewSpecialWarningYou(374623, nil, nil, nil, 1, 2)

mod:AddSetIconOption("SetIconOnMistressWish", 374693, true, true, {8,7})
mod:AddSetIconOption("SetIconOnDoomLink", 374707, true, true, {1,2,3})
mod:AddSetIconOption("SetIconOnDeathGrip", 374701, true, true, {4,5,6})

local function classColorName(name)
	local _, class = UnitClass(name)
	local color = class and RAID_CLASS_COLORS[class]
	if color then
		return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
	end
	return name
end

local function hideRangeFrame()
	DBM.RangeCheck:Hide()
end

local showWish, showDoom, showGrip

local function resetPhaseState(self)
	table.wipe(wishTargets)
	table.wipe(doomTargets)
	table.wipe(gripTargets)

	self.vb.wishIcon = 8
	self.vb.linkScheduled = false
	self.vb.gripScheduled = false

	self:Unschedule(showWish)
	self:Unschedule(showDoom)
	self:Unschedule(showGrip)
	self:Unschedule(hideRangeFrame)

	timerWish:Stop()
	timerDoom:Stop()
	timerGrip:Stop()
end

showWish = function()
	if #wishTargets > 0 then
		local colored = {}
		for i, name in ipairs(wishTargets) do
			colored[i] = classColorName(name)
		end
		warnWish:Show(table.concat(colored, ", "))
		table.wipe(wishTargets)
	end
end

showDoom = function()
	if #doomTargets > 0 then
		warnDoom:Show(table.concat(doomTargets, ", "))
		table.wipe(doomTargets)
		mod.vb.linkScheduled = false
	end
end

showGrip = function()
	if #gripTargets > 0 then
		warnGrip:Show(table.concat(gripTargets, ", "))
		table.wipe(gripTargets)
		mod.vb.gripScheduled = false
	end
end

mod.vb.phase = 0
mod.vb.punishmentCount = 0
mod.vb.wishIcon = 8
mod.vb.linkScheduled = false
mod.vb.gripScheduled = false

function mod:OnCombatStart()
	self.vb.phase = 0
	self.vb.punishmentCount = 0
	resetPhaseState(self)

	if self.Options.InfoFrame and DBM.InfoFrame then
		DBM.InfoFrame:SetHeader(PassionBuff)
		DBM.InfoFrame:Show(30, "playerdebuffstacks", PassionBuff, 2)
	end
end

function mod:OnCombatEnd()
	if DBM.InfoFrame then DBM.InfoFrame:Hide() end
	DBM.RangeCheck:Hide()
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 374693 then
		if #wishTargets == 0 then
			timerWish:Start(35)
		end

		table.insert(wishTargets, args.destName)

		if self.Options.SetIconOnMistressWish then
			self:SetIcon(args.destName, self.vb.wishIcon)
			self.vb.wishIcon = (self.vb.wishIcon == 8) and 7 or 8
		end

		if UnitIsUnit(args.destName, "player") then
			specWish:Show()
			specWish:Play("targetyou")
			yellWish:Yell()
		end

		self:Unschedule(showWish)
		if #wishTargets >= 2 then
			showWish()
		else
			self:Schedule(0.3, showWish)
		end

	elseif args.spellId == 374707 then
		if not self.vb.linkScheduled then
			table.wipe(doomTargets)
			timerDoom:Start(40)
			self.vb.linkScheduled = true
			self:Unschedule(showDoom)
			self:Schedule(0.4, showDoom)
		end

		table.insert(doomTargets, args.destName)

		if self.Options.SetIconOnDoomLink then
			self:SetIcon(args.destName, #doomTargets)
		end

		if UnitIsUnit(args.destName, "player") then
			specDoom:Show()
			specDoom:Play("gathershare")
			yellDoom:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(8)
				self:Unschedule(hideRangeFrame)
				self:Schedule(6, hideRangeFrame)
			end
		end

	elseif args.spellId == 374701 then
		if not self.vb.gripScheduled then
			table.wipe(gripTargets)
			timerGrip:Start(40)
			self.vb.gripScheduled = true
			self:Unschedule(showGrip)
			self:Schedule(0.4, showGrip)
		end

		table.insert(gripTargets, args.destName)

		if self.Options.SetIconOnDeathGrip then
			self:SetIcon(args.destName, #gripTargets + 3)
		end

		if UnitIsUnit(args.destName, "player") then
			specGrip:Show()
			specGrip:Play("gathershare")
			yellGrip:Yell()
		end

	elseif args.spellId == 374690 then
		if args:IsPlayer() then
			if ((args.amount or 1) >= 70) and self:AntiSpam(5, 3) then
				specWarnPassion:Show(args.amount)
			end
		end

	elseif args.spellId == 374623 then
		if UnitIsUnit(args.destName, "player") then
			specWarnPain:Show()
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 374619 then
		self.vb.phase = 2
		resetPhaseState(self)
		timerWish:Start(17)
		timerDoom:Start(37)
		timerGrip:Start(12)
		timerPunishment:Start(21)
		timerBossPhase:Start()

	elseif args.spellId == 374623 then
		self.vb.phase = 1
		resetPhaseState(self)
		timerBossPhase:Stop()
		specWarnPhaseMobs:Show()

	elseif args.spellId == 374693 and self.Options.SetIconOnMistressWish then
		self:RemoveIcon(args.destName)
	elseif args.spellId == 374707 and self.Options.SetIconOnDoomLink then
		self:RemoveIcon(args.destName)
	elseif args.spellId == 374701 and self.Options.SetIconOnDeathGrip then
		self:RemoveIcon(args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 374706 then
		table.wipe(doomTargets)
		timerDoom:Start(40)
		self.vb.linkScheduled = true
		self:Unschedule(showDoom)
		self:Schedule(1.6, showDoom)

	elseif args.spellId == 374699 then
		table.wipe(gripTargets)
		timerGrip:Start(40)
		self.vb.gripScheduled = true
		self:Unschedule(showGrip)
		self:Schedule(1.6, showGrip)

	elseif args.spellId == 374696 then
		self.vb.punishmentCount = self.vb.punishmentCount + 1
		if self.vb.punishmentCount > 3 then
			self.vb.punishmentCount = 1
		end
		local nextCount = self.vb.punishmentCount + 1
		if nextCount > 3 then
			nextCount = 1
		end
		timerPunishment:Start(40, nextCount)
		specWarnPunishment:Show()
	end
end
