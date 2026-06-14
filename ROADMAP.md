# OpenTracker — Status & Roadmap

> Stand: 2026-06-14 · Version 0.3 (Branch `claude/great-hopper-qupu5e`)
> Leitprinzip: **privates Reflexionswerkzeug**, kein Kontroll-/Monitoring-Tool.
> Alle Daten bleiben lokal auf dem Mac.

Dieses Dokument prüft alle bisher gewünschten Features gegen den aktuellen
Code-Stand und beschreibt für alles Offene einen konkreten, umsetzbaren Plan.

---

## 1. Status-Check (Soll vs. Ist)

### ✅ Gut umgesetzt

| Feature | Wo im Code | Anmerkung |
|---|---|---|
| Automatisches Hintergrund-Tracking (5-Sek-Takt, idle-aware) | `ActivityTracker` | Läuft als Menübar-Agent |
| App-Erkennung | `ActivityTracker` (NSWorkspace) | Keine Sonderrechte nötig |
| Website-Erkennung (Domain) | `BrowserScripting` | Safari/Chrome/Arc/Brave/Edge |
| Produktiv / Neutral / Ablenkung | `AppCategory`, `CategoryStore` | Presets + eigene Overrides |
| Apps/Websites selbst einordnen | `ManagementView`, `ActivityRow` | „Verwalten"-Tab + Schnell-Menü |
| Projekte (anlegen, zuordnen, auswerten) | `ProjectStore`, `ProjectBreakdownCard` | |
| Tages- & Wochenbericht | `DashboardView` | inkl. 7-Tage-Verlaufschart |
| Fokuszeit-Analyse | `DayMetrics` | Fokuszeit, Sessions, längste Phase |
| **Fokus-Unterbrechungs-Analyse** | `FocusAnalysis`, `FocusQualitySection` | zählt nur echte Unterbrechungen von Fokusphasen, nicht produktive Wechsel; nach Ursache (Ablenkung/Neutral/Pause) |
| **Einstellbare Fokusphasen-Schwelle** | `AppSettings`, `SettingsView` | Default 15 min, 5–60 min |
| **Manuelle Marker: Pause & Externe Ablenkung** | `ActivityTracker`, `PanelView` | Menüleisten-Buttons; Erholung = neutral, externe Ablenkung = Ablenkung |
| Pausen-/Aktivitätsübersicht | `DayMetrics`, `TimelineStrip` | Pausen (auto + manuell), farbige Tages-Zeitleiste |
| **Persönliche Ziele** | `Goal`, `GoalStore`, `GoalsView`, `GoalsCard` | Vorlagen + eigene Ziele (min/max), Tagesfortschritt |
| Lokale, privacy-freundliche Speicherung | `UsageStore` (JSON), `UserDefaults` | `~/Library/Application Support/OpenTracker/` |
| Pomodoro-Timer | `PomodoroTimer`, `PomodoroView` | Menübar-Countdown |
| Echte `.app` + Benachrichtigungen | `Scripts/build-app.sh`, `Notifier` | Bundle-ID + Automation-Recht |
| Dashboard mit Charts/Statistiken | `DashboardView` u. a. | Eigenbau-Charts (dependency-frei) |

### ⚠️ Teilweise umgesetzt

| Feature | Stand | Was fehlt |
|---|---|---|
| **Kontextwechsel-Analyse** | App- + Tab-Wechsel ✅ | **Dokumentwechsel** (Fenster-/Dokumenttitel) — siehe #3 |
| Tab-Wechsel | Domain-genau (`github.com`) | Seiten-/Tab-genau (gleiche Domain, anderer Tab) braucht Tab-Titel |
| Benachrichtigungen | via `.app`-Build ✅ | via `swift run` deaktiviert (kein Bundle) — by design |
| Browser-Abdeckung | Safari/Chrome/Arc/Brave/Edge ✅ | Firefox nur App-Ebene (kein URL-Scripting) |

