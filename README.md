# LARNES Mobile

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

По умолчанию **debug** ходит в prod API: `https://larnes.online` (та же БД, что web на VPS). Отдельный флаг не нужен.

Release-сборки — тоже `https://larnes.online`.

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
