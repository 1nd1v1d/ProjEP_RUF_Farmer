# ProjEP Ruf Farmer

Ein leichtgewichtiges Addon für **Project Epoch** (WoW WotLK 3.3.5), das per **Minimap-Button** eine Übersicht aller Hauptstadtfraktionen anzeigt – mit Berechnung der benötigten **Runenstoffspenden** bis **Ehrfürchtig**.

Optional wird – sofern das Addon **ProjEP AH Trader** installiert ist – zusätzlich angezeigt, wie viel die benötigten Runenstoffe auf dem Auktionshaus kosten würden.

---

## Bedienung

- **Minimap-Button** (Runenstoff-Icon): **Klick** öffnet/schließt die Übersicht
- **Drag** des Buttons: verschiebt ihn entlang des Minimap-Rings (Position wird gespeichert)
- Das Info-Fenster ist **verschiebbar** (Drag am Fenstertitel)

---

## Info-Fenster

Das Fenster zeigt **alle** relevanten Hauptstadtfraktionen auf einmal:

| Spalte | Beschreibung |
|---|---|
| Fraktion | Name der Fraktion (grün = bereits Ehrfürchtig) |
| Stand | Aktuelle Ruf-Stufe |
| Fehl. Ruf | Verbleibende Ruf-Punkte bis Ehrfürchtig |
| Spenden | Benötigte Runenstoff-Abgaben (à 20 Runenstoff = 50 Ruf) |
| Runenstoff | Gesamtmenge Runenstoff |

Darunter:
- **Runenstoff gesamt** über alle Fraktionen zusammengefasst
- **AH-Kosten** (Preis pro Stück + Gesamtkosten) wenn ProjEP AH Trader vorhanden

---

## Rechenformel

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

---

## ProjEP AH Trader Integration

Wenn [ProjEP AH Trader](https://github.com/1nd1v1d/ProjEP_AH_Trader) installiert ist, erscheint im Info-Fenster:

```
Runenstoff gesamt:   11.180x
[AH Trader – gew. Durchschnitt]  Preis/Stk: 45s 20c
Gesamtkosten:  84g 17s 60c
```

---

## Installation

1. Ordner `ProjEP_RUF_Farmer` nach `...\Interface\AddOns\ProjEP_RUF_Farmer\` kopieren  
   oder `deploy.ps1` ausführen (deployt nach `C:\Ascension\Launcher\resources\epoch-live\Interface\AddOns\`)
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

Ein leichtgewichtiges Addon für **Project Epoch** (WoW WotLK 3.3.5), das beim Hovern über die Ruf-Leiste anzeigt, wie viele **Runenstoffspenden** noch benötigt werden, um den Ruf mit einer Hauptstadtfraktion auf **Ehrfürchtig** zu bringen.

Optional wird – sofern das Addon **ProjEP AH Trader** installiert ist – zusätzlich angezeigt, wie viel die benötigten Runenstoffe auf dem Auktionshaus kosten würden.

---

## Funktionsweise

Beim Hovern über den **Ruf-Balken** (unten links) wird der Tooltip um folgende Informationen erweitert – jedoch **nur bei Hauptstadtfraktionen**, die Runenstoffspenden annehmen:

| Zeile | Beschreibung |
|---|---|
| Fraktionsname + Standing | Aktueller Stand (z. B. „Wohlgesonnen 14072 / 21000") |
| Fehlender Ruf | Gesamte Ruf-Punkte bis Ehrfürchtig |
| Benötigte Spenden | Anzahl der nötigen 20er-Stapel-Abgaben (à 50 Ruf) |
| Runenstoff gesamt | Gesamtmenge Runenstoff |
| AH-Kosten *(optional)* | Preis und Gesamtkosten basierend auf AH-Trader-Daten |

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