### ❌ Fehlt noch

| Feature | Priorität (Vorschlag) |
|---|---|
| **Monatsansicht / Langzeit-Trends** | hoch |
| **CSV-Export** | mittel |
| **Dokumentwechsel** (#3, Accessibility) | mittel |
| **Beim Anmelden starten** (Login-Item) | niedrig |
| Benannte Arbeitskategorien (Rize-Stil) — *optional, Projekte decken vieles ab* | niedrig |

### Bekannte Einschränkungen

- Historie: Tage **vor** der Zeitleisten-Einführung haben keine Kontextwechsel-/
  Pausendaten (zeigen dort 0).
- `.app` ist nur **ad-hoc signiert** → macOS fragt nach jedem Neu-Build ggf.
  erneut nach Berechtigungen. Für echte Verteilung bräuchte es Signierung +
  Notarisierung (Apple Developer Account).
- Charts sind bewusst einfache Eigenbauten (keine Achsen-Interaktion/Zoom).

---

## 2. Umsetzbarer Plan (offene Features)

Format je Feature: **Ziel · Ansatz · Schritte · Dateien · Aufwand · Berechtigung**.
Aufwand: S = klein (≈½ Tag), M = mittel (1 Tag), L = groß (mehrere Tage).

---

### Monatsansicht / Langzeit-Trends  ·  Aufwand: S–M  ·  Berechtigung: keine

**Ziel:** Über Wochen hinaus: Monatsüberblick + Trend (mehr/weniger Fokus als
letzte Woche/Monat).

**Schritte:**
1. `UsageStore`: `recentDays(30)` existiert bereits; Aggregation per `merged(...)`.
2. `DashboardView`: Modus `.month` ergänzen; `MonthDetailView` mit 30-Tage-Balken
   (dünner; `WeeklyBarChart` generalisieren), Monats-`RatingSummaryCard`,
   `InsightsRow`, Projekt-/Fokus-/Ziel-Karten.
3. Trend: aktuelle Periode vs. vorige (z. B. Fokus diese Woche vs. Vorwoche), als
   kleine ↑/↓-Anzeige in den `StatTile`s.

**Dateien:** ändern `DashboardView`, ggf. `WeeklyBarChart` (Parameter für Balkenzahl).

---

### CSV-Export  ·  Aufwand: S  ·  Berechtigung: keine

**Ziel:** Rohdaten exportieren für eigene Auswertungen (Excel/Numbers/Python).

**Schritte:**
1. `Services/CSVExporter.swift`: Zeilen `datum,typ,name,kategorie,projekt,sekunden`
   über einen Zeitraum (z. B. alle vorhandenen Tage) erzeugen.
2. UI-Button in `ManagementView` oder `SettingsView`: `NSSavePanel` → Datei schreiben.
3. Optional zweite Datei: Segment-Timeline (`start,end,typ,name`) für Detailanalyse.

**Dateien:** neu `CSVExporter.swift`; ändern `ManagementView`/`SettingsView`.

---

### #3 — Dokumentwechsel sichtbar machen  ·  Aufwand: L  ·  Berechtigung: Accessibility

**Ziel:** Kontextwechsel auf drei Ebenen getrennt zeigen: **App** · **Tab** ·
**Dokument** (Wechsel *innerhalb* einer App, z. B. zwischen zwei Dateien in
VS Code, zwei E-Mails, zwei Notion-Seiten).

**Ansatz:** Den Titel des aktiven Fensters auslesen. Das geht auf macOS nur über
die **Accessibility-API** (AX), die eine eigene TCC-Berechtigung braucht
(*Systemeinstellungen → Datenschutz → Bedienungshilfen*). Eine Titeländerung bei
gleichbleibender App = Dokumentwechsel.

**Schritte:**
1. `Services/AccessibilityPermission.swift`: Status prüfen & anfragen via
   `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`.
2. `Services/WindowTitleReader.swift`: für die frontmost-App-PID
   `AXUIElementCreateApplication` → `kAXFocusedWindowAttribute` → `kAXTitleAttribute`.
   Robust gegen `nil`/fehlende Rechte; Aufruf gedrosselt.
3. Datenmodell: `ActivitySegment.Kind.app` um `windowTitle: String?` erweitern
   (Codable-Migration via `decodeIfPresent`).
4. `ActivityTracker`: Titel je Sample erfassen; Titelwechsel bei gleicher App →
   Dokumentwechsel zählen.
5. `FocusAnalysis`: `documentSwitches` ergänzen; Klassifikation App/Tab/Dokument.
6. `FocusQualitySection`: Kachel „Dokumentwechsel" + optional „Top-Dokumente,
   zwischen denen du gesprungen bist".
7. `SettingsView`: Schalter/Onboarding „Dokument-Tracking aktivieren" (fragt das
   Recht an), klar erklärt (Titel können Dateinamen/Betreffs enthalten, bleiben lokal).
