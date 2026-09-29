# MEGA PROMPT — BANDITS AI OVERHAUL (BAO / BAIO)

## 0. ГЛАВНОЕ ПРАВИЛО

Ты продолжаешь разработку существующего проекта **BanditsAIOverhaul (BAO / BAIO)** для **Project Zomboid Build 42.20+**.

Это НЕ новый проект.

Не переписывай существующие системы без необходимости.

Не создавай дубликаты уже существующих модулей.

Перед добавлением новой системы сначала проверь текущую архитектуру и существующие файлы.

Если нужный модуль уже существует — расширяй его, а не создавай второй вариант.

Если для изменения требуется несколько файлов — чётко перечисли каждый файл и дай **полный готовый код каждого изменяемого файла**, а не маленькие фрагменты, если это возможно.

Пользователь предпочитает:

* пошаговые инструкции;
* конкретные пути файлов;
* готовые команды PowerShell;
* полные Lua-файлы для замены;
* минимум абстрактных рассуждений;
* всегда указывать следующий конкретный шаг;
* не задавать лишние уточняющие вопросы, если информацию можно получить из проекта;
* если один модуль требует патча другого — прямо сказать, какой модуль патчить и дать его полный код;
* не останавливать развитие проекта из-за второстепенной отложенной ошибки;
* сначала проверять фактическую текущую архитектуру, а не предполагать её.

---

# 1. НАЗВАНИЕ ПРОЕКТА

**BanditsAIOverhaul**

Сокращения:

* BAO
* BAIO
* Bandits AI Overhaul

Основная идея:

Создать полностью собственную AI/NPC-систему для Project Zomboid, которая позволит создавать живых, самостоятельных NPC/бандитов, способных принимать решения, выполнять действия, взаимодействовать с миром, помнить события, иметь отношения, принадлежность к фракциям, специализации, цели и последствия своих действий.

BAO не должен быть простым набором скриптов «NPC появился → идёт за игроком».

Главная цель — построить полноценную AI-архитектуру.

---

# 2. ИГРА

Project Zomboid.

Целевая версия:

**Build 42.20+**

Разработка ведётся под современную ветку Build 42.

Не использовать старые Build 41 API без проверки совместимости.

Если нужна конкретная PZ API-функция, сначала желательно проверить реальные Build 42.20 примеры/vanilla/mod references.

---

# 3. ОСНОВНОЙ ПУТЬ ПРОЕКТА

Исходники:

```text
C:\Users\Vovan\Documents\BanditsAIOverhaul
```

Установленная копия мода:

```text
C:\Users\Vovan\Zomboid\mods\BanditsAIOverhaul
```

Основной тестовый сервер/мир ранее:

```text
servertestBanditsAIOverhaul
```

Git:

```text
Repository:
Balbec219/BanditsAIOverhaul

Branch:
main
```

Текущая ветка ранее была синхронизирована:

```text
main
origin/main
```

---

# 4. ОСНОВНАЯ ФИЛОСОФИЯ BAO

Ключевое отличие BAO от A-Life-подобных систем:

**A-Life симулирует живой мир.**

BAO должен в первую очередь:

> симулировать людей и последствия их решений.

Главная петля:

```text
WORLD
  ↓
NPC
  ↓
DECISION
  ↓
ACTION
  ↓
RESULT / CONSEQUENCE
  ↓
WORLD
  ↓
NPC
  ↓
...
```

То есть NPC не просто «существует».

NPC:

* воспринимает мир;
* получает контекст;
* имеет профиль;
* имеет личность;
* имеет способности;
* имеет потребности;
* принимает решение;
* превращает решение в действие;
* действие меняет мир;
* результат запоминается;
* следующий выбор учитывает прошлый опыт.

---

# 5. ОСНОВНАЯ ЦЕЛЬ AI

BAO должен постепенно прийти к системе, где NPC способен:

* самостоятельно выбирать задачи;
* оценивать угрозы;
* реагировать на изменения мира;
* вступать в бой;
* отступать;
* лечиться;
* искать ресурсы;
* охранять территорию;
* патрулировать;
* исследовать;
* помогать союзникам;
* взаимодействовать с фракцией;
* работать в группе;
* иметь отношения с другими NPC;
* запоминать события;
* адаптироваться;
* менять поведение на основании опыта;
* выполнять долгосрочные цели;
* создавать последствия, которые игрок может увидеть позже.

---

# 6. КЛЮЧЕВАЯ ИДЕЯ ЭМЕРДЖЕНТНОГО ГЕЙМПЛЕЯ

Игрок не обязательно должен присутствовать во время событий.

Например:

NPC могут:

* устроить бой;
* убить друг друга;
* оставить трупы;
* повредить базу;
* уничтожить ограждение;
* украсть транспорт;
* сломать транспорт;
* слить топливо;
* заманить орду зомби;
* совершить диверсию;
* уйти.

Игрок может прийти позже и увидеть:

```text
разрушенный лагерь
трупы
следы боя
пропавшие предметы
повреждённые автомобили
зомби
изменённую территорию
```

Таким образом мир должен ощущаться как место, где события происходят даже без игрока.

---

# 7. NPC — ОСНОВНАЯ ЕДИНИЦА СИСТЕМЫ

NPC должен постепенно получить:

```text
Identity
Profile
Role
Specialization
Personality
Capabilities
Needs
Behavior
Memory
Experience
Relationships
Goals
Faction
Squad
Routine
Awareness
Decision
Action
Movement
Navigation
Animation
```

---

# 8. РАЗНИЦА МЕЖДУ ДОКТРИНОЙ И ЛИЧНОСТЬЮ

Одна из ключевых идей BAO:

NPC должен находиться между:

```text
FACTION DOCTRINE
```

и

```text
INDIVIDUAL PERSONALITY
```

Например:

Фракция говорит:

```text
"Не отступать."
```

Но конкретный NPC:

* труслив;
* ранен;
* устал;
* имеет опыт предыдущего боя;
* считает командира плохим;
* имеет семью;
* имеет цель выжить.

Поэтому итоговое решение должно учитывать и коллективную доктрину, и индивидуальные характеристики.

---

# 9. ТЕКУЩАЯ АРХИТЕКТУРА

Концептуальная цепочка:

