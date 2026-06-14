# OpenTracker

Ein schlanker, lokaler **Time-Tracker für macOS** in der Menüleiste — inspiriert
von der ursprünglichen Idee hinter Rize. OpenTracker zeichnet automatisch auf,
welche **Apps und Websites** du wie lange nutzt, teilt deine Zeit in
**Produktiv / Neutral / Ablenkung** auf und bringt einen **Pomodoro-Timer** mit.

Alles passiert **lokal** auf deinem Mac. Keine Cloud, kein Account, kein Tracking
nach außen.

## Funktionen

- 🟢 **Automatisches App-Tracking** — erfasst die App im Vordergrund über
  `NSWorkspace`.
- 🌐 **Browser-Tracking nach Domain** — in Safari, Chrome, Arc, Brave & Edge wird
  die aktive Tab-Domain erfasst (z. B. `github.com` statt nur „Chrome"). Dafür
  ist einmalig eine **Automatisierungs-Berechtigung** nötig (macOS fragt nach).
- 💤 **Leerlauf-Erkennung** — bei Inaktivität (Standard: 2 min) wird Zeit nicht
  mitgezählt.
- 🎯 **Fokus-Score** — Produktiv-/Neutral-/Ablenkungs-Anteil deines Tages.
- 🏷️ **Kategorien** — jede App und Website per Klick als produktiv, neutral oder
  ablenkend markieren. Sinnvolle Voreinstellungen sind dabei.
- 🍅 **Pomodoro-Timer** — Fokus-/Pausenphasen mit Countdown in der Menüleiste.

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15 oder neuer

## Starten

### Empfohlen: als echte App (mit Benachrichtigungen & Browser-Tracking)

```bash
./Scripts/build-app.sh
```

Das Script baut OpenTracker, packt es in ein echtes `OpenTracker.app`-Bundle
(mit Bundle-ID) und startet es. Erst dadurch funktionieren System-Benachrichtigungen
und die Browser-Domain-Erfassung sauber.

> Beim ersten Wechsel in einen Browser fragt macOS einmal:
> *„OpenTracker möchte … steuern"* — auf **OK** klicken. Falls du versehentlich
> ablehnst: *Systemeinstellungen → Datenschutz & Sicherheit → Automatisierung*.

### Schnell entwickeln (Terminal)

```bash
swift run
```

Funktioniert für Tracking & Timer, aber ohne App-Bundle → keine Benachrichtigungen
und Konsolen-Warnungen wegen fehlender Bundle-ID (harmlos).

### In Xcode

```bash
open Package.swift
```

Schema **OpenTracker** wählen und ▶︎ **Run** drücken.

### Bedienung

OpenTracker erscheint **nur in der Menüleiste** (Timer-Symbol ⏱, kein Dock-Icon).
Klick öffnet das Panel; beenden über das Power-Symbol ⏻.

## Wo liegen meine Daten?

```
~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json
```

Pro Tag eine kleine JSON-Datei. Einstellungen und Kategorien liegen in den
`UserDefaults`. Nichts verlässt den Mac.

## Architektur

```
Sources/OpenTracker/
├── App/          App-Einstieg, AppDelegate, Service-Container
├── Models/       AppCategory, DayUsage, ActivitySummary, PomodoroPhase
├── Services/     ActivityTracker, BrowserScripting, UsageStore,
│                 CategoryStore, PomodoroTimer, AppSettings, Notifier
├── Utilities/    Zeit-Formatierung
└── Views/        Menübar-Label, Panel, Pomodoro, Statistiken, Aktivitätsliste
Resources/Info.plist   ← Bundle-ID, LSUIElement, Browser-Berechtigung
Scripts/build-app.sh   ← baut das .app-Bundle
```

- **ActivityTracker** sampelt im 5-Sekunden-Takt die Vordergrund-App. Ist es ein
  Browser, holt **BrowserScripting** per AppleScript die aktive Domain.
- Zeit wird je App bzw. je Domain in den **UsageStore** gebucht.
- **CategoryStore** bewertet Apps und Domains (Presets + eigene Overrides).

## Roadmap

- 📊 **Dashboard-Fenster** mit Tag/Woche-Verlauf und Diagrammen *(als Nächstes)*
- Benannte Arbeits-Kategorien (Development, Email …) mit Bewertung
- Wochen-/Monatsvergleich, Ziele & Streaks
- CSV-Export, „beim Anmelden starten"

---

Gebaut als native SwiftUI-Menübar-App.
