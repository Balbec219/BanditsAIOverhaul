# Pipeline V1.2 / Navigation V1.3

## Две ошибки в логе

В console.txt от 2026-09-29 23:35:38 предыдущая версия дважды прошла 39/39.
Исключения на строках 3288 и 4206 вызваны намеренным `error("expected test error")`
в тесте onStart. В PZ/Kahlua pcall не предотвращает запись исключения в игровой
счётчик ошибок. Этот тест перенесён только в `tools/run_lua_tests.py`.
Обработка настоящих ошибок callbacks осталась в ActionSystem.

## Что готово

Существующий Controller может привязать персонажа и координаты к следующему patrol.
Executor создаёт один запрос Navigation и наблюдает его результат. Прибытие завершает
действие только при достижении XY на правильном этаже. Зависший маршрут и превышение
таймаута завершаются ошибкой. Прерывание отменяет принадлежащий этому выполнению путь.
Старая пара не может остановить новый чужой запрос.

Это ещё не автоматический спавн NPC. Нужен существующий игровой character, для которого
движение обновляет движок. IsoPlayer отклоняется; навигация не меняет координаты персонажа
и не вызывает вручную PathFindBehavior2:update(). Жизненный цикл настоящего NPC — следующий этап.

## Готовые файлы

Корень: `C:\Users\Vovan\Documents\BanditsAIOverhaul`.

| Файл | Назначение изменений |
| --- | --- |
| `42/media/lua/shared/ai/BAO_AIController.lua` | Привязка patrol к character/точке, сохранение владения при ошибке cleanup |
| `42/media/lua/shared/ai/BAO_ActionExecutor.lua` | Запуск и наблюдение Navigation, освобождение пути |
| `42/media/lua/shared/ai/BAO_ActionSystem.lua` | canComplete для проверки возможности завершения |
| `42/media/lua/shared/navigation/BAO_NavigationSystem.lua` | Navigation V1.3, таймауты, отмена, ограниченная частота обновлений |
| `42/media/lua/shared/tests/BAO_AIControllerTestHarness.lua` | 66 изолированных проверок, без намеренных исключений |
| `42/media/lua/shared/tests/BAO_ActionExecutorTestHarness.lua` | Проверка версии 1.2 |
| `42/media/lua/shared/tests/BAO_NavigationTestHarness.lua` | Проверка версии 1.3 |
| `tools/run_lua_tests.py` | Проверки исключений, активного маршрута, паузы и частоты опроса вне игры |

DebugUI V1.9 из предыдущего этапа уже вызывает расширенный harness; его менять не потребовалось.
Новых AI-модулей не создано: текущие ответственности покрыты существующими файлами.

## Производительность

- Навигация без активного запроса сразу возвращается и не читает позицию.
- Активный запрос опрашивается примерно раз в 100 мс игрового delta.
- Для LOCATION берётся один набор XYZ за опрос вместо повторных валидаций позиции.
- Путь запрашивается один раз при старте, не каждый тик.
- Подробные probes выключены; при `diagnostics=true` выполняются не чаще раза в секунду.
- Статистика имеет `polls`, `positionReads`, `pathRequests`, `diagnosticReads`.
- Дельта берётся из getRealworldSecondsSinceLastUpdate; нулевая дельта не расходует таймаут,
  а очень длинный кадр ограничен 0.25 с для защиты от мгновенного timeout при возобновлении.

Эти изменения проверены функционально; прирост FPS не измерялся.
Дальнейший план — `PERFORMANCE_PLAN.md`.

## API для следующего этапа

`BAO.AIController.SetPatrolTarget(character, x, y, z, options)` применяется, когда Controller
не имеет текущего Action. Возвращает успех или false/reason. Он задаёт цель следующему
решению patrol, но не подменяет решение DecisionSystem. `ClearPatrolTarget()` снимает
привязку, также при отсутствии текущего Action.

Options: `timeoutSeconds` (30 по умолчанию), `stuckSeconds` (5), `arrivalRadius` (0.5,
диапазон 0..1), `diagnostics` (false). После терминального результата повтор остаётся
явным: `RestartCurrentDecision()` или смена решения.

При поддержке отмены движок получает `getPathFindBehavior2():cancel()` и `setPath2(nil)`.
Если cleanup не удался, владение не освобождается для запуска нового маршрута.
Навигация не заявляет мгновенное распознавание всех внутренних отказов движка:
отсутствие дальнейшего движения определяется по stuck/total timeout.

## Проверка

1. Полностью перезапусти игру и войди в тестовый мир.
2. F10 → PIPELINE TESTS. Ожидается `66/66 PASSED`, `PASS`.
3. Повтори: тот же итог, без новых `expected test error`.
4. В новом console.txt ищи:

```text
[BAO][NavigationSystem] NavigationSystem V1.3 loaded
[BAO][BAO_AIControllerTestHarness] PIPELINE V1.2 TOTAL=66 PASS=66 FAIL=0
```

PASS проверяет тестовый объект. Это не подтверждение физического движения настоящего NPC.
AdvancedAnimator и предупреждения сторонних модов остаются отдельными вопросами.

Офлайн Lua 5.1: синтаксис 32 файлов; pipeline 66/66; старые Action/Executor/Navigation/Bridge
suites; повторный harness при активном пути; отсутствие лишних polls, поведение на паузе,
обработка ошибки остановки и UI handler. Проверка новой версии в игре пока ожидается.

Резервная копия перед изменениями: `C:\Users\Vovan\Zomboid\BAO_Backups\before-navigation-v13.zip`.
Установленный мод — junction на исходники, поэтому копирование не требуется.

## Проверенные локальные API 42.21.0

В `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid`:
- `media/lua/client/Vehicles/TimedActions/ISPathFindAction.lua`: cancel + setPath2(nil).
- `media/lua/shared/TimedActions/ISRestAction.lua`: getRealworldSecondsSinceLastUpdate.
- `projectzomboid.jar`, IsoGameCharacter.class: public pathToLocationF(FFF), pathToCharacter,
  pathToSound(III), getPathFindBehavior2, setPath2. SOUND-координаты округляются до integer.