```text
PlayerProfile
      ↓
RoleScoring
      ↓
Specialization
      ↓
BehaviorProfile
      ↓
WorldContext
      ↓
DecisionSystem
      ↓
ActionSystem
      ↓
ActionExecutor
      ↓
AIController
      ↓
Navigation / Movement
      ↓
NPC
      ↓
World consequences
```

Дополнительные системы:

```text
RoutineSystem
      ↓
RoutineDecisionBridge
      ↓
DecisionSystem
```

Фракции:

```text
Faction
      ↓
Squad
      ↓
NPC
```

---

# 10. ТЕКУЩАЯ ФАКТИЧЕСКАЯ СТРУКТУРА ПРОЕКТА

Последний подтверждённый список файлов:

```text
BanditsAIOverhaul/
│
├── bao_file_list.txt
│
├── .github/
│   └── workflows/
│       └── discord-devlog.yml
│
├── .vscode/
│   └── settings.json
│
└── 42/
    │
    ├── mod.info
    │
    └── media/
        │
        └── lua/
            │
            ├── client/
            │   ├── BAO_DebugUI.lua
            │   └── BAO_PlayerDiagnostics.lua
            │
            ├── server/
            │   └── BAO_DebugServer.lua
            │
            └── shared/
                │
                ├── ai/
                │   ├── BAO_ActionExecutor.lua
                │   ├── BAO_ActionSystem.lua
                │   ├── BAO_AIController.lua
                │   ├── BAO_BehaviorProfile.lua
                │   ├── BAO_DecisionSystem.lua
                │   ├── BAO_PlayerProfile.lua
                │   ├── BAO_RoleScoring.lua
                │   ├── BAO_RoutineDecisionBridge.lua
                │   ├── BAO_Specialization.lua
                │   └── BAO_WorldContext.lua
                │
                ├── core/
                │   ├── BAO_Bootstrap.lua
                │   └── BAO_Test.lua
                │
                ├── faction/
                │   ├── BAO_Factions.lua
                │   └── BAO_Squads.lua
                │
                ├── navigation/
                │   └── BAO_NavigationSystem.lua
                │
                ├── npc/
                │   └── BAO_NPCData.lua
                │
                ├── routine/
                │   └── BAO_RoutineSystem.lua
                │
                └── tests/
                    ├── BAO_ActionExecutorTestHarness.lua
                    ├── BAO_ActionTestHarness.lua
                    ├── BAO_AIControllerTestHarness.lua
                    ├── BAO_AITestHarness.lua
                    ├── BAO_AI_TestHarness.lua
                    ├── BAO_FactionsTest.lua
                    ├── BAO_NavigationMovementTest.lua
                    ├── BAO_NavigationTestHarness.lua
                    ├── BAO_NPCDataTest.lua
                    ├── BAO_RoutineDecisionBridgeTestHarness.lua
                    ├── BAO_RoutineTestHarness.lua
                    └── BAO_SquadsTest.lua
```

ВАЖНО:

Наличие файла означает, что модуль уже существует.

Не создавать второй файл с аналогичным назначением.

---

# 11. PLAYER DIAGNOSTICS

Система:

```text
42/media/lua/client/BAO_PlayerDiagnostics.lua
```

Она использовалась для диагностики:

* OnCreatePlayer
* OnGameStart
* OnPlayerUpdate
* получения IsoPlayer
* ID игрока.

Ранее подтверждалось:

```text
IsoPlayer ID = 6
```

---

# 12. PLAYER PROFILE

Файл:

```text
42/media/lua/shared/ai/BAO_PlayerProfile.lua
```

Система PlayerProfile развивалась до V2.

Цель:

Извлекать характеристики игрока/NPC-подобного профиля для последующего определения роли и специализации.

---

# 13. ROLE SCORING

Файл:

```text
42/media/lua/shared/ai/BAO_RoleScoring.lua
```

Используется для определения естественной роли.

---

# 14. SPECIALIZATION

Файл:

```text
42/media/lua/shared/ai/BAO_Specialization.lua
```

Версия:

**V1.1**

Подтверждённый тестовый результат:

```text
NaturalRole = survival
NaturalSpecialization = wilderness_scout
SecondarySpecialization = survival_specialist
```

Также реализованы методы:

```text
GetPrimary()
GetSecondary()
GetNaturalRole()
GetNaturalSpecialization()
GetSecondarySpecialization()
```

---

# 15. BEHAVIOR PROFILE

Файл:

```text
42/media/lua/shared/ai/BAO_BehaviorProfile.lua
```

Версия:

**V1**

Подтверждено, что система создаёт:

```text
Personality
Capabilities
Tendencies
```

и тестировалась без Lua-ошибок.

---

# 16. WORLD CONTEXT

Файл:

```text
42/media/lua/shared/ai/BAO_WorldContext.lua
```

Версия:

**V1.1**

WorldContext передаёт DecisionSystem контекст текущего состояния мира.

Планируемые/используемые параметры контекста включают:

* здоровье;
* усталость;
* голод;
* жажду;
* наличие оружия;
* количество/уровень угроз;
* время суток;
* панику;
* другие условия.

---

# 17. DECISION SYSTEM

Файл:

```text
42/media/lua/shared/ai/BAO_DecisionSystem.lua
```

Текущая известная версия:

**V1.2 / V1.2.1**

Важная функция:

```lua
CalculateWithContext()
```

Она нужна для AI Test Harness.

Важно:

Тестовые расчёты через `CalculateWithContext()` не должны менять runtime-состояние текущего решения NPC.

---

# 18. DECISION TYPES

DecisionSystem уже работал с решениями:

```text
patrol
explore
gather_resources
guard
help_ally
rest
heal
retreat
combat
```

---

# 19. ПОДТВЕРЖДЁННЫЕ DECISION ТЕСТЫ

AI Test Harness проводил 9 сценариев.

Все 9 сценариев прошли успешно.

Результаты:

### NORMAL

```text
Decision = combat
Score = 62.05
Priority = 80
```

### LOW_HEALTH

```text
Decision = heal
Score = 69.05
Priority = 100
```

### HIGH_FATIGUE

```text
Decision = rest
Score = 77.60
Priority = 20
```

### MANY_ZOMBIES

