# ProjEP Ruf Farmer

Ein leichtgewichtiges Addon für **Project Epoch** (WoW WotLK 3.3.5), das per **Minimap-Button** eine Übersicht aller Hauptstadtfraktionen anzeigt – mit Berechnung der benötigten **Runenstoffspenden** bis **Ehrfürchtig** inklusive Kostenabschätzung je Fraktion.

Optional wird – sofern das Addon **ProjEP AH Trader** installiert ist – zusätzlich der aktuelle AH-Preis für Runenstoff einbezogen.

---

## Bedienung

| Aktion | Funktion |
|---|---|
| **Klick** auf Minimap-Button | Info-Fenster öffnen / schließen |
| **Drag** des Minimap-Buttons | Position entlang des Minimap-Rings verschieben (wird gespeichert) |
| **Drag** am Info-Fenster-Titel | Fenster frei verschieben |
| **X**-Button im Info-Fenster | Fenster schließen |

---

## Info-Fenster

Das Fenster zeigt **alle** relevanten Hauptstadtfraktionen auf einmal in einer Tabelle:

| Spalte | Beschreibung |
|---|---|
| **Fraktion** | Name der Fraktion (grün = bereits Ehrfürchtig) |
| **Stand** | Aktuelle Ruf-Stufe |
| **Fehl. Ruf** | Verbleibende Ruf-Punkte bis Ehrfürchtig |
| **Spenden** | Benötigte Runenstoff-Abgaben (à 20 Stk = 50 Ruf) |
| **Runenstoff** | Benötigte Runenstoff-Menge für diese Fraktion |
| **Gesamtkosten** | AH-Kosten für diese Fraktion (benötigt ProjEP AH Trader) |

Unter der Tabelle erscheint eine Zusammenfassung:
- **Runenstoff gesamt** – Summe über alle nicht-Ehrfürchtigen Fraktionen
- **Preis pro Stück** – aus AH Trader (gewichteter Durchschnitt oder aktueller Scan)
- **Gesamtkosten gesamt** – Gesamtbetrag für alle Fraktionen zusammen

---

## Rechenformel

```
verbleibender Ruf = (barMax − barValue) + Summe der Stufen-Breiten bis Respektvoll
Spenden           = ceil(verbleibender Ruf / 50)
Runenstoff        = Spenden × 20
Gesamtkosten      = Runenstoff × Preis/Stk (aus AH Trader)
```

Ruf-Stufen-Breiten (WotLK 3.3.5 – identisch zu Vanilla):

| Stufe | Punkte |
|---|---|
| Verhasst | 36.000 |
| Feindlich | 3.000 |
| Unfreundlich | 3.000 |
| Neutral | 3.000 |
| Freundlich | 6.000 |
| Wohlgesonnen | 12.000 |
| Respektvoll | 21.000 |

---

## Unterstützte Fraktionen

### Allianz
- Stormwind / Sturmwind
- Ironforge / Eisenschmiede
- Darnassus
- Gnomeregan Exiles / Gnomereganexil

### Horde
- Orgrimmar
- Thunder Bluff / Donnerfels
- Undercity / Unterstadt
- Darkspear Trolls / Dunkelspeer-Trolle

> Alle anderen Fraktionen werden ignoriert.

---

## ProjEP AH Trader Integration

