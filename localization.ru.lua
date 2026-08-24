if GetLocale() ~= "ruRU" then return end
local L

-----------------
--  Najentus  --
-----------------
L = DBM:GetModLocalization("Najentus")

L:SetGeneralLocalization({
	name = "Верховный Полководец Надж'ентус"
})

L:SetOptionLocalization({
	RangeFrame = "Show range frame (10)" --Translate
})

----------------
-- Supremus --
----------------
L = DBM:GetModLocalization("Supremus")

L:SetGeneralLocalization({
	name = "Супремус"
})

L:SetWarningLocalization({
	WarnPhase     = "%s Phase",    --Translate
	WarnPhaseSoon = "%s Phase in 10", --Translate
	WarnKite      = "Gaze on >%s<" --Translate
})

L:SetTimerLocalization({
	TimerPhase = "Next %s phase" --Translate
})

L:SetOptionLocalization({
	WarnPhase     = "Show warning for next phase",                   --Translate
	WarnPhaseSoon = "Show pre-warning for next phase",               --Translate
	WarnKite      = "Announce Kite targets",                         --Translate
	TimerPhase    = "Show time for next phase",                      --Translate
	KiteIcon      = "Set icon on Kite target",                       --Translate
	KiteWhisper   = "Send whisper to Kite target (requires Raid Leader)" --Translate
})

L:SetMiscLocalization({
	PhaseTank    = "в гневе ударяет по земле!", --Check if Backwards
	PhaseKite    = "Земля начинает раскалываться!", --Check if Backwards
	ChangeTarget = "атакует новую цель!",
	Kite         = "Kite", --Translate
	Tank         = "Tank" --Translate
})

-------------------------
--  Shape of Akama  --
-------------------------
L = DBM:GetModLocalization("Akama")

L:SetGeneralLocalization({
	name = "Тень Акамы"
})

L:SetWarningLocalization({
	WeaponsStatus = "Cнятие оружий включено"
})

L:SetOptionLocalization({
	EqUneqWeapons =
	"Снимать/надевать оружия если в вас кастанулся контроль. Для надевания создайте компл. экип. 'pve'. Для снятия не нужен.",
	EqUneqTimer   = "Снимать оружия по таймеру ВСЕГДА, а не в каст(если высокий пинг). Опция выше должна быть вкл.",
	BlockWeapons  = "Полностью заблокировать функции снятия/надевания выше",
	RaidSay       = "Оповещение о несбитом касте в Рейд чат"
})

L:SetMiscLocalization({
	SummonPepel = "Один из Пеплоустов-чаротворцев выходит из транса и вступает в бой!",
	Groz        = "Пеплоуст-грозоборец",
	Ciao        = "Пеплоуст-чаротворец",
	Dusha       = "Пеплоуст-душелов",
	CrisaTH     = "Пеплоуст-разбойник",
	GigaChad    = "Пеплоуст-защитник",
	YellKill    = "Сломленные из племени Пеплоустов, ваш предводитель говорит!"
})

-------------------------
--  Teron Gorefiend  --
-------------------------
L = DBM:GetModLocalization("TeronGorefiend")

L:SetGeneralLocalization({
	name = "Терон Кровожад"
})

L:SetTimerLocalization({
	TimerVengefulSpirit = "Ghost : %s" --Translate
})

L:SetOptionLocalization({
	TimerVengefulSpirit = "Show timer for Ghost durations", --Translate
	RaidTimer           = "Таймер для всего рейда о начале боя и фазах"
})

L:SetMiscLocalization({
	CamStart =
	"Я был первым. Колесо моей жизни сделало уже не один оборот. Столько времени прошло... Мне нужно столько наверстать."
})
----------------------------
--  Gurtogg Bloodboil  --
----------------------------
L = DBM:GetModLocalization("Bloodboil")

L:SetGeneralLocalization({
	name = "Гуртогг Кипящая Кровь"
})

L:SetWarningLocalization({
	WarnRageEnd = "Fel Rage End", --Translate
})

L:SetTimerLocalization({
	TimerRageEnd = "Fel Rage End" --Translate
})

L:SetOptionLocalization({
	WarnRageEnd  = "Show warning for $spell:40604 ends", --Translate
	TimerRageEnd = "Show timer for $spell:40604 ends" --Translate
})

--------------------------
--  Essence Of Souls  --
--------------------------
L = DBM:GetModLocalization("Souls")

L:SetGeneralLocalization({
	name = "Воплощение Душ"
})

L:SetWarningLocalization({
	WarnEnrage     = "Озверение",
	WarnEnrageSoon = "Озверение скоро",
	WarnEnrageEnd  = "Озверение закончилось",
	WarnMana       = "Ноль маны через 30 сек"
})

