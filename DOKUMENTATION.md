# OpenTracker — Dokumentation

> Stand: 2026-06-14 · Version 0.3
> Ein lokaler **Time-Tracker & Reflexionswerkzeug für macOS** in der Menüleiste,
> inspiriert von Rize. Erfasst automatisch, womit du am Mac Zeit verbringst,
> und macht **Fokus, Ablenkungen, Kontextwechsel, Pausen und Ziele** sichtbar.
> **Alle Daten bleiben lokal** auf deinem Mac — keine Cloud, kein Account.

## Inhalt
1. [Überblick & Philosophie](#1-überblick--philosophie)
2. [Installation & Start](#2-installation--start)
3. [Berechtigungen](#3-berechtigungen)
4. [Bedienung](#4-bedienung)
5. [Funktionen im Detail](#5-funktionen-im-detail)
6. [Kennzahlen & Definitionen](#6-kennzahlen--definitionen)
7. [Speicherung & Datenschutz](#7-speicherung--datenschutz)
8. [Bekannte Einschränkungen](#8-bekannte-einschränkungen)
9. [Architektur (Kurzüberblick)](#9-architektur-kurzüberblick)

---

## 1. Überblick & Philosophie

OpenTracker läuft unauffällig als **Menüleisten-Agent** (kein Dock-Icon) und
zeichnet im Hintergrund auf, welche **Apps** und **Websites** du wie lange aktiv
nutzt. Daraus entstehen einfache, verständliche Auswertungen.

Leitprinzip: Es soll sich wie ein **privates Reflexionswerkzeug** anfühlen, nicht
wie ein Kontroll- oder Monitoring-Tool. Deshalb: lokal, ermutigend formuliert,
ohne Datenversand nach außen.

---

## 2. Installation & Start

**Voraussetzungen:** macOS 14 (Sonoma) oder neuer · Xcode 15 oder neuer.

### Empfohlen: als echte App (mit Benachrichtigungen & Browser-Tracking)
```bash
git clone https://github.com/hieblle/open-tracker.git
cd open-tracker
git checkout claude/great-hopper-qupu5e
./Scripts/build-app.sh
```
Das Script baut `OpenTracker.app` (mit Bundle-ID), signiert sie ad-hoc und
startet sie. **Immer so starten**, damit Benachrichtigungen, Browser-Erfassung
und gespeicherte Einstellungen konsistent sind.

### Schnelltest (Terminal)
```bash
swift run
```
Tracking & Timer funktionieren, aber **ohne App-Bundle** → keine
Benachrichtigungen, und Konsolen-Warnungen wegen fehlender Bundle-ID (harmlos).

### In Xcode
```bash
open Package.swift
```
Schema **OpenTracker** wählen → ▶︎ Run.

> Nach einem Update einfach `git pull origin claude/great-hopper-qupu5e` und
> erneut `./Scripts/build-app.sh`.

---

## 3. Berechtigungen

Beim ersten Start fragt macOS ggf. nach:

- **Benachrichtigungen** — für die Pomodoro-Phasenende-Hinweise. (Optional; es
  ertönt zusätzlich/sonst ein Ton.)
- **Automatisierung** („OpenTracker möchte ‚Google Chrome' steuern") — nötig, um
  die **aktive Browser-Domain** auszulesen. Beim ersten Browser-Wechsel → **OK**.

Versehentlich abgelehnt? *Systemeinstellungen → Datenschutz & Sicherheit →
Automatisierung → OpenTracker* aktivieren und die App neu starten.

Es werden **keine besonderen Rechte** für das reine App-Tracking benötigt.

---

## 4. Bedienung

### Menüleisten-Symbol
Oben rechts erscheint ein Symbol. Es zeigt den Zustand:
- ⏱ Standard
- 🍅 + Countdown, wenn ein Pomodoro läuft
- ⏸ wenn manuell pausiert · ⚠️ bei manuell markierter externer Ablenkung

Klick öffnet das **Panel**.

### Das Panel (Klick aufs Menüleisten-Symbol)
- **Pomodoro** — Ring-Countdown, Start/Pause, Zurücksetzen, Phase überspringen.
- **Heute** — Fokus-Prozent, Aufteilung Produktiv/Neutral/Ablenkung als Balken,
  Tagesgesamtzeit.
- **Pause / Ablenkung** — zwei Buttons (siehe „Manuelle Marker").
- **Aktivität heute** — Top-Apps & -Websites mit Zeit; farbiger Punkt = Kategorie
  (klickbar zum Umkategorisieren).
- **Dashboard öffnen** — öffnet das große Fenster.
- **Fußzeile** — ⚙️ Einstellungen · aktuelle Aktivität (grüner Punkt = aktiv) ·
  ⏻ Beenden.

### Das Dashboard-Fenster
Vier Reiter:

- **Tag** — Detailansicht des gewählten Tages; mit **‹ ›** durch vergangene Tage
  blättern. Enthält: Fokus-Aufteilung, Ziel-Fortschritt, Insight-Kacheln,
  Tagesverlauf-Zeitleiste, Fokus-Unterbrechungen, Projekt-Aufteilung, sowie
  alle Apps und Websites.
- **Woche** — letzte 7 Tage: Verlaufs-Balkendiagramm, Wochen-Kennzahlen,
  Aufteilung, Fokus-Unterbrechungen, Top-Apps/-Websites.
- **Ziele** — Tagesfortschritt, „Meine Ziele" (bearbeiten/löschen), Vorlagen,
  eigener Ziel-Builder.
- **Verwalten** — Projekte anlegen/löschen; für jede App/Website der letzten 14
  Tage Bewertung (Produktiv/Neutral/Ablenkung) und Projekt zuweisen.

> Während das Dashboard offen ist, erscheint kurz ein **Dock-Icon** — normal.
> Schließt du das Fenster, ist OpenTracker wieder nur in der Menüleiste.

---

## 5. Funktionen im Detail

### Automatisches Tracking
Alle **5 Sekunden** wird die Vordergrund-App erfasst. Ist es ein unterstützter
Browser, wird die **aktive Tab-Domain** ausgelesen und die Zeit der **Website**
zugeschrieben (z. B. `github.com` statt nur „Chrome"). Pro Messpunkt zählt die
Zeit **entweder** auf die Website **oder** die App — nie doppelt.

Unterstützte Browser: Safari, Chrome, Arc, Brave, Edge (+ Safari Technology
Preview, Chrome Canary, Vivaldi). **Firefox**: nur App-Ebene (kein URL-Scripting).

### Kategorien (Produktiv / Neutral / Ablenkung)
Jede App und Domain ist einer Bewertung zugeordnet. Sinnvolle **Voreinstellungen**
sind dabei (z. B. Xcode/VS Code = produktiv, github.com = produktiv,
youtube.com/Social Media = ablenkend). Ändern: farbiger Punkt in den Listen oder
zentral im **Verwalten**-Tab. Eigene Zuweisungen überschreiben die Presets.

### Projekte
Frei anlegbare Projekte (mit Farbe), denen du Apps/Websites zuordnest —
unabhängig von der Bewertung. Auswertung als „Zeit pro Projekt" in Tag & Woche.
Anlegen/zuordnen im **Verwalten**-Tab.

### Fokuszeit-Analyse
Misst deine produktive Zeit, die Anzahl der **Fokus-Sessions** (≥ 15 min am
Stück) und die **längste Fokus-Phase**.

### Fokus-Unterbrechungs-Analyse
Der Kern des Reflexionsteils. Statt roher Wechselzahlen wird gemessen, **wie oft
deine Fokusphasen unterbrochen werden** — Wechsel zwischen *produktiven*
Tätigkeiten zählen bewusst **nicht** als Unterbrechung.
- **Unterbrechungen** (Anzahl) je Fokusphase, und **pro Fokus-Stunde**
- **Ø ungestörte Phase** und **tiefer Fokus**
- **Wodurch?** — aufgeschlüsselt nach **Ablenkung / Neutrales / Pause**
- **Häufigste Unterbrecher** — farbcodiert (z. B. „Slack 6× · Ablenkung")
- **Fragmentierung** (0–100 %) sowie App- und Tab-Wechsel als Nebeninfo

### Manuelle Marker: Pause & externe Ablenkung
Zwei Buttons im Panel pausieren das automatische Tracking und werden
**unterschiedlich** bewertet:
- 🔵 **Pause** — Erholungspause (Kaffee, kurz weg) → zählt als **neutrale Pause**.
- 🟠 **Ablenkung** — externe Unterbrechung → zählt als **Ablenkung** (geht in die
  „ablenkend"-Zeit ein und erscheint bei den Unterbrechern).

Während aktiv: Banner + „Fortsetzen"; das Menüleisten-Symbol wechselt (⏸ / ⚠️).

### Pausen & Tagesverlauf
- **Automatische Pausen**: Inaktivität ≥ 2 min wird als Pause erkannt (Zeit wird
  nicht als aktiv gezählt).
- **Tagesverlauf-Zeitleiste**: eine farbige Leiste über den Tag (Produktiv/
  Neutral/Ablenkung + Pausen) — zeigt auf einen Blick, wie fokussiert oder
  zerstückelt der Tag war.

### Tages- & Wochenberichte
Übersichtliche Karten und ein dependency-freies 7-Tage-Balkendiagramm; vergangene
Tage frei aufrufbar. Die Historie wächst Tag für Tag.

### Ziele
Tägliche Ziele als **„Mindestens"** (Untergrenze) oder **„Höchstens"** (Budget):
- **Vorlagen** (1-Klick): Mindest-Arbeitszeit · Mehr Fokuszeit ·
  6-Stunden-Arbeitstag · Weniger Ablenkung · Mehr Pausen.
- **Eigene Ziele** (Builder): Metrik (Arbeitszeit/Fokus/Neutral/Ablenkung/Pausen/
  **Projekt**) × Richtung × Minuten. Projekt-Ziele decken z. B. „Meeting-Zeit
  reduzieren" ab (Projekt „Meetings" anlegen).
- **Bearbeiten**: in „Meine Ziele" Zielzeit per Stepper anpassen, Richtung
  umschalten, löschen. Vorlagen erzeugen **keine Duplikate**.
- **Fortschritt**: Balken im Ziele-Tab und in der Tagesansicht. *Mindestens* →
  grün bei Erreichen; *Höchstens* → grün/orange/rot je nach Budget.

### Pomodoro-Timer
Klassischer Fokus-/Pausen-Zyklus mit Ring-Countdown in der Menüleiste.
Standard: 25 min Fokus, 5 min kurze Pause, 15 min lange Pause nach 4 Pomodoros —
alles einstellbar. Tonsignal (und Benachrichtigung in der `.app`) am Phasenende.

### Einstellungen (Panel → ⚙️)
- Pomodoro: Fokus-, kurze & lange Pausenlänge, Pomodoros bis zur langen Pause.
- **Leerlauf-Schwelle** (Default 120 s): ab wann Inaktivität als Pause gilt.
- **Fokusphase ab** (Default 15 min): ab wann ein produktiver Block als
  „Fokusphase" zählt, deren Unterbrechungen gemessen werden.

---

## 6. Kennzahlen & Definitionen

| Begriff | Definition (Standard) |
|---|---|
| Aktive Zeit | Produktiv + Neutral + Ablenkung (ohne Pausen) |
| Fokuszeit | Zeit in als *produktiv* bewerteten Aktivitäten |
| Fokus-Session | ununterbrochene produktive Phase ≥ 15 min |
| Fokusphase (für Unterbrechungen) | produktive Phase ≥ **einstellbarer Schwelle** (Default 15 min) |
| Pause | Inaktivität ≥ 2 min oder manuell markierte Erholungspause |
| Kontextwechsel | Wechsel zwischen verschiedenen Aktivitäten (App/Tab) |
| Fragmentierung | Anteil der Fokuszeit, der **nicht** in langen Blöcken liegt (0–100 %) |
| Mess-Intervall | 5 Sekunden |

---

## 7. Speicherung & Datenschutz

**Alles bleibt lokal.** Zwei Ablageorte:

1. **Tracking-Daten** (Apps/Websites/Zeitleiste, eine Datei pro Tag):
   `~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json`
   Gespeichert **alle ~20 Sek** während des Trackings, bei Tageswechsel und beim
   **sauberen Beenden**; beim Start wird die Tagesdatei geladen.
2. **Konfiguration** (Kategorien, Projekte, Ziele, Einstellungen):
   macOS-`UserDefaults` unter `at.neoclarity.OpenTracker`
   (`~/Library/Preferences/at.neoclarity.OpenTracker.plist`) — sofort bei jeder
   Änderung geschrieben.

**Bleiben die Daten nach dem Schließen erhalten? → Ja.** Beim nächsten Start sind
sie wieder da.

Hinweise:
- **Sauber beenden** (⏻ im Panel) sichert alles. Bei **Absturz/Force-Quit** können
  die letzten **≤ 20 Sek** Tracking fehlen (Konfiguration nie betroffen).
- **Immer über die `.app`** starten — die Konfiguration hängt an der Bundle-ID.
  Die Tracking-JSONs sind davon unabhängig (fester Pfad) und immer dieselben.
- Daten sind an **Mac + Benutzerkonto** gebunden, **kein** Sync über mehrere Macs.
- Sichern/Ansehen: Finder → ⌘⇧G → `~/Library/Application Support/OpenTracker`.

---

## 8. Bekannte Einschränkungen

- Tage **vor** Einführung der Zeitleiste haben keine Kontextwechsel-/Pausendaten
  (zeigen dort 0).
- Die `.app` ist nur **ad-hoc signiert** → macOS fragt nach Neu-Builds ggf. erneut
  nach Berechtigungen. Für Verteilung an andere bräuchte es Signierung +
  Notarisierung (Apple Developer Account).
- Charts sind bewusst einfache Eigenbauten (keine Achsen-Interaktion/Zoom).
- Firefox: nur App-Ebene. Benachrichtigungen nur im `.app`-Build.
- **Dokumentwechsel** (innerhalb einer App, z. B. zwischen Dateien) sind noch
  nicht erfasst — siehe `ROADMAP.md`.

---

## 9. Architektur (Kurzüberblick)

Native **SwiftUI-Menübar-App** (SwiftPM-Paket).

```
Sources/OpenTracker/
├── App/        Einstieg, AppDelegate, Service-Container, Dashboard-Fenster
├── Models/     AppCategory, DayUsage, ActivitySegment, DayMetrics,
│               FocusAnalysis, Project, Goal, …
├── Services/   ActivityTracker, BrowserScripting, UsageStore, CategoryStore,
│               ProjectStore, GoalStore, PomodoroTimer, AppSettings, Notifier
├── Utilities/  Zeit-Formatierung
└── Views/      Panel, Pomodoro, Dashboard (Tag/Woche/Ziele/Verwalten),
                Insights, Fokus-Qualität, Ziele, Zeitleiste, …
Resources/Info.plist   Bundle-ID, LSUIElement, Browser-Berechtigung
Scripts/build-app.sh   baut das .app-Bundle
```

- **ActivityTracker** sampelt die Vordergrund-App; bei Browsern holt
  **BrowserScripting** die Domain. Zeit + eine Segment-Zeitleiste landen im
  **UsageStore**.
- **CategoryStore / ProjectStore / GoalStore** halten die Konfiguration
  (UserDefaults). Aus der Zeitleiste werden **DayMetrics** und **FocusAnalysis**
  berechnet.

Weiterführend: offene Features und Plan in **`ROADMAP.md`**.
