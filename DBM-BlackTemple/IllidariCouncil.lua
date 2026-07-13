local mod	= DBM:NewMod("Council", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260713000000")
mod:SetCreatureID(22949, 22950, 22951, 22952)

mod:SetModelID(21416)
mod:SetUsedIcons(1)

mod:RegisterCombat("combat")

-- ===================== Spell ID (кастомные, с вашего сервера) =====================
local SPELL_HAMMER			= 376217 -- Молот правосудия (Гатиос) - стан
local SPELL_BLIZZARD		= 376228 -- Буран (каст, Зеревор)
local SPELL_BLIZZARD_DOT	= 376230 -- Буран (тик урона по игрокам, стоящим в зоне)
local SPELL_LIVINGBOMB		= 376223 -- Живая бомба (Зеревор)
local SPELL_WEAKENMAGIC	= 376231 -- Ослабление магии (Зеревор, бафф на себя)
local SPELL_RENEW			= 376234 -- Высшее обновление (Маланда, хил на весь Совет)
local SPELL_POISON			= 376240 -- Смертельный яд (Верас, стакающийся дебафф на рейде)
local SPELL_PRAYER			= 376235 -- Молитва исцеления (Маланда, хил на весь Совет) - НЕ фикс. КД, условный каст
local SPELL_FANOFKNIVES	= 376238 -- Веер клинков (Верас) - урон по рейду по площади
local SPELL_BLOODJUDGMENT	= 376218 -- Правосудие крови (Гатиос) - стакающийся дот на танка

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS " .. SPELL_HAMMER .. " " .. SPELL_BLIZZARD .. " " .. SPELL_WEAKENMAGIC .. " " .. SPELL_RENEW,
	"SPELL_CAST_START " .. SPELL_PRAYER .. " " .. SPELL_FANOFKNIVES .. " " .. SPELL_BLOODJUDGMENT,
	"SPELL_AURA_APPLIED " .. SPELL_LIVINGBOMB .. " " .. SPELL_BLIZZARD_DOT .. " " .. SPELL_POISON,
	"SPELL_AURA_APPLIED_DOSE " .. SPELL_POISON,
	"SPELL_AURA_REMOVED " .. SPELL_LIVINGBOMB .. " " .. SPELL_POISON,
	"SPELL_AURA_REMOVED_DOSE " .. SPELL_POISON,
	"SPELL_PERIODIC_DAMAGE " .. SPELL_BLIZZARD_DOT
)

-- ===================== Предупреждения =====================
local warnLivingBombYou	= mod:NewSpecialWarningYou(SPELL_LIVINGBOMB, nil, nil, nil, 1, 2)
local warnLivingBombTarget	= mod:NewTargetNoFilterAnnounce(SPELL_LIVINGBOMB, 2, nil, nil, 3)
local warnBlizzardYou		= mod:NewSpecialWarningYou(SPELL_BLIZZARD_DOT, nil, nil, nil, 1, 2)