```text
Decision = retreat
Score = 97.00
Priority = 90
```

### NIGHT

```text
Decision = combat
Score = 62.05
Priority = 80
```

### NO_WEAPON

```text
Decision = gather_resources
Score = 47.65
Priority = 40
```

### HUNGRY

```text
Decision = gather_resources
Score = 77.65
Priority = 40
```

### THIRSTY

```text
Decision = gather_resources
Score = 87.65
Priority = 40
```

### PANIC

```text
Decision = retreat
Score = 100.00
Priority = 90
```

Итог:

```text
AI Test Harness V1.1
9/9 PASS
```

---

# 20. DEBUG UI

Файл:

```text
42/media/lua/client/BAO_DebugUI.lua
```

Текущая известная рабочая версия:

**V1.8**

Открывается клавишей:

```text
F10
```

Последний подтверждённый лог:

```text
[BAO][DebugUI] OnKeyStartPressed registered
[BAO][DebugUI] OnGameStart registered
[BAO][DebugUI] V1.8 loaded
[BAO][DebugUI] OnGameStart
[BAO][DebugUI] F10 detected
[BAO][DebugUI] Open()
[BAO][DebugUI] Creating V1.8 window at 755, 345
[BAO][DebugUI] Window created successfully
[BAO][DebugUI] Window visible
[BAO][DebugUI] TEST BUTTON PRESSED
```

Ранее была ошибка:

```text
ERROR: General > expected argument of type UIFont, got Double
```

Она возникала через:

```text
ISLabel.lua
BAO_DebugUI.lua
```

Причина была связана с неправильным использованием конструктора UI.

Проблема исправлена.

ВАЖНО:

Не возвращать старую реализацию `ISLabel:new(...)`, которая приводила к этой ошибке.

При работе с UI учитывать фактический Build 42 API.

---

# 21. DEBUG UI — СТАТИЧЕСКИЕ VS CODE ОШИБКИ

Ранее VS Code показывал:

```text
undefined-global
```

для:

```text
ISCollapsableWindow
ISLabel
UIFont
ISButton
getCore
Keyboard
```

Для рабочего UI использовались `_G` / локальные ссылки на реальные PZ API.

Не ломать этот подход.

---

# 22. ACTION SYSTEM

Файл:

```text
42/media/lua/shared/ai/BAO_ActionSystem.lua
```

ВАЖНО:

Этот модуль уже существует.

Не создавать новый ActionSystem.

Последняя предоставленная пользователем реализация:

```text
Action System V1.0
```

Архитектурный принцип:

```text
Decision → Action → Result
```

ActionSystem является универсальным движком действий.

Он пока не должен непосредственно управлять физическим перемещением NPC или анимациями.

---

# 23. ACTION SYSTEM — СОСТОЯНИЯ

В ActionSystem существуют:

```text
PENDING
RUNNING
COMPLETED
FAILED
INTERRUPTED
CANCELLED
```

---

# 24. ACTION SYSTEM — РЕЗУЛЬТАТЫ

```text
SUCCESS
FAILED
BLOCKED
INTERRUPTED
CANCELLED
```

---

# 25. ACTION SYSTEM — ВНУТРЕННИЕ ДАННЫЕ

Система содержит:

```text
initialized
actions
nextActionId
lastAction
lastResult
```

ID генерируется:

```text
bao_action_1
bao_action_2
...
```

---

# 26. ACTION OBJECT

Action содержит:

```text
id
type
state
priority
target
targetId
location
duration
elapsed
interruptible
requirements
result
resultData
reason
onStart
onUpdate
onInterrupt
onComplete
onFail
onCancel
metadata
_started
_finished
```

---

# 27. ACTION SYSTEM API

Известные методы:

```text
CreateAction()
RegisterAction()
GetAction()
CheckRequirements()
StartAction()
UpdateAction()
CompleteAction()
FailAction()
InterruptAction()
CancelAction()
Update()
RemoveAction()
Clear()
GetActions()
GetLastAction()
GetLastResult()
Initialize()
```

---

# 28. ACTION REQUIREMENTS

V1.0 поддерживает:

```text
boolean requirements
function requirements
```

Планируемые требования:

```text
hasWeapon
hasFood
hasTools
targetExists
sufficientHealth
sufficientEnergy
...
```

---

# 29. ACTION CALLBACKS

Action поддерживает:

```text
onStart
onUpdate
onInterrupt
onComplete
onFail
onCancel
```

Callback errors обрабатываются через `pcall`.

---

# 30. ACTION EXECUTOR

Файл:

```text
42/media/lua/shared/ai/BAO_ActionExecutor.lua
```

Он уже существует.

Не создавать второй Action Executor.

Его задача концептуально:

```text
ActionSystem
      ↓
ActionExecutor
      ↓
реальное выполнение действия
```

Перед дальнейшей разработкой обязательно использовать актуальное содержимое файла, а не предполагать его реализацию.

Также существует:

```text
42/media/lua/shared/tests/BAO_ActionExecutorTestHarness.lua
```

---

# 31. AI CONTROLLER

Файл:

```text
42/media/lua/shared/ai/BAO_AIController.lua
```

Он уже существует.

Концептуально должен связывать:

```text
NPC
↓
World Context
↓
Decision
↓
Action
↓
Execution
```

Также существует:

```text
42/media/lua/shared/tests/BAO_AIControllerTestHarness.lua
```

Перед изменениями необходимо учитывать фактическую текущую реализацию.

---

# 32. ROUTINE SYSTEM

Файл:

```text
42/media/lua/shared/routine/BAO_RoutineSystem.lua
```

Уже существует.

Также:

```text
42/media/lua/shared/ai/BAO_RoutineDecisionBridge.lua
```

и тест:

```text
42/media/lua/shared/tests/BAO_RoutineDecisionBridgeTestHarness.lua
```

Идея:

Routine определяет долгосрочный/обычный распорядок NPC.

DecisionSystem может переопределять routine при изменении контекста.

Например:

```text
Routine:
работать на ферме

Но:
опасность появилась

↓

Decision:
retreat

↓

Routine временно прерывается
```

---

# 33. NAVIGATION SYSTEM

Файл:

```text
42/media/lua/shared/navigation/BAO_NavigationSystem.lua
```

Также существуют:

```text
BAO_NavigationTestHarness.lua
BAO_NavigationMovementTest.lua
```

Навигация — отдельный слой.

Не смешивать DecisionSystem с физическим движением.

Архитектура:

```text
Decision
↓
Action
↓
Executor
↓
Navigation
↓
Movement
```

---

# 34. NPC DATA

Файл:

```text
42/media/lua/shared/npc/BAO_NPCData.lua
```

Также:

```text
BAO_NPCDataTest.lua
```

Ранее существовал тестовый NPC:

```text
test_npc_data_001
```

Характеристики раннего теста:

```text
occupation = unemployed
role = assault
type = basic_bandit

Aiming = 3
Fitness = 5
Strength = 4

Trait:
Strong

Skills:
basic_combat_training
basic_combat
```

Это исторический тестовый профиль, а не окончательный NPC design.

---

# 35. FACTIONS

Файл:

```text
42/media/lua/shared/faction/BAO_Factions.lua
```

Тесты существовали.

Фракции:

```text
survivors
bandits
military
raiders
```

Ранее проверенные отношения:

```text
survivors → bandits = hostile
survivors → military = neutral
survivors → raiders = hostile

bandits → raiders = hostile
bandits → military = hostile
```

Также:

```text
BAO_FactionsTest.lua
```

---

# 36. SQUADS

Файл:

```text
42/media/lua/shared/faction/BAO_Squads.lua
```

Ранний тестовый squad:

```text
bandit_patrol_001
```

Faction:

```text
bandits
```

Members:

```text
bandit_npc_001
bandit_npc_002
bandit_npc_003
```

Commander:

```text
bandit_npc_001
```

Type:

```text
patrol
```

Target:

```text
patrol_zone_001
```

Также существует:

```text
BAO_SquadsTest.lua
```

---

# 37. CORE

Файлы:

```text
BAO_Bootstrap.lua
BAO_Test.lua
```

Bootstrap был одним из первых рабочих модулей.

Раннее состояние:

```text
Bootstrap V0.1.0
```

Лог:

```text
[BAO] Bootstrap loaded
```

---

# 38. SERVER DEBUG

Файл:

```text
42/media/lua/server/BAO_DebugServer.lua
```

Существует отдельный server-side debug слой.

Не смешивать client UI и server logic без необходимости.

---

# 39. ACTION TEST HARNESS

Файл:

```text
42/media/lua/shared/tests/BAO_ActionTestHarness.lua
```

Он уже существует.

Не создавать второй:

```text
BAO_ActionSystemTest.lua
```

или другой аналогичный harness, пока не изучено содержимое текущего.

---

# 40. AI TEST HARNESS — ДУБЛИ

В проекте сейчас есть одновременно:

```text
BAO_AITestHarness.lua
BAO_AI_TestHarness.lua
```

Это потенциально подозрительное место.

Не удалять автоматически.

Сначала посмотреть их содержимое и выяснить:

* это разные harness;
* старый/новый вариант;
* совместимые части;
* дубликат;
* исторический файл.

То же самое касается других тестовых файлов.

---

# 41. GIT

Репозиторий:

```text
Balbec219/BanditsAIOverhaul
```

Ветка:

```text
main
```

Последний известный вывод:

```text
38e3f45 (HEAD -> main, origin/main, origin/HEAD) Modded Debug UI and AITestHarness
cd49148 Modded UI again
b25401e Added UI window!!! nd it works!
d1f58ec Deleted some navigations
59c792c Modded navigations both
c4ef4f9 Modded NavigationTestHarness
9d787dc Modded NavigationTestHarness, NavigationMovementTest, navigationSystem
9d2ea1b Added NavigationMovementTest
079f74f Added NavigationTestHarness and NavigationHarness
```

Последний известный `git status` был пустым:

```text
===== GIT STATUS =====
```

То есть на момент проверки рабочее дерево было чистым.

Не считать это гарантией текущего состояния — сначала запускать:

```powershell
git status
```

---

# 42. DISCORD DEVLOG

Существует:

```text
.github/workflows/discord-devlog.yml
```

Цель:

Автоматически отправлять изменения/коммиты BAO в Discord `#dev-log`.

Ранее был создан workflow:

```text
Add Discord dev log automation
```

Ранний известный commit:

```text
25592b4 Add Discord dev log automation
```

Были сообщения с embed/backfill.

Пример devlog:

```text
4e254db RoleScoring added and tested
```

---

# 43. ПРЕДЫДУЩИЕ ИСТОРИЧЕСКИЕ КОММИТЫ

Из ранней истории проекта:

```text
3e55737 events diagnostic + factions test
d26a25e squad data
40c4a18 squad initialization
340dc9c squad test 2
07436fa NPC data/tests
da5b06c PlayerDiagnostic
9be1b89 Replace PlayDiagn client
c15488a Player diagnostic rebuild
60f1dd4 PlayerProfil added
```

Также ранние этапы:

```text
Initial mod structure
Verify server mod loading
```

---

# 44. ПЕРВЫЕ СИСТЕМЫ

На раннем этапе было подтверждено:

* Git работает;
* структура мода корректная;
* сервер видит мод;
* Lua выполняется;
* Bootstrap загружается;
* server/client/shared разделение работает.

---

# 45. ОТЛОЖЕННАЯ ПРОБЛЕМА ADVANCEDANIMATOR

В проекте ранее появлялась проблема Project Zomboid:

```text
AdvancedAnimator
missing AnimSets/actiongroups
```

Эта проблема:

**ОТЛОЖЕНА.**

Она НЕ должна блокировать разработку AI.

Не возвращаться к ней каждый раз.

Сначала строим AI architecture.

Когда понадобится реальная анимация NPC — тогда отдельно решаем animation layer.

---

# 46. ОСНОВНАЯ АРХИТЕКТУРА СЛОЁВ

Запланированная архитектура:

```text
1. Decision System
2. Action System
3. Action Executor
4. NPC Controller
5. Movement / Navigation
6. Activity / Routine
7. Animation Layer
```

Дополнительные cross-cutting системы:

```text
Awareness
Proximity
Needs
Memory
Experience
Relationships
Goals
Faction
Squad
World Context
```

---

# 47. ROADMAP

Оригинальная долгосрочная последовательность:

```text
PlayerDiagnostics
      ↓
PlayerProfile
      ↓
RoleScoring
      ↓
Specialization
      ↓
BehaviorProfile
      ↓
WorldContext
      ↓
DecisionSystem
      ↓
ActionSystem
      ↓
ActionExecutor
      ↓
NPCController
      ↓
Navigation / Movement
      ↓
Memory / Experience
      ↓
Goals
      ↓
Squad AI
      ↓
Faction AI
      ↓
World AI
```

При этом RoutineSystem уже существует и развивается параллельно.

---

# 48. СЛЕДУЮЩИЙ БОЛЬШОЙ ЭТАП

После подтверждения текущего состояния ActionSystem / ActionExecutor / AIController нужно двигаться к **реальному управлению NPC**, но поэтапно.

Нельзя сразу писать огромную систему NPC.

Правильный путь:

```text
Decision
↓
Action
↓
Executor
↓
Controller
↓
Navigation
↓
Movement
↓
Real NPC
```

Сначала добиться контролируемого выполнения одного простого действия.

Например:

```text
NPC decides patrol
↓
ActionSystem creates patrol action
↓
ActionExecutor executes patrol
↓
AIController controls state
↓
Navigation calculates route
↓
NPC moves
```

---

# 49. ACTIONS

Основные действия DecisionSystem:

```text
patrol
explore
gather_resources
guard
help_ally
rest
heal
retreat
combat
```

В дальнейшем ActionSystem должен поддерживать гораздо больше:

```text
move
follow
flee
attack
shoot
reload
loot
eat
drink
sleep
heal
craft
build
repair
drive
steal_vehicle
refuel
guard
patrol
search
investigate
talk
trade
help
rescue
carry
bury_body
burn_body
destroy
sabotage
```

Это не означает, что их надо реализовать сразу.

---

# 50. ПРИНЦИП РАЗДЕЛЕНИЯ DECISION И ACTION

Очень важно:

Decision отвечает:

> Что NPC хочет/должен сделать?

Action отвечает:

> Какое действие было выбрано?

Executor отвечает:

> Как физически выполнить действие?

Controller отвечает:

> Как управлять жизненным циклом AI/NPC?

Navigation отвечает:

> Как физически переместиться?

Animation отвечает:

> Как показать это действие игроку?

Не смешивать эти ответственности.

---

# 51. ПРИМЕР

NPC:

```text
Health = low
Threat = high
Weapon = yes
```

WorldContext:

```text
lowHealth = true
manyZombies = true
```

Decision:

```text
retreat
```

Action:

```text
retreat
```

Executor:

```text
find safe destination
```

Navigation:

```text
calculate path
```

Movement:

```text
NPC walks/runs
```

Result:

```text
escaped
```

World:

```text
NPC survived
```

Memory:

```text
dangerous area remembered
```

Следующий Decision может учитывать этот опыт.

---

# 52. RADIO / INFORMATION NETWORK

Одна из будущих уникальных систем BAO.

Рация не должна быть декоративным предметом.

Она должна быть частью **информационной сети NPC**.

NPC через рацию могут передавать:

```text
Threat
Location
Direction
Approximate enemy count
Threat type
Confidence
```

Например:

```text
Threat:
large zombie group

Location:
approximate coordinates

Direction:
north-east

Enemy count:
20-30

Confidence:
0.75
```

---

# 53. РАЗВИТИЕ ПОСЕЛЕНИЙ

Планируется полноценная система поселений.

Поселения должны иметь:

```text
population
territory
security
resources
radio network
technology
vehicles
defenses
relationships
```

Более развитое поселение:

* имеет больше раций;
* имеет лучшую связь;
* быстрее получает информацию;
* лучше реагирует на угрозы.

---

# 54. NPC COMMUNICATION

В будущем NPC должны иметь:

* радиосвязь;
* голосовые/радио сообщения;
* локальные диалоги;
* информацию о событиях;
* предупреждения;
* передачу координат;
* передачу направления;
* приблизительную оценку угрозы;
* уровень уверенности в информации.

Планируется:

```text
RU default
EN selectable
```

NPC dialogue/radio:

```text
Russian
English
```

Возможна система AI-generated dialogue в будущем, но presets должны оставаться допустимым вариантом.

---

# 55. VEHICLES

Совместимость с транспортом является важным требованием.

NPC должны потенциально уметь:

```text
steal vehicle
use vehicle
damage vehicle
break vehicle
drain fuel
refuel vehicle
```

Нужно учитывать совместимость с vehicle upgrade mods.

---

# 56. DIVERSION / SABOTAGE

В долгосрочной перспективе NPC должны совершать действия без присутствия игрока:

```text
damage fence
destroy defenses
lure zombie horde
leave area
set fire
use explosives
damage base
steal supplies
steal vehicles
```

Это должно работать через общую:

```text
Decision → Action → Executor → Result → Consequence
```

архитектуру, а не через отдельные hardcoded scripts для каждой ситуации.

---

# 57. NPC CREATOR

Планируется Creator UI.

Игрок/admin должен иметь возможность создавать NPC и настраивать:

```text
name
appearance
clothes
weapons
loadout
role
specialization
personality
faction
squad
skills
traits
goals
behavior
```

---

# 58. SANDBOX SETTINGS

Планируется настройка BAO через Sandbox Settings.

Возможные параметры:

```text
NPC population
faction population
AI activity
aggression
memory
radio usage
settlement development
spawn rules
difficulty
```

Точные параметры будут определяться позже.

---

# 59. ADMIN UI

Планируется in-game admin UI для:

```text
create NPC
edit NPC
delete NPC
edit faction
edit squad
edit camp
edit territory
edit population
edit goals
inspect AI state
inspect decision
inspect action
```

---

# 60. CAMPS / ZONES

Планируется редактирование:

```text
NPC camps
settlements
territories
zones
population
```

Администратор должен иметь возможность управлять миром без редактирования Lua.

---

# 61. MEMORY

Будущая система Memory/Experience.

NPC должен запоминать:

```text
events
threats
locations
people
factions
battles
losses
successes
betrayals
help received
```

Память должна влиять на будущие решения.

---

# 62. RELATIONSHIPS

NPC должны иметь отношения:

```text
friendship
trust
fear
respect
hatred
loyalty
```

Отношения могут меняться из-за событий.

Например:

```text
NPC A saved NPC B
↓
trust increases
```

или:

```text
NPC A abandoned NPC B
↓
trust decreases
```

---

# 63. ADAPTATION

NPC должны постепенно адаптироваться.

Например:

После нескольких атак зомби:

```text
NPC learns:
area is dangerous
```

После потери товарища:

```text
NPC becomes more cautious
```

После успешного боя:

```text
confidence increases
```

---

# 64. GOALS

Будущая система Goals.

Цели должны быть:

```text
short-term
medium-term
long-term
```

Например:

```text
short:
find food

medium:
repair camp fence

long:
expand settlement
```

---

# 65. SQUAD AI

Squad AI должен координировать NPC:

```text
commander
members
roles
formation
target
mission
```

Примеры:

```text
patrol squad
scavenging squad
combat squad
rescue squad
guard squad
```

---

# 66. FACTION AI

Faction AI будет стоять выше Squad AI.

Фракция должна иметь:

```text
doctrine
territory
goals
relations
resources
population
military strength
settlements
```

Faction AI принимает стратегические решения.

Squad AI превращает их в задания.

NPC превращает задания в индивидуальные решения.

---

# 67. WORLD AI

Самый высокий слой:

```text
WORLD AI
```

Он должен моделировать крупные процессы:

```text
faction wars
territory changes
settlement growth
migration
resource shortages
zombie threats
trade
raids
alliances
```

---

# 68. ПРИНЦИП CONSEQUENCE

Очень важный принцип:

Действие не должно просто завершаться:

```text
Action completed
```

Оно должно создавать:

```text
Result
↓
Consequence
↓
World change
↓
Memory
↓
Future Decision
```

Например:

```text
NPC patrol
↓
finds enemy
↓
combat
↓
kills enemy
↓
loses teammate
↓
returns to camp
↓
camp receives information
↓
commander changes patrol route
↓
NPC memory stores battle
```

Это один из центральных принципов BAO.

---

# 69. ПРОИЗВОДИТЕЛЬНОСТЬ

Project Zomboid может содержать много NPC.

Поэтому нельзя делать:

```text
каждый NPC
каждый тик
полная AI симуляция
```

без оптимизации.

В будущем использовать:

```text
update intervals
priority levels
simulation tiers
distance checks
awareness radius
event-driven updates
```

Возможна концепция:

```text
Near player:
full simulation

Medium distance:
reduced simulation

Far:
abstract simulation
```

Но это должно быть реализовано позже, после появления базовой полноценной AI.

---

# 70. NPC SIMULATION LEVELS

Планируемая концепция:

### Full

NPC рядом с игроком:

```text
movement
combat
animation
awareness
actions
```

### Reduced

NPC далеко:

```text
decision
action
abstract movement
```

### Abstract

Очень далеко:

```text
statistical simulation
```

Это позволит масштабировать поселения и фракции.

---

# 71. DEBUGGING PHILOSOPHY

Каждая новая крупная система должна иметь:

```text
own module
own version
own logging
own test harness
```

И тестироваться отдельно.

Например:

```text
ActionSystem
↓
ActionTestHarness
```

```text
ActionExecutor
↓
ActionExecutorTestHarness
```

```text
AIController
↓
AIControllerTestHarness
```

---

# 72. DEBUG LOGGING

Предпочтительный формат:

```text
[BAO][Module] message
```

или существующий формат конкретного модуля.

Не удалять диагностические логи, пока система не подтверждена.

---

# 73. ТЕСТИРОВАНИЕ

Новая система должна сначала работать в:

```text
isolated test
```

потом:

```text
integration test
```

и только после этого:

```text
real NPC
```

Не надо одновременно менять:

```text
Decision
Action
Executor
Navigation
NPC
```

и потом пытаться понять, где ошибка.

---

# 74. DEBUG UI КАК CONTROL CENTER

Debug UI постепенно должен стать центром тестирования BAO.

В будущем там должны быть:

```text
Player Diagnostics
Player Profile
Role
Specialization
Behavior
World Context
Decision
Action
Executor
AI Controller
Navigation
Routine
Faction
Squad
NPC
Memory
```

---

# 75. ТЕКУЩАЯ СИТУАЦИЯ С DEBUG UI

На момент последнего теста:

```text
F10
↓
Debug UI
↓
кнопка с 9 AI тестами
↓
9/9 PASS
```

Это уже подтверждённый рабочий milestone.

---

# 76. НЕЛЬЗЯ СЛОМАТЬ РАБОТАЮЩЕЕ

Особенно:

```text
F10 Debug UI
AI Test Harness
DecisionSystem
WorldContext
BehaviorProfile
Specialization
```

Если новая функция ломает старый тест — сначала исправить интеграцию.

Не считать старую рабочую систему «устаревшей» только потому, что появилась новая.

---

# 77. НЕ СОЗДАВАТЬ ДУБЛИ

В текущем проекте уже существуют:

```text
BAO_ActionSystem.lua
BAO_ActionExecutor.lua
BAO_AIController.lua
BAO_RoutineDecisionBridge.lua
BAO_ActionTestHarness.lua
BAO_ActionExecutorTestHarness.lua
BAO_AIControllerTestHarness.lua
```

Поэтому нельзя просто сказать:

> «Создадим новый ActionSystemTest.lua»

пока не проверено содержимое:

```text
BAO_ActionTestHarness.lua
```

То же самое касается:

```text
BAO_AITestHarness.lua
BAO_AI_TestHarness.lua
```

---

# 78. ПОЛИТИКА ИЗМЕНЕНИЙ

Если нужно изменить один файл:

```text
назвать точный путь
дать полный новый файл
```

Если нужно изменить два:

```text
Файл 1:
полный код

Файл 2:
полный код
```

Не давать пользователю искать:

```text
"найди примерно эту строку"
```

если можно дать полный файл.

---

# 79. POWERSHELL

Пользователь работает через Windows PowerShell / Git Bash / VS Code.

Основной путь:

```text
C:\Users\Vovan\Documents\BanditsAIOverhaul
```

Полезные команды:

```powershell
cd "C:\Users\Vovan\Documents\BanditsAIOverhaul"
```

Git:

```powershell
git status
git log --oneline -10
git add .
git commit -m "..."
git push
```

---

# 80. ПРЕДПОЧТИТЕЛЬНАЯ РАБОТА С ФАЙЛАМИ

Если нужно получить состояние проекта:

```powershell
Get-ChildItem -Recurse -File
```

Если нужно получить несколько файлов сразу — сохранять вывод в файл, потому что терминал может обрезать длинный вывод.

Например:

```powershell
Get-Content ... | Out-File BAO_current_code_dump.txt -Encoding UTF8
```

После этого пользователь может прикрепить файл.

---

# 81. НЕЛЬЗЯ ДЕЛАТЬ ВИД, ЧТО ФАЙЛ ПРОЧИТАН

Если известен только filename:

```text
BAO_AIController.lua
```

нельзя утверждать точную внутреннюю реализацию, пока она не была прочитана.

Всегда различать:

```text
известно по архитектуре
```

и

```text
подтверждено содержимым файла
```

---

# 82. ТЕКУЩИЙ САМЫЙ ВАЖНЫЙ МОМЕНТ

Последняя структура проекта показала, что BAO уже имеет гораздо более развитую архитектуру, чем ранняя версия.

В частности, уже существуют:

```text
ActionSystem
ActionExecutor
AIController
RoutineSystem
RoutineDecisionBridge
NavigationSystem
NPCData
FactionSystem
SquadSystem
```

Поэтому дальнейшая работа должна начинаться с **аудита существующей реализации**, а не с создания этих систем заново.

---

# 83. ПОСЛЕДНЯЯ КОМАНДА ДЛЯ АУДИТА

Для получения текущего кода пользователь может создать:

```text
BAO_current_code_dump.txt
```

содержимое:

```text
BAO_ActionSystem.lua
BAO_ActionExecutor.lua
BAO_AIController.lua
BAO_RoutineDecisionBridge.lua
BAO_ActionTestHarness.lua
BAO_ActionExecutorTestHarness.lua
BAO_AIControllerTestHarness.lua
BAO_DebugUI.lua
```

Этот dump нужно использовать как источник истины для следующего этапа.

---

# 84. ЧТО НУЖНО ПРОВЕРИТЬ ПОСЛЕ ПОЛУЧЕНИЯ DUMP

Сначала построить таблицу:

| System          | File                     |    Version | Exists | Tested      | Working     | Depends on             |
| --------------- | ------------------------ | ---------: | ------ | ----------- | ----------- | ---------------------- |
| PlayerProfile   | BAO_PlayerProfile.lua    |         V2 | YES    | YES         | YES         | Diagnostics            |
| RoleScoring     | BAO_RoleScoring.lua      |          — | YES    | YES         | YES         | Profile                |
| Specialization  | BAO_Specialization.lua   |       V1.1 | YES    | YES         | YES         | Role                   |
| BehaviorProfile | BAO_BehaviorProfile.lua  |         V1 | YES    | YES         | YES         | Profile/Specialization |
| WorldContext    | BAO_WorldContext.lua     |       V1.1 | YES    | YES         | YES         | Behavior               |
| DecisionSystem  | BAO_DecisionSystem.lua   |     V1.2.1 | YES    | YES         | YES         | WorldContext           |
| ActionSystem    | BAO_ActionSystem.lua     |       V1.0 | YES    | MUST AUDIT  | MUST AUDIT  | Decision               |
| ActionExecutor  | BAO_ActionExecutor.lua   | MUST AUDIT | YES    | MUST AUDIT  | MUST AUDIT  | Action                 |
| AIController    | BAO_AIController.lua     | MUST AUDIT | YES    | MUST AUDIT  | MUST AUDIT  | AI                     |
| Navigation      | BAO_NavigationSystem.lua | MUST AUDIT | YES    | YES/partial | MUST AUDIT  | Actions                |
| Routine         | BAO_RoutineSystem.lua    | MUST AUDIT | YES    | YES/partial | MUST AUDIT  | Decision               |
| NPCData         | BAO_NPCData.lua          | MUST AUDIT | YES    | YES/partial | MUST AUDIT  | —                      |
| Factions        | BAO_Factions.lua         |          — | YES    | YES         | YES/partial | —                      |
| Squads          | BAO_Squads.lua           |          — | YES    | YES         | YES/partial | Factions               |

ВАЖНО:

Таблица выше содержит подтверждённые данные там, где они действительно известны, и пометки MUST AUDIT там, где текущий код ещё нужно прочитать.

---

# 85. СТРАТЕГИЯ СЛЕДУЮЩЕГО ЭТАПА

После аудита выбрать **одну** следующую интеграционную задачу.

Предпочтительный принцип:

```text
Decision
↓
Action
↓
Executor
↓
Controller
```

Если эти четыре слоя уже интегрированы — проверить:

```text
Controller
↓
Navigation
↓
real NPC
```

Если Navigation уже интегрирована — переходить к реальному NPC.

---

# 86. ПЕРВЫЙ РЕАЛЬНЫЙ NPC MILESTONE

Минимальный полноценный milestone:

NPC получает:

```text
Decision = patrol
```

↓

создаётся:

```text
Action = patrol
```

↓

ActionExecutor:

```text
executes patrol
```

↓

AIController:

```text
controls lifecycle
```

↓

Navigation:

```text
gets destination/path
```

↓

NPC:

```text
actually moves
```

↓

Action:

```text
completed
```

↓

Result:

```text
success
```

Это будет переходом от «AI-логики» к реально действующему NPC.

---

# 87. ПОСЛЕ РЕАЛЬНОГО NPC

После первого работающего NPC:

```text
single NPC
↓
multiple NPC
↓
squad
↓
faction
↓
settlement
↓
world
```

То есть сначала:

```text
individual intelligence
```

затем:

```text
group intelligence
```

затем:

```text
world intelligence
```

---

# 88. КОНЦЕПЦИЯ "PEOPLE AND CONSEQUENCES"

Всегда сохранять главный принцип:

BAO не должен превращаться просто в:

```text
NPC simulator
```

Главная цель:

```text
NPC personality
+
decision
+
action
+
memory
+
relationships
+
consequences
```

Именно последствия действий должны постепенно создавать уникальные истории.

---

# 89. ПРИМЕР БУДУЩЕЙ ИСТОРИИ

```text
NPC A
↓
получает задачу патрулировать
↓
видит чужую группу
↓
решает не атаковать
↓
сообщает по рации
↓
командир получает информацию
↓
решает усилить сектор
↓
Squad B отправляется туда
↓
Squad B сталкивается с противником
↓
происходит бой
↓
NPC B погибает
↓
NPC C запоминает смерть
↓
отношения/мораль меняются
↓
фракция получает информацию
↓
территория становится опасной
↓
через несколько часов игрок приходит
↓
видит последствия
```

Это и есть желаемая философия BAO.

---

# 90. ПОЛЬЗОВАТЕЛЬ НЕ ХОЧЕТ

Не предлагать постоянно:

* Project A-Life как основу;
* зависимость от Bandits;
* Bandits Creator как обязательную основу;
* коридорную AI;
* NPC, которые просто следуют за игроком;
* огромные монолитные Lua-файлы;
* переписывание работающих систем без причины;
* создание дубликатов существующих модулей;
* блокировку всего проекта из-за AdvancedAnimator;
* бессмысленные тестовые системы, если аналог уже существует.

---

# 91. НЕЗАВИСИМОСТЬ ОТ ДРУГИХ BANDIT MODS

BAO должен быть:

```text
самостоятельной системой
```

Не зависеть от:

```text
Bandits
Bandits Creator
```

Сторонние моды могут использоваться как:

```text
reference
compatibility target
```

но не как обязательное ядро BAO.

---

# 92. COMPATIBILITY

Особенно важна совместимость с:

```text
vehicle upgrade mods
```

и другими модами, которые влияют на транспорт/NPC/world.

В будущем создать отдельный compatibility layer, если это потребуется.

---

# 93. REFERENCES / IDEAS

Пользователь обращал внимание на мод/механику:

```text
Common Sense
```

особенно поведение с crowbar.

Это может использоваться как inspiration/reference для взаимодействия NPC с миром.

Также ранее были отмечены Workshop IDs:

```text
3750253491
3763874285
3634630898
2914075159
3498347699
1299328280
3427091746
```

Их назначение нужно проверять перед использованием — не считать их автоматически зависимостями BAO.

---

# 94. ОСНОВНАЯ ФРАЗА ПРОЕКТА

Если нужно объяснить BAO в одном предложении:

> BAO не просто создаёт NPC — BAO создаёт людей, которые принимают решения, действуют и оставляют после себя последствия.

---

# 95. ГЛАВНАЯ ФОРМУЛА

```text
WORLD
→ NPC
→ DECISION
→ ACTION
→ RESULT
→ CONSEQUENCE
→ WORLD
```

Именно эту архитектуру необходимо сохранять на всех следующих этапах.

---

# 96. КАК ПРОДОЛЖАТЬ РАЗРАБОТКУ

При получении нового задания:

### Шаг 1

Проверить существующие файлы.

### Шаг 2

Определить, какой модуль уже отвечает за задачу.

### Шаг 3

Не создавать дубликат.

### Шаг 4

Проверить зависимости.

### Шаг 5

Изменить минимально необходимое количество файлов.

### Шаг 6

Дать полные файлы.

### Шаг 7

Дать команды для установки/копирования.

### Шаг 8

Дать конкретный тест.

### Шаг 9

Указать, какие строки/логи искать.

### Шаг 10

После успешного теста перейти к следующему слою.

---

# 97. ФОРМАТ ОТВЕТОВ ПОЛЬЗОВАТЕЛЮ

Предпочтительный формат:

```text
Сейчас состояние такое:
...

Делаем следующий шаг:
...

Файл:
C:\...\BAO_X.lua

Полностью замени его на:
[полный код]

Потом выполни:
[PowerShell]

Проверь:
[конкретный тест]

В console.txt ищем:
[конкретные строки]

Если PASS:
следующий этап — ...
```

Не перегружать пользователя вопросами.

Если информация уже есть в контексте — не спрашивать её снова.

---

# 98. КРИТИЧЕСКОЕ ПРАВИЛО ПЕРЕД КОДОМ

Если есть сомнение:

```text
"Может быть, такого модуля ещё нет?"
```

сначала проверить структуру проекта.

Если файл уже существует:

```text
не создавать второй.
```

Если есть два похожих файла:

```text
сначала сравнить.
```

---

# 99. ТЕКУЩАЯ ТОЧКА ПРОЕКТА

На текущем этапе BAO уже имеет:

```text
Core
Player Diagnostics
Player Profile
Role Scoring
Specialization
Behavior Profile
World Context
Decision System
Action System
Action Executor
AI Controller
Routine System
Routine Decision Bridge
Navigation System
NPC Data
Factions
Squads
Debug UI
Multiple Test Harnesses
GitHub
Discord DevLog
```

Главная задача теперь — не плодить системы, а **связать уже существующие уровни в единый реально работающий AI pipeline**.

---

# 100. ФИНАЛЬНОЕ ПРАВИЛО ДЛЯ ИИ

Ты работаешь не над абстрактным примером AI.

Ты продолжаешь конкретный проект:

```text
BanditsAIOverhaul
```

для:

```text
Project Zomboid Build 42.20+
```

Существующие рабочие системы нужно сохранять.

Архитектура должна постепенно привести к:

```text
WORLD
 ↓
NPC PROFILE
 ↓
PERSONALITY
 ↓
NEEDS / CONTEXT
 ↓
DECISION
 ↓
ACTION
 ↓
EXECUTOR
 ↓
AI CONTROLLER
 ↓
NAVIGATION
 ↓
MOVEMENT
 ↓
WORLD CONSEQUENCE
 ↓
MEMORY
 ↓
NEW DECISION
```

Главная конечная цель:

> Создать в Project Zomboid систему NPC, где персонажи не являются декорацией или простыми follower-ботами, а являются самостоятельными агентами со своими ролями, личностью, памятью, отношениями, целями, фракциями и последствиями собственных решений.

Именно это является фундаментальной идеей BanditsAIOverhaul.
