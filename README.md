# LARNES Mobile

**2026-10-31 — девайсы, прогон 4:** общий экран ученика передаёт подготовку/ответы тренажёра без подключения к звонку; `ready` получает link текущего Flutter-подключения, старые поколения/комнаты отклоняются. `assets/call/larnes-board.js` заново собран из общих веб-исходников, включая последние «Арбузы», и проверен `node scripts/mobile-board/build.mjs --check` из `platform`. 46 профильных Flutter-тестов и целевой Dart analyze прошли; настоящий APK/устройства — следующий прогон 5. Использовать согласованные веб и приложение; миграций/env нет. [Общий журнал и ограничения](../platform/docs/active/classroom-devices-unified-lesson-v1.md#прогон-4--единый-учебный-маршрут-и-готовность-упражнений-2026-10-31).

**2026-10-27 — Диск, прогон22:** доска ДЗ использует общий native protocol2, CAS/operation receipts, app-private durable outbox и authenticated image bridge. Пересобран SDK, обе HTML принимают реальный пакет65 частей/около15MiB; browser feature flags не требуют Node process.5 Flutter/FS tests и4 настоящих Chromium сценария PASS; Dart analyze изменённых файлов чистый. Backend требует0304 и совместимого native endpoint; старые APK не могут писать перенесённое ДЗ (409 native_required). Native protocol2 сохраняет служебные маркеры удаления при загрузке/сохранении, старый homework wire остаётся совместимым. Новый APK/телефоны/visual/production не приняты, включать homework canary только после установки нового клиента. [Подробный журнал22](../platform/docs/active/larnes-drive-v1-implementation.md#прогон-22-проверяемое-переключение-чтениязаписи-и-совместимость). Старые срезы ниже — история.

**2026-10-16 — доска урока, прогон 52:** общий плеер получил компактную рамку, название и вписывание по обеим сторонам. Пересобран `assets/call/larnes-board.js`. Модель `LessonChildBoard` и HTML передают/показывают краткоживущее уведомление о присутствии педагога в аудиокомнате; вне своей комнаты оно не показывается и без обновлений исчезает. Новый модельный тест и анализ изменённых Dart-файлов прошли. Живой телефон/звук и внешний вид Alex принимает позже; APK и production не менялись. [Прогон и ограничения](../platform/docs/completed/lesson-board-workspace-v2.md#прогон-52-комнаты-тренажёры-и-аудиосвязь).

Flutter-приложение LARNES.

## Запуск (физический Android)

1. На телефоне: режим разработчика + USB-отладка (или Wi‑Fi debugging).
2. Подключить USB, проверить устройство:

```powershell
$env:PATH = "D:\projects\LARNES-2.0\.tools\flutter\bin;" + $env:PATH
cd larnes-mobile
flutter pub get
flutter devices
flutter run
```

По умолчанию **debug** ходит в prod API: `https://larnes.ru` (та же БД, что web на VPS). Отдельный флаг не нужен.

Release-сборки — тоже `https://larnes.ru`.

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

Перед установкой на планшет: удалить старую версию app (Settings → Apps) или `adb uninstall com.larnes.larnes_mobile`.

## API: когда какой backend

| Сценарий | Команда |
|----------|---------|
| **Обычная разработка UI** (телефон) | `flutter run` |
| **Локальный `platform/`** на ноуте (своя БД) | см. ниже |
| **Android-эмулятор** + локальный Next.js | `--dart-define=API_BASE_URL=http://10.0.2.2:3200` |

### Локальный platform + телефон (одна Wi‑Fi)

`localhost` на телефоне — это сам телефон, не ноут. Нужен **LAN IP ноута**:

```powershell
ipconfig
# IPv4, например 192.168.1.42
```

Backend слушает сеть (не только 127.0.0.1):

```powershell
cd platform
npx next dev -H 0.0.0.0 -p 3200
```

Разрешить порт 3200 в firewall Windows, если не коннектится.

```powershell
cd larnes-mobile
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3200
```

HTTP на LAN: в Android уже `usesCleartextTraffic="true"`.

### Эмулятор (если понадобится)

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3200
```

## Документация

Журнал: [platform/docs/completed/larnes-mobile-dev.md](../platform/docs/completed/larnes-mobile-dev.md)

### Parent activity diary (приёмка)

Hub ребёнка → **Посещаемость** · **График** · **Оплаты** — read-only parity с web `/parent/:childId/activity/*`.

Smoke на staging (тот же ребёнок, что web):

1. Hub → Посещаемость → класс → календарь месяца.
2. Hub → График → place dock, листание дней.
3. Hub → Оплаты → Начисления / Чеки → деталь строки.

Эпик: [platform/docs/completed/parent-activity-mobile-v1.md](../platform/docs/completed/parent-activity-mobile-v1.md)