8. Feinere **Tab-Wechsel** gleich mitnehmen: in `BrowserScripting` zusätzlich den
   Tab-Titel holen → Tab-Wechsel auf Seitenebene statt nur Domain.

**Dateien:** neu `AccessibilityPermission.swift`, `WindowTitleReader.swift`;
ändern `ActivitySegment`, `ActivityTracker`, `UsageStore` (FocusAnalysis),
`FocusQualitySection`, `SettingsView`, `BrowserScripting`.

**Risiken:** AX-APIs sind fummelig; Privatsphäre sensibler → opt-in + transparente
Erklärung.

---

### Beim Anmelden starten (Login-Item)  ·  Aufwand: S  ·  Berechtigung: keine

**Ziel:** App startet automatisch beim Anmelden.

**Schritte:**
1. `Services/LoginItem.swift`: Wrapper um `SMAppService.mainApp`
   (`register()`/`unregister()`/`status`), nur wenn als `.app` (Bundle vorhanden).
2. `SettingsView`: Schalter „Beim Anmelden starten" (an `AppSettings` koppeln).

**Dateien:** neu `LoginItem.swift`; ändern `SettingsView`, evtl. `AppSettings`.

---

### Optional: benannte Arbeitskategorien (Rize-Stil)  ·  Aufwand: M

Heute: Bewertung (produktiv/neutral/ablenkend) + frei anlegbare **Projekte** +
**Ziele**. Das deckt Gruppierung weitgehend ab. Falls eine feste Taxonomie
gewünscht ist („Development", „Email", „Design" …), ließe sich
`WorkCategory { name, rating }` zwischen Aktivität und Bewertung einziehen.
Eher Nice-to-have.

---

## 3. Empfohlene Reihenfolge

1. **Monatsansicht + Trends** (rundet die Berichte ab) — S–M
2. **CSV-Export** (schnell, ermöglicht externe Analysen) — S
3. **#3 Dokumentwechsel** (größter Schritt, neue Berechtigung) — L
4. **Login-Item** (Komfort) — S
5. *(optional)* benannte Arbeitskategorien, App-Icon, signierte/notarisierte App

### ✅ Bereits erledigt (frühere Roadmap-Punkte)

- Persönliche Ziele (Vorlagen + eigene, Tagesfortschritt)
- Fokus-Unterbrechungs-Analyse (statt roher Kontextwechsel)
- Manuelle Pause-/Ablenkungs-Marker
- Einstellbare Fokusphasen-Schwelle

---

## 4. Mittelfristig / Politur

- App-Icon & Onboarding-Screen für Berechtigungen (Automation/Accessibility).
- Signierte + notarisierte `.app` für Verteilung an andere (Apple Developer Account).
- Daten-Retention/Erinnerungen („Wochenrückblick am Freitag").
- Tagesnotiz/Reflexion am Abend, Ziel-Benachrichtigungen.
