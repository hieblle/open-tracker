# OpenTracker — Status & Roadmap

> Stand: 2026-06-14 · Version 0.2 (Branch `claude/great-hopper-qupu5e`)
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
| Apps/Websites selbst einordnen | `ManagementView`, `ActivityRow` | Zentral im „Verwalten"-Tab + Schnell-Menü |
| Projekte (anlegen, zuordnen, auswerten) | `ProjectStore`, `ProjectBreakdownCard` | |
| Tages- & Wochenbericht | `DashboardView` (`DayDetailView`, `WeekDetailView`) | inkl. 7-Tage-Verlaufschart |
| Fokuszeit-Analyse | `DayMetrics` | Fokuszeit, Sessions ≥15 min, längste Phase |
| Kontextwechsel (App + Tab) | `FocusAnalysis` | App- vs. Tab-Wechsel getrennt |
| Meta-Analyse (Fragmentierung, Flow-Unterbrecher) | `FocusAnalysis`, `FocusQualitySection` | |
| Pausen-/Aktivitätsübersicht | `DayMetrics`, `TimelineStrip` | Pausen = Idle ≥ 2 min, farbige Tages-Zeitleiste |
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
| **Persönliche Ziele** (z. B. „max. 30 min Social/Tag", „min. 4 h Fokus") | hoch |
| **Dokumentwechsel** (#3, Accessibility) | hoch |
| **Monatsansicht / Langzeit-Trends** | mittel |
| **CSV-Export** | mittel |
| **Beim Anmelden starten** (Login-Item) | niedrig |
| Benannte Arbeitskategorien (Rize-Stil) — *optional, Projekte decken vieles ab* | niedrig |

### Bekannte Einschränkungen

- Historie: Tage **vor** der Zeitleisten-Einführung (Schritt 3) haben keine
  Kontextwechsel-/Pausendaten (zeigen dort 0).
- `.app` ist nur **ad-hoc signiert** → macOS fragt nach jedem Neu-Build ggf.
  erneut nach Berechtigungen. Für echte Verteilung bräuchte es Signierung +
  Notarisierung (Apple Developer Account).
- Charts sind bewusst einfache Eigenbauten (keine Achsen-Interaktion/Zoom).

---

## 2. Umsetzbarer Plan (offene Features)

Format je Feature: **Ziel · Ansatz · Schritte · Dateien · Aufwand · Berechtigung**.
Aufwand: S = klein (≈½ Tag), M = mittel (1 Tag), L = groß (mehrere Tage).

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
   Robust gegen `nil`/fehlende Rechte; Aufruf gedrosselt (nicht jeden Tick teuer).
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

**Risiken:** AX-APIs sind fummelig und hier (Linux) nicht testbar; Privatsphäre
sensibler → opt-in + transparente Erklärung.

---

### Persönliche Ziele  ·  Aufwand: M  ·  Berechtigung: keine

**Ziel:** Ziele definieren und Fortschritt sehen, z. B. „mindestens 4 h Fokus
heute", „höchstens 30 min Ablenkung", „max. 20 min auf youtube.com".

**Ansatz:** Einfaches Ziel-Modell + Fortschrittsberechnung aus den Tagesdaten.
Positiv/ermutigend formuliert (Reflexion, nicht Bestrafung).

**Schritte:**
1. `Models/Goal.swift`: `Goal { id, kind, targetSeconds }` mit
   `kind ∈ { focusAtLeast, distractingAtMost, categoryAtMost(rating),
   appAtMost(bundleId), domainAtMost(domain) }`.
2. `Services/GoalStore.swift` (`@Observable`, CRUD, Persistenz in UserDefaults).
3. Fortschritt: aus `UsageStore` (Fokus-/Ablenkungs-Sekunden, App/Domain-Zeit).
4. `Views/GoalsCard.swift`: Fortschrittsbalken je Ziel (z. B. „Fokus 2 h 10 / 4 h
   → 54 %", grün bei erreicht; bei „max"-Zielen Warnfarbe bei Überschreitung).
5. `ManagementView`: Ziele anlegen/entfernen.
6. Verdrahten: `AppModel` + `DashboardWindowController` injizieren `GoalStore`.
7. Optional: Benachrichtigung bei Ziel erreicht/überschritten.

**Dateien:** neu `Goal.swift`, `GoalStore.swift`, `GoalsCard.swift`;
ändern `AppModel`, `DashboardWindowController`, `DashboardView`, `ManagementView`.

---

### Monatsansicht / Langzeit-Trends  ·  Aufwand: S–M  ·  Berechtigung: keine

**Ziel:** Über Wochen hinaus: Monatsüberblick + Trend (mehr/weniger Fokus als
letzte Woche/Monat).

**Schritte:**
1. `UsageStore`: `recentDays(30)` existiert bereits; Aggregation per `merged(...)`.
2. `DashboardView`: Modus `.month` ergänzen; `MonthDetailView` mit 30-Tage-Balken
   (dünner; `WeeklyBarChart` generalisieren), Monats-`RatingSummaryCard`,
   `InsightsRow`, Projekt-/Fokus-Karten.
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

### Beim Anmelden starten (Login-Item)  ·  Aufwand: S  ·  Berechtigung: keine

**Ziel:** App startet automatisch beim Anmelden.

**Schritte:**
1. `Services/LoginItem.swift`: Wrapper um `SMAppService.mainApp`
   (`register()`/`unregister()`/`status`), nur wenn als `.app` (Bundle vorhanden).
2. `SettingsView`: Schalter „Beim Anmelden starten" (an `AppSettings` koppeln).

**Dateien:** neu `LoginItem.swift`; ändern `SettingsView`, evtl. `AppSettings`.

---

### Optional: benannte Arbeitskategorien (Rize-Stil)  ·  Aufwand: M

Heute: Bewertung (produktiv/neutral/ablenkend) + frei anlegbare **Projekte**.
Das deckt Gruppierung weitgehend ab. Falls eine feste Taxonomie gewünscht ist
(„Development", „Email", „Design" …), ließe sich `WorkCategory { name, rating }`
zwischen Aktivität und Bewertung einziehen. Eher Nice-to-have.

---

## 3. Empfohlene Reihenfolge

1. **Persönliche Ziele** (großer Mehrwert, keine neue Berechtigung) — M
2. **Monatsansicht + Trends** (rundet die Berichte ab) — S–M
3. **CSV-Export** (schnell, ermöglicht externe Analysen) — S
4. **#3 Dokumentwechsel** (größter Schritt, neue Berechtigung) — L
5. **Login-Item** (Komfort) — S
6. *(optional)* benannte Arbeitskategorien, App-Icon, signierte/notarisierte App

---

## 4. Mittelfristig / Politur

- App-Icon & Onboarding-Screen für Berechtigungen (Automation/Accessibility).
- Signierte + notarisierte `.app` für Verteilung an andere (Apple Developer Account).
- Daten-Retention/Erinnerungen („Wochenrückblick am Freitag").
- Editierbare Pomodoro-Auto-Start-Logik, Tagesnotiz/Reflexion am Abend.
