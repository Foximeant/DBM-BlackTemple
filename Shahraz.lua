local mod = DBM:NewMod("Shahraz", "DBM-BlackTemple")
local L = mod:GetLocalizedStrings()

mod:SetRevision("2026070101")
mod:SetCreatureID(22947)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 374619 374706 374699 374696",
	"SPELL_AURA_APPLIED 374693 374707 374701 374690 374623",
	"SPELL_AURA_APPLIED_DOSE 374690",
	"SPELL_AURA_REMOVED 374619 374693 374707 374701 374623"
)
-- 374706 = каст Doom Link, 374707 (+ парная 374708) = сама аура Doom Link, 374711 = периодический тик урона (НЕ аура!)
-- 374699 = каст Death Grip, 374701 (+ парная 374702) = сама аура Death Grip
-- 374623 = Нестерпимая боль на танке — её снятие означает, что фаза мобов уже началась
-- 374696 = каст Наказания (~4.2с), КД 40с считается от CAST_START (проверено по логу: интервал каст->каст стабилен ~40с,
--          при этом сама длительность каста гуляет сильнее — значит откат не привязан к завершению каста)

mod:AddBoolOption("DebugMode", false)
mod:AddInfoFrameOption(374690)
mod:AddRangeFrameOption(8)

local PassionBuff = DBM:GetSpellInfo(374690)
local specWarnPassion = mod:NewSpecialWarningStack(374690, nil, 70, nil, nil, 1, 3) -- предупреждение о большом стаке Страсти
local specWarnPhaseMobs = mod:NewSpecialWarning("Фаза мобов!", nil, nil, nil, 1, 2)
local timerBossPhase = mod:NewPhaseTimer(120, nil, "Фаза мобов", nil, nil, 3) -- полная длительность фазы босса; по логу вышло 125.5с, доверяем заявленным 120с

----------------------------------------------------
-- STATE
----------------------------------------------------
mod.vb.phase = 0

----------------------------------------------------
-- WISH
----------------------------------------------------
local wishTargets = {}
mod.vb.wishIcon = 8

local warnWish = mod:NewTargetNoFilterAnnounce(374693, 4)
local specWish = mod:NewSpecialWarningYou(374693, nil, nil, nil, 1, 2)
local yellWish = mod:NewYell(374693)
local timerWish = mod:NewCDTimer(40, 374693, nil, nil, nil, 3)
mod:AddSetIconOption("SetIconOnMistressWish", 374693, true, true, {8,7})

----------------------------------------------------
-- DOOM LINK
----------------------------------------------------
local doomTargets = {}
mod.vb.linkScheduled = false

local warnDoom = mod:NewTargetNoFilterAnnounce(374711, 4)
local specDoom = mod:NewSpecialWarningYou(374711, nil, nil, nil, 1, 2)
local yellDoom = mod:NewYell(374711)
local timerDoom = mod:NewCDTimer(40, 374711, nil, nil, nil, 3)
mod:AddSetIconOption("SetIconOnDoomLink", 374711, true, true, {1,2,3})

----------------------------------------------------
-- DEATH GRIP
----------------------------------------------------
local gripTargets = {}
mod.vb.gripScheduled = false

local warnGrip = mod:NewTargetNoFilterAnnounce(374701, 4)
local specGrip = mod:NewSpecialWarningYou(374701, nil, nil, nil, 1, 2)
local yellGrip = mod:NewYell(374701)
local timerGrip = mod:NewCDTimer(40, 374701, nil, nil, nil, 3)
mod:AddSetIconOption("SetIconOnDeathGrip", 374701, true, true, {4,5,6})

----------------------------------------------------
-- PUNISHMENT (НАКАЗАНИЕ)
----------------------------------------------------
local specWarnPunishment = mod:NewSpecialWarning("Наказание!", nil, nil, nil, 1, 2)
local timerPunishment     = mod:NewCDTimer(40, 374696, nil, nil, nil, 3)

