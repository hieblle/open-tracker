# OpenTracker

Ein schlanker, lokaler **Time-Tracker für macOS** in der Menüleiste — inspiriert
von der ursprünglichen Idee hinter Rize. OpenTracker zeichnet automatisch auf,
welche Apps du wie lange nutzt, teilt deine Zeit in **Produktiv / Neutral /
Ablenkung** auf und bringt einen **Pomodoro-Timer** mit.

Alles passiert **lokal** auf deinem Mac. Keine Cloud, kein Account, kein Tracking
nach außen.

## Funktionen (v1)

- 🟢 **Automatisches App-Tracking** — erfasst die App im Vordergrund über
  `NSWorkspace`. Keine besonderen Berechtigungen nötig.
- 💤 **Leerlauf-Erkennung** — bist du länger inaktiv (Standard: 2 min), wird die
  Zeit nicht mitgezählt, damit deine Statistik ehrlich bleibt.
- 🎯 **Fokus-Score** — Produktiv-/Neutral-/Ablenkungs-Anteil deines Tages auf
  einen Blick, inkl. Balken und Tagesgesamtzeit.
- 🏷️ **Kategorien pro App** — jede App per Klick als produktiv, neutral oder
  ablenkend markieren. Sinnvolle Voreinstellungen sind dabei.
- 🍅 **Pomodoro-Timer** — Fokus-/Pausenphasen mit Ring-Countdown direkt in der
  Menüleiste, frei konfigurierbar.

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15 oder neuer (bzw. die passenden Command Line Tools)

## Starten

### Schnell ausprobieren (Terminal)

```bash
swift run
```

Es erscheint ein **Timer-Symbol in der Menüleiste** (oben rechts). Klick darauf
öffnet das Panel. Beenden über das Power-Symbol unten im Panel.

> Hinweis: Per `swift run` läuft die App ohne App-Bundle. Der Timer und das
> Tracking funktionieren vollständig; nur die System-Benachrichtigungen am Ende
> einer Pomodoro-Phase sind deaktiviert (es ertönt stattdessen ein Ton). Für
> echte Banner siehe „Als App bauen".

### In Xcode entwickeln

```bash
open Package.swift
```

Xcode öffnet das Paket. Schema **OpenTracker** wählen und auf **Run** (⌘R)
drücken.

### Als echte `.app` bauen (mit Benachrichtigungen & Icon)

Für eine verteilbare App mit Bundle-Identifier (Voraussetzung für
Benachrichtigungen) legst du in Xcode ein **macOS App**-Target an und ziehst die
Dateien aus `Sources/OpenTracker/` hinein. Wichtige Einstellungen:

- **Info.plist**: `Application is agent (UIElement)` = `YES` (versteckt das
  Dock-Icon — zur Laufzeit setzen wir das zusätzlich über
  `NSApp.setActivationPolicy(.accessory)`).
- **Signing & Capabilities**: ein Bundle-Identifier (z. B. `com.deinname.OpenTracker`).

## Wo liegen meine Daten?

```
~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json
```

Pro Tag eine kleine JSON-Datei mit den Sekunden je App. Einstellungen und
Kategorien liegen in den `UserDefaults`. Löschen = Daten weg, nichts verlässt
den Mac.

## Architektur

```
Sources/OpenTracker/
├── App/          App-Einstieg, AppDelegate, Service-Container
├── Models/       AppCategory, DayUsage, AppUsageSummary, PomodoroPhase
├── Services/     ActivityTracker, UsageStore, CategoryStore,
│                 PomodoroTimer, AppSettings, Notifier
├── Utilities/    Zeit-Formatierung
└── Views/        Menübar-Label, Panel, Pomodoro, Statistiken, Einstellungen
```

- **ActivityTracker** sampelt im 5-Sekunden-Takt die Vordergrund-App und bucht
  die aktive Zeit (Idle-Zeit ausgenommen) in den **UsageStore**.
- **CategoryStore** ordnet Bundle-IDs Kategorien zu (Presets + eigene Overrides).
- **PomodoroTimer** ist eine kleine Zustandsmaschine, die über ein absolutes
   Enddatum tickt und so auch bei verzögerten Ticks korrekt bleibt.

## Ideen für später

- Wochen-/Verlaufsansicht mit Diagrammen
- Fenstertitel-/Projektkontext (benötigt Bedienungshilfen-Berechtigung)
- Ziele & Streaks, automatische App-Kategorisierung
- Export (CSV)
- Login-Item („beim Anmelden starten")

---

Gebaut als native SwiftUI-Menübar-App.