-- ===================== Таймеры (CD-бары) =====================
local timerHammer		= mod:NewCDTimer(20, SPELL_HAMMER, nil, nil, nil, 5)
local timerBlizzard		= mod:NewCDTimer(16.5, SPELL_BLIZZARD, nil, nil, nil, 4, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerLivingBomb		= mod:NewCDTimer(15.7, SPELL_LIVINGBOMB, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerWeakenMagic		= mod:NewCDTimer(15.7, SPELL_WEAKENMAGIC, nil, nil, nil, 2)
local timerRenew		= mod:NewCDTimer(6.1, SPELL_RENEW, nil, nil, nil, 1, nil, DBM_COMMON_L.HEALER_ICON)
local timerFanOfKnives	= mod:NewCDTimer(6.5, SPELL_FANOFKNIVES, nil, nil, nil, 6, nil, DBM_COMMON_L.DAMAGE_ICON)
-- Молитва исцеления: не фикс. КД, кастуется по условию (скорее всего % хп боссов).
-- Таймер показывает МИНИМАЛЬНЫЙ откат (~16.5 сек) - раньше точно не будет, но может быть позже.
local timerPrayer		= mod:NewCDTimer(16.5, SPELL_PRAYER, nil, nil, nil, 7, nil, DBM_COMMON_L.INTERRUPT_ICON)
-- Правосудие крови: первый каст +10 сек, второй +23 сек (интервал 13 сек), дальше стабильно ~11 сек
local timerBloodJudgment	= mod:NewCDTimer(11, SPELL_BLOODJUDGMENT, nil, nil, nil, 8)

local berserkTimer		= mod:NewBerserkTimer(600) -- 10 минут

mod:AddSetIconOption("LivingBombIcon", SPELL_LIVINGBOMB)
mod:AddInfoFrameOption() -- инфо-фрейм DBM для стаков Смертельного яда (свой тумблер/позиция уже встроены)

-- ===================== Таблица стаков "Смертельного яда" (через InfoFrame DBM) =====================
local poisonStacks = {}

local function PoisonColor(stack)
	if stack >= 5 then
		return 1, 0.2, 0.2 -- красный
	elseif stack >= 3 then
		return 1, 0.65, 0 -- оранжевый
	else
		return 1, 1, 0 -- жёлтый
	end
end

local function PoisonSetStack(self, name, stack)
	poisonStacks[name] = stack
	local r, g, b = PoisonColor(stack)
	self.infoFrame:AddLine(name, tostring(stack), r, g, b)
end

local function PoisonRemove(self, name)
	poisonStacks[name] = nil
	self.infoFrame:RemoveLine(name)
end

local function PoisonReset(self)
	wipe(poisonStacks)
	self.infoFrame:Hide()
end

-- ===================== События =====================

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	timerHammer:Start(20 - delay)
	timerBlizzard:Start(16.1 - delay)
	timerLivingBomb:Start(16.1 - delay)
	timerWeakenMagic:Start(0.1 - delay)
	timerRenew:Start(6 - delay)
	timerPrayer:Start(15 - delay)
	timerBloodJudgment:Start(10 - delay)
	PoisonReset(self)
	if self.Options.InfoFrame then
		self.infoFrame:Show()
		self.infoFrame:SetHeader(L.PoisonHeader or "Смертельный яд")
	end
end

function mod:OnCombatEnd()
	PoisonReset(self)
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == SPELL_HAMMER then
		timerHammer:Start()
	elseif spellId == SPELL_BLIZZARD then
		timerBlizzard:Start()
	elseif spellId == SPELL_WEAKENMAGIC then
		timerWeakenMagic:Start()
	elseif spellId == SPELL_RENEW then
		timerRenew:Start()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == SPELL_PRAYER then
		timerPrayer:Start()
	elseif spellId == SPELL_FANOFKNIVES then
		timerFanOfKnives:Start()
	elseif spellId == SPELL_BLOODJUDGMENT then
		timerBloodJudgment:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == SPELL_LIVINGBOMB then
		timerLivingBomb:Start()
		warnLivingBombTarget:Show(args.destName)
		if self.Options.LivingBombIcon then
			self:SetIcon(args.destName, 8)
		end
		if args:IsPlayer() then
			warnLivingBombYou:Show()
			warnLivingBombYou:Play("warning")
		end
	elseif spellId == SPELL_BLIZZARD_DOT then
		if args:IsPlayer() and self:AntiSpam(3, 1) then
			warnBlizzardYou:Show()
			warnBlizzardYou:Play("runaway")
		end
	elseif spellId == SPELL_POISON then
		PoisonSetStack(self, args.destName, 1)
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args.spellId == SPELL_POISON then
		PoisonSetStack(self, args.destName, args.amount or 1)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == SPELL_LIVINGBOMB then
		if self.Options.LivingBombIcon then
			self:RemoveIcon(args.destName)
		end
	elseif spellId == SPELL_POISON then
		PoisonRemove(self, args.destName)
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	if args.spellId == SPELL_POISON then
		PoisonSetStack(self, args.destName, args.amount or 0)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(args)
	if args.spellId == SPELL_BLIZZARD_DOT and args:IsPlayer() and self:AntiSpam(3, 1) then
		warnBlizzardYou:Show()
		warnBlizzardYou:Play("runaway")
	end
end