----------------------------------------------------
-- НЕСТЕРПИМАЯ БОЛЬ
----------------------------------------------------
local specWarnPain = mod:NewSpecialWarningYou(374623, nil, nil, nil, 1, 2)

----------------------------------------------------
-- HELPERS
----------------------------------------------------
local function classColorName(name)
	local _, class = UnitClass(name)
	local color = class and RAID_CLASS_COLORS[class]
	if color then
		return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
	end
	return name
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

----------------------------------------------------
-- START / END
----------------------------------------------------
function mod:OnCombatStart()
	self.vb.phase = 0
	resetPhaseState(self)

	if self.Options.InfoFrame and DBM.InfoFrame then
		DBM.InfoFrame:SetHeader(PassionBuff)
		DBM.InfoFrame:Show(30, "playerdebuffstacks", PassionBuff, 2)
	end
end

function mod:OnCombatEnd()
	if DBM.InfoFrame then DBM.InfoFrame:Hide() end
	self:HideRangeFrame()
end

----------------------------------------------------
-- CAST START
----------------------------------------------------
function mod:SPELL_CAST_START(args)
	if args.spellId == 374706 then -- Doom Link
		table.wipe(doomTargets)
		timerDoom:Start(40)
		self.vb.linkScheduled = true
		self:Unschedule(showDoom)
		self:Schedule(1.6, showDoom) -- аура приходит ~1.05-1.1с после каста, буфер с запасом

	elseif args.spellId == 374699 then -- Death Grip
		table.wipe(gripTargets)
		timerGrip:Start(40)
		self.vb.gripScheduled = true
		self:Unschedule(showGrip)
		self:Schedule(1.6, showGrip)

	elseif args.spellId == 374696 then -- Наказание — КД считается от начала каста (проверено по логу)
		timerPunishment:Start(40)
		specWarnPunishment:Show()
	end
end

----------------------------------------------------
-- AURA REMOVED
----------------------------------------------------
function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 374619 then
		self.vb.phase = 2
		resetPhaseState(self)
		timerWish:Start(17)
		timerDoom:Start(37)
		timerGrip:Start(12)
		timerPunishment:Start(21)
		timerBossPhase:Start()

	elseif args.spellId == 374623 then -- Нестерпимая боль спала с танка -> фаза мобов уже началась
		self.vb.phase = 1
		resetPhaseState(self) -- останавливаем Wish/Doom/Grip — в фазе мобов босс их не кастует
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

----------------------------------------------------
-- AURA APPLIED
----------------------------------------------------
function mod:SPELL_AURA_APPLIED(args)
	------------------------------------------------
	-- WISH
	------------------------------------------------
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

	------------------------------------------------
	-- DOOM LINK
	------------------------------------------------
	elseif args.spellId == 374707 then
		if not self.vb.linkScheduled then
			-- fallback на случай, если SPELL_CAST_START (374706) не долетел
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
			specDoom:Show("СБЕГИСЬ")
			specDoom:Play("gathershare")
			yellDoom:Yell()
			self:ShowRangeFrame(8)
			self:Schedule(6, self.HideRangeFrame)
		end

	------------------------------------------------
	-- DEATH GRIP
	------------------------------------------------
	elseif args.spellId == 374701 then
		if not self.vb.gripScheduled then
			-- fallback на случай, если SPELL_CAST_START (374699) не долетел
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
			specGrip:Show("РАЗБЕГИСЬ")
			specGrip:Play("gathershare")
			yellGrip:Yell()
		end

	------------------------------------------------
	-- PASSION (СТРАСТЬ) — большой стак
	------------------------------------------------
	elseif args.spellId == 374690 then
		if args:IsPlayer() then
			if ((args.amount or 1) >= 70) and self:AntiSpam(5, 3) then
				specWarnPassion:Show(args.amount)
			end
		end

	------------------------------------------------
	-- НЕСТЕРПИМАЯ БОЛЬ
	------------------------------------------------
	elseif args.spellId == 374623 then
		if UnitIsUnit(args.destName, "player") then
			specWarnPain:Show()
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED