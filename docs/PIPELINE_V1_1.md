# BAO: Controller / Executor integration V1.1

Дата: 2026-09-29. Изменения уже внесены в готовые Lua-файлы.

## Файлы

Все пути относительно `C:\Users\Vovan\Documents\BanditsAIOverhaul`:

| Полный файл с готовым кодом | Изменение |
| --- | --- |
| `42/media/lua/shared/ai/BAO_AIController.lua` | V1.1: запуск пары Action/Execution, история, остановка, явный повтор, изоляция тестов |
| `42/media/lua/shared/ai/BAO_ActionExecutor.lua` | V1.1: синхронизация результата с Action, однократное завершение, защита владельца |
| `42/media/lua/shared/ai/BAO_ActionSystem.lua` | V1.1: externalCompletion, обработка отказа требований и ошибки onStart |
| `42/media/lua/shared/tests/BAO_AIControllerTestHarness.lua` | V1.1: 39 изолированных интеграционных проверок |
| `42/media/lua/shared/tests/BAO_ActionExecutorTestHarness.lua` | Проверка версии обновлённого Executor |
| `42/media/lua/shared/tests/BAO_RoutineDecisionBridgeTestHarness.lua` | Чтение boolean, reason из EvaluateEmergency; строгая проверка нормального контекста |
| `42/media/lua/client/BAO_DebugUI.lua` | V1.9: кнопка PIPELINE TESTS |

Новые модули AI не создавались. `tools/run_lua_tests.py` — офлайн runner для разработки,
а не игровой модуль. Полные исходники доступны по указанным путям; вручную вставлять
фрагменты или заменять файлы не требуется.

## Установка и проверка в игре

Папка `C:\Users\Vovan\Zomboid\mods\BanditsAIOverhaul` является junction на этот проект.
Копировать исходники в неё не нужно. Старые версии 7 файлов из HEAD `38e3f45` сохранены:
`C:\Users\Vovan\Zomboid\BAO_Backups\pipeline-before-v11-38e3f45.zip`.

1. Полностью закрой и заново запусти Project Zomboid.
2. Войди в тестовый мир. Автоматический Controller harness выполнится на OnGameStart.
3. Нажми F10. Кнопка слева сверху должна называться PIPELINE TESTS.
4. Нажми её: ожидается `39/39 PASSED`, Status `PASS`.
5. Нажми ещё раз: снова 39/39. Текущая runtime-пара должна сохраниться.
6. RUN ALL TESTS по-прежнему запускает прежние 9 сценариев выбора решения.

В `C:\Users\Vovan\Zomboid\console.txt` ищем:

```text
[BAO][DebugUI] V1.9 loaded
[BAO][BAO_AIControllerTestHarness] PIPELINE V1.1 TOTAL=39 PASS=39 FAIL=0
[BAO][BAO_AIControllerTestHarness] STATUS: ALL TESTS PASSED
[BAO][BAO_RoutineDecisionBridgeTest] STATUS: ALL TESTS PASSED
```

В harness намеренно проверяются отказ старта и исключение onStart. Поэтому внутри
тестового вывода возможны `expected test error`, `injected_start_failure` и строки
о failed/interrupted actions; результат suite определяется итоговыми PASS/FAIL.
Ошибки AdvancedAnimator по-прежнему отложены отдельно.

## Что гарантирует эта версия

Один Controller запускает одно действие и одно выполнение. Повторный Update не создаёт
дубликаты. Завершение, ошибка, прерывание или отмена синхронизируются между слоями.
Повторное завершение не увеличивает статистику. Смена решения не теряет непрерываемую
пару. История хранит decisionId завершённого действия. Удаление связанного Action
не оставляет активный Execution. Сбой запуска не вызывает бесконечное создание действий.

После terminal-состояния Controller ждёт смены решения. Для намеренного повторения
предусмотрен `BAO.AIController.RestartCurrentDecision()`. Это явный контракт V1.1.

Физическое выполнение ещё не подключено: `ExecuteStep()` не перемещает NPC.
Патруль не получает SUCCESS от прошедшего таймера. Синтетическое завершение в harness
проверяет связь слоёв, а не факт прибытия персонажа.

## Офлайн-проверки

Проверено на Lua 5.1 через lupa: синтаксис 32 Lua-файлов, pipeline 39/39,
старые Action/Executor suites, RoutineDecisionBridge, повторные запуски при занятом
runtime, восстановление после исключения и UI handler. UI не рендерился; PZ API
движения не эмулировались. Проверка в игре после патча пока ожидается.

Повторить на этой машине (тестовая lupa установлена только во временный каталог):

```powershell
Set-Location 'C:\Users\Vovan\Documents\BanditsAIOverhaul'
& 'C:\Users\Vovan\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/run_lua_tests.py --runtime-path "$env:TEMP\bao-lua-test-runtime"
```

Если временный каталог удалён, установить туда `lupa` через `python -m pip install
--target <путь> lupa`, затем передать этот путь параметром `--runtime-path`.

Следующая интеграционная задача: передать заданные character и destination в
существующую Navigation и завершать patrol по фактическому прибытию, проверяя
этаж, отсутствие прогресса, ошибку и отмену. Массовый NPC runtime пока не добавляется.
