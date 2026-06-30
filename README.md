# LARNES Mobile

Flutter-приложение LARNES.

## Запуск

```powershell
$env:PATH = "D:\projects\LARNES-2.0\.tools\flutter\bin;" + $env:PATH
cd larnes-mobile
flutter pub get
flutter run -d emulator-5554
```

## API (dev)

Эмулятор + локальный Next.js:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3200
```

Prod по умолчанию: `https://larnes.online`

## Документация

Журнал: [platform/docs/active/larnes-mobile-dev.md](../platform/docs/active/larnes-mobile-dev.md)