Wenn [ProjEP AH Trader](https://github.com/1nd1v1d/ProjEP_AH_Trader) installiert ist, wird der Runenstoff-Preis automatisch eingelesen und für jede Fraktion einzeln sowie gesamt ausgewiesen:

```
Fraktion          Stand          Fehl.Ruf   Spenden   Runenstoff   Gesamtkosten
Orgrimmar         Wohlgesonnen   18.928     379x      7.580x       56g 42s 60c
Undercity         Neutral        42.000     840x      16.800x      125g 16s 00c
...

Runenstoff gesamt: 24.380x
[AH Trader – gew. Durchschnitt]  Preis/Stk: 45s 20c
Gesamtkosten gesamt: 181g 58s 60c
```

**Preisquelle (Priorität):**
1. **Gewichteter Durchschnitt** – aus der Scan-Historie (`PROJEP_AHT:GetPriceAverage`)
2. **Aktueller Scan-Preis** – günstigster Buyout aus dem letzten Scan (`PROJEP_AHT.prices`)

Ohne AH Trader werden Gesamtkosten-Spalten als `–` angezeigt.

---

## Installation

1. Ordner `ProjEP_RUF_Farmer` nach `...\Interface\AddOns\ProjEP_RUF_Farmer\` kopieren  
   **oder** `deploy.ps1` ausführen (deployt automatisch nach `C:\Ascension\Launcher\resources\epoch-live\Interface\AddOns\`)
2. WoW starten, Addon im Addon-Menü aktivieren

---

## Technische Details

| Eigenschaft | Wert |
|---|---|
| Plattform | Project Epoch (WotLK 3.3.5a) |
| Interface | `30300` |
| Lua-Version | 5.1 |
| SavedVariables | `ProjEP_RUF_Farmer_DB` (Minimap-Button-Position) |
| Abhängigkeiten | keine (ProjEP_AH_Trader optional) |

### Unterschiede zu TWOW_RUF_Farmer (Vanilla 1.12.1)

| Aspekt | TWOW_RUF_Farmer | ProjEP_RUF_Farmer |
|---|---|---|
| Interface | 11200 | 30300 |
| Lua | 5.0 (`mod()`) | 5.1 (`%`) |
| Bedienung | Mouseover Ruf-Balken | Minimap-Button + Info-Fenster |
| Anzeige | Tooltip (nur beobachtete Fraktion) | Tabelle aller Hauptstadtfraktionen |
| Gesamtkosten je Fraktion | nein | ja |
| Event-Frame | `CreateFrame` in Lua | XML-Frame |
| AH-Trader | TWOW_AH_Trader | ProjEP_AH_Trader |

### Rechenformel

```
verbleibender Ruf = (barMax − barValue) + Summe der Stufen-Breiten bis Respektvoll
Spenden           = ceil(verbleibender Ruf / 50)
Runenstoff        = Spenden × 20
```

Ruf-Stufen-Breiten (WotLK 3.3.5 – identisch zu Vanilla):

| Stufe | Punkte |
|---|---|
| Verhasst | 36.000 |
| Feindlich | 3.000 |
| Unfreundlich | 3.000 |
| Neutral | 3.000 |
| Freundlich | 6.000 |
| Wohlgesonnen | 12.000 |
| Respektvoll | 21.000 |

---

## Unterstützte Fraktionen

### Allianz
- Stormwind / Sturmwind
- Ironforge / Eisenschmiede
- Darnassus
- Gnomeregan Exiles / Gnomereganexil

### Horde
- Orgrimmar
- Thunder Bluff / Donnerfels
- Undercity / Unterstadt
- Darkspear Trolls / Dunkelspeer-Trolle

> Alle anderen Fraktionen werden ignoriert – der Standard-WoW-Tooltip bleibt unverändert.

---

## ProjEP AH Trader Integration

Wenn das Addon [ProjEP AH Trader](https://github.com/1nd1v1d/ProjEP_AH_Trader) installiert ist, wird der Tooltip um einen Kostenblock erweitert:

```
[AH Trader] Kaufkosten (gew. Durchschnitt):
  Preis pro Runenstoff:   45s 20c
  Gesamtkosten (11180x):  84g 17s 60c
```

**Preisquelle (Priorität):**
1. **Gewichteter Durchschnitt** – wird aus der Scan-Historie berechnet (`PROJEP_AHT:GetPriceAverage`)
2. **Aktueller Scan-Preis** – günstigster Buyout aus dem letzten Einzelscan (`PROJEP_AHT.prices`)

---

## Installation

1. Ordner `ProjEP_RUF_Farmer` nach  
   `...\Interface\AddOns\ProjEP_RUF_Farmer\` kopieren  
   oder `deploy.ps1` ausführen (deployt nach `C:\Ascension\Launcher\resources\epoch-live\Interface\AddOns\`)
2. WoW starten, Addon im Addon-Menü aktivieren

---

## Technische Details

| Eigenschaft | Wert |
|---|---|
| Plattform | Project Epoch (WotLK 3.3.5a) |
| Interface | `30300` |
| Lua-Version | 5.1 |
| SavedVariables | keine |
| Abhängigkeiten | keine (ProjEP_AH_Trader optional) |

### Unterschiede zu TWOW_RUF_Farmer (Vanilla 1.12.1)

| Aspekt | TWOW_RUF_Farmer | ProjEP_RUF_Farmer |
|---|---|---|
| Interface | 11200 | 30300 |
| Lua | 5.0 (`mod()`) | 5.1 (`%`) |
| Event-Handler | globales `this` / `event` | `self, event, ...` Parameter |
| `GetWatchedFactionInfo` | 5 Rückgabewerte | 7 Rückgabewerte (+ `description`, `factionID`) |
| Event-Frame | `CreateFrame` in Lua | XML-Frame (zuverlässiger auf Project Epoch) |
| AH-Trader | TWOW_AH_Trader | ProjEP_AH_Trader |