L:SetTimerLocalization({
	TimerEnrage     = "Озверение",
	TimerNextEnrage = "Next Озверение", --Translate
	TimerMana       = "Mana 0" --Translate
})

L:SetOptionLocalization({
	WarnEnrage      = "Show warning for Enrage",                              --Translate
	WarnEnrageSoon  = "Show pre-warning for Enrage",                          --Translate
	WarnEnrageEnd   = "Show warning when Enrage ends",                        --Translate
	WarnMana        = "Show warning from zero mana in Phase 2",               --Translate
	TimerEnrage     = "Show timer for Enrage",                                --Translate
	TimerNextEnrage = "Show timer for next Enrage",                           --Translate
	TimerMana       = "Show timer for zero mana in Phase 2",                  --Translate
	SpiteWhisper    = "Send whisper to $spell:41376 targets (requires Raid Leader)" --Translate
})

L:SetMiscLocalization({
	Enrage       = "%s впадает в ярость!",
	SpiteWhisper = "Злоба на Вас!",
	Suffering    = "Воплощение Страдания", --Translate
	Desire       = "Воплощение Желания", --Translate
	Anger        = "Воплощение Гнева" --Translate
})

-----------------------
--  Mother Shahraz --
-----------------------
L = DBM:GetModLocalization("Shahraz")

L:SetGeneralLocalization({
	name = "Матушка Шахраз"
})

L:SetWarningLocalization({
	["Фаза мобов!"] = "Фаза мобов!",
	["Наказание!"]  = "Наказание!",
	["СБЕГИСЬ"]     = "СБЕГИСЬ",
	["РАЗБЕГИСЬ"]   = "РАЗБЕГИСЬ"
})

----------------------
--  Illidari Council  --
----------------------
L = DBM:GetModLocalization("Council")

L:SetGeneralLocalization({
	name = "Совет Иллидари"
})

L:SetWarningLocalization({
	WarnFadeSoon = "Vanish fades in 5 sec",   --Translate
	WarnFaded    = "Vanish faded",            --Translate
	WarnDevAura  = "Devotion Aura for 30 sec", --Translate
	WarnResAura  = "Resistance Aura for 30 sec", --Translate
	Immune       = "Malande - %s immune for 15 sec" --Translate
})

L:SetOptionLocalization({
	WarnFadeSoon = "Show warning 5 seconds before $spell:41476 fades", --Translate
	WarnFaded    = "Show warning when $spell:41476 fades",            --Translate
	WarnDevAura  = "Show warning for $spell:41452",                   --Translate
	WarnResAura  = "Show warning for $spell:41453",                   --Translate
	Immune       = "Show warning when Manalde becomes spell or melee immune" --Translate
})

L:SetMiscLocalization({
	Gathios       = "Гатиос Изувер",
	Malande       = "Леди Маланда",
	Zerevor       = "Верховный пустомант Зеревор",
	Veras         = "Верас Глубокий Мрак",
	Melee         = "Melee",             --Translate
	Spell         = "Spell",             --Translate
	PoisonWhisper = "Deadly Poison on you!" --Translate
})

-------------------------
--  Illidan Stormrage --
-------------------------
L = DBM:GetModLocalization("Illidan")

L:SetGeneralLocalization({
	name = "Иллидан Ярость Бури"
})

L:SetWarningLocalization({
	WarnHuman      = "Обычная Фаза",
	WarnBombardment = "Обстрел скверны, вероятные цели: %s",
	SpecWarnPhase2 = "Фаза 2 началась!",
	SpecWarnPierce = "Скоро взгляд!" --TODO: уточнить формулировку
})

L:SetTimerLocalization({
	FlameCrashCount  = "Падение пламени #%d",
	ShearCount       = "Срез #%d"
})

L:SetOptionLocalization({
	WarnHuman        = "Показывать предупреждение об окончании демон-формы",
	WarnBombardment  = "Показывать вероятные цели обстрела скверны перед 2 фазой",
	SpecWarnPhase2   = "Показывать спецпредупреждение о начале 2 фазы",
	SpecWarnPierce   = "Показывать спецпредупреждение о приближении взгляда",
	RangeFrame       = "Показывать радар (30 ярдов) пока висят Паразитические исчадия",
	SpacingRadar     = "Показывать радар для соблюдения дистанции (7/8/8 ярдов по фазам)"
})

L:SetMiscLocalization({
	Pull            = "Акама. Я не удивлен твоей двуличностью. Давно нужно было убить тебя и твоих мерзких прихвостней."
})
