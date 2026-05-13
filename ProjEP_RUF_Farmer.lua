-- ============================================================
-- ProjEP Ruf Farmer
-- Zeigt benoetigte Runenstoffspenden fuer Hauptstadt-Fraktionen
-- bis Ehrfuerchtig beim Hovern ueber die Ruf-Leiste.
--
-- 20 Runenstoff = 50 Ruf pro Spende am Stadthalter-NPC
-- Optional: Preisanzeige via ProjEP_AH_Trader (gewichteter Ø)
--
-- Lua 5.1 (WotLK 3.3.5 / Project Epoch)
-- ============================================================

local ADDON_VERSION         = "1.0"
local RUNENSTOFF_PRO_SPENDE = 20
local RUF_PRO_SPENDE        = 50

-- Breite jeder Ruf-Stufe in Punkten
-- Wird benutzt um den fehlenden Ruf bis Ehrfuerchtig zu berechnen.
-- Stufen-Breiten sind in WotLK 3.3.5 identisch zu Vanilla.
local STUFEN_BREITE = {
    [1] = 36000,  -- Verhasst      (Hated)
    [2] = 3000,   -- Feindlich     (Hostile)
    [3] = 3000,   -- Unfreundlich  (Unfriendly)
    [4] = 3000,   -- Neutral
    [5] = 6000,   -- Freundlich    (Friendly)
    [6] = 12000,  -- Wohlgesonnen  (Honored)
    [7] = 21000,  -- Respektvoll   (Revered)
    -- [8] = Ehrfuerchtig (Exalted) = Ziel, keine weitere Stufe danach
}

-- Hauptstadt-Fraktionen die Runenstoffspenden annehmen
-- (Englisch + Deutsch)
local HAUPTSTADT_FRAKTIONEN = {
    -- Allianz / Alliance
    ["Stormwind"]          = true,
    ["Sturmwind"]          = true,
    ["Ironforge"]          = true,
    ["Eisenschmiede"]      = true,
    ["Darnassus"]          = true,
    ["Gnomeregan Exiles"]  = true,
    ["Gnomereganexil"]     = true,
    -- Horde
    ["Orgrimmar"]          = true,
    ["Thunder Bluff"]      = true,
    ["Donnerfels"]         = true,
    ["Undercity"]          = true,
    ["Unterstadt"]         = true,
    ["Darkspear Trolls"]   = true,
    ["Dunkelspeer-Trolle"] = true,
}

-- Moegliche Item-Namen fuer Runenstoff (Englisch + Deutsch)
local RUNENSTOFF_ITEM_NAMEN = { "Runecloth", "Runenstoff" }

-- ── Hilfsfunktionen ──────────────────────────────────────────

-- Formatiert einen Kupfer-Betrag als farbigen Gold/Silber/Kupfer-String
-- Lua 5.1: mod() existiert nicht mehr, stattdessen %-Operator
local function FormatMoney(copper)
    copper = math.floor(copper)
    if copper <= 0 then return "|cFFAD8B610c|r" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    local out = ""
    if g > 0 then
        out = out .. "|cFFFFD700" .. g .. "g|r "
    end
    if s > 0 or g > 0 then
        out = out .. "|cFFC0C0C0" .. s .. "s|r "
    end
    out = out .. "|cFFAD8B61" .. c .. "c|r"
    return out
end

-- Gibt den besten verfuegbaren Preis (Kupfer/Stueck) fuer Runenstoff
-- aus dem ProjEP_AH_Trader zurueck.
-- Prioritaet: 1. gewichteter Durchschnitt (GetPriceAverage)
--             2. aktuell guenstigster Scan-Preis (prices)
-- Rueckgabe: preis (Kupfer), quellenbezeichnung (String), oder nil, nil
local function GetRunenstoffAHPreis()
    if not PROJEP_AHT then return nil, nil end
    for _, name in ipairs(RUNENSTOFF_ITEM_NAMEN) do
        -- 1. Gewichteter Durchschnitt aus Scan-Verlauf
        if PROJEP_AHT.GetPriceAverage then
            local avg = PROJEP_AHT:GetPriceAverage(name)
            if avg and avg > 0 then
                return avg, "gew. Durchschnitt"
            end
        end
        -- 2. Fallback: aktuell guenstigster Preis aus letztem Scan
        if PROJEP_AHT.prices then
            local cur = PROJEP_AHT.prices[name]
            if cur and cur > 0 then
                return cur, "akt. Preis"
            end
        end
    end
    return nil, nil
end

-- Berechnet benoetigte Runenstoff-Spenden und fehlende Ruf-Punkte bis
-- Ehrfuerchtig (standingId 8).
-- standingId : aktuelle Ruf-Stufe (1-7)
-- barMax     : Maximum-Wert der aktuellen Stufe
-- barValue   : aktueller Wert in der Stufe
-- Rueckgabe  : spenden (Anzahl), verbleibend (Ruf-Punkte)
local function BerechneSpendenBedarf(standingId, barMax, barValue)
    if standingId >= 8 then return 0, 0 end

    -- Verbleibende Punkte in der aktuellen Stufe
    local verbleibend = barMax - barValue

    -- Alle folgenden Stufen bis einschliesslich Respektvoll (7) addieren
    for i = standingId + 1, 7 do
        verbleibend = verbleibend + (STUFEN_BREITE[i] or 0)
    end

    local spenden = math.ceil(verbleibend / RUF_PRO_SPENDE)
    return spenden, verbleibend
end

-- Stehens-Namen fuer die Tooltip-Kopfzeile
local STANDING_NAMEN = {
    [1] = "Verhasst",
    [2] = "Feindlich",
    [3] = "Unfreundlich",
    [4] = "Neutral",
    [5] = "Freundlich",
    [6] = "Wohlgesonnen",
    [7] = "Respektvoll",
    [8] = "Ehrfuerchtig",
}

-- ── Tooltip-Aufbau ────────────────────────────────────────────

local _origRepBarOnEnter = nil

-- WotLK 3.3.5: SetScript-Handler erhaelt self als erstes Argument (kein globales "this").
-- GetWatchedFactionInfo() gibt in WotLK zurueck:
--   name, description, standingID, barMin, barMax, barValue, factionID
-- (Vanilla hatte: name, standingId, barMin, barMax, barValue)
local function RepBar_OnEnter(self)
    local name, _, standingId, barMin, barMax, barValue = GetWatchedFactionInfo()

    -- Kein Ruf beobachtet oder keine Hauptstadtfraktion -> Original-Handler aufrufen
    if not name or not HAUPTSTADT_FRAKTIONEN[name] then
        if _origRepBarOnEnter then
            _origRepBarOnEnter(self)
        end
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    -- Kopfzeile: Fraktionsname + aktueller Stand
    GameTooltip:AddLine(name, 1, 1, 1)
    local standingText = STANDING_NAMEN[standingId] or "Unbekannt"
    GameTooltip:AddDoubleLine(
        standingText,
        barValue .. " / " .. barMax,
        0.9, 0.9, 0.9,
        0.8, 0.8, 0.8
    )

    GameTooltip:AddLine(" ")

    if standingId >= 8 then
        GameTooltip:AddLine("|cFF00FF00Bereits Ehrfuerchtig!|r")
    else
        local spenden, verbleibend = BerechneSpendenBedarf(standingId, barMax, barValue)
        local runenstoff = spenden * RUNENSTOFF_PRO_SPENDE

        GameTooltip:AddLine("|cFFFFD700Runenstoffspenden bis Ehrfuerchtig:|r")

        if standingId < 4 then
            GameTooltip:AddLine("|cFFFF8080(Spenden erst ab Neutral moeglich)|r")
        end

        GameTooltip:AddDoubleLine(
            "Fehlender Ruf:",
            verbleibend .. " Punkte",
            0.9, 0.9, 0.9,
            1.0, 1.0, 0.5
        )
        GameTooltip:AddDoubleLine(
            "Benoetigte Spenden:",
            spenden .. "x  (a 20 Runenstoff = 50 Ruf)",
            0.9, 0.9, 0.9,
            0.4, 1.0, 0.4
        )
        GameTooltip:AddDoubleLine(
            "Runenstoff gesamt:",
            runenstoff .. "x",
            0.9, 0.9, 0.9,
            1.0, 0.65, 0.0
        )

        -- ── ProjEP_AH_Trader Integration ──────────────────────
        local avgPreis, quelle = GetRunenstoffAHPreis()
        if avgPreis then
            local gesamtkosten = avgPreis * runenstoff
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00CCFF[AH Trader] Kaufkosten (" .. quelle .. "):|r")
            GameTooltip:AddDoubleLine(
                "Preis pro Runenstoff:",
                FormatMoney(avgPreis),
                0.7, 0.9, 1.0,
                1.0, 1.0, 1.0
            )
            GameTooltip:AddDoubleLine(
                "Gesamtkosten (" .. runenstoff .. "x):",
                FormatMoney(gesamtkosten),
                0.7, 0.9, 1.0,
                1.0, 0.9, 0.3
            )
        end
    end

    GameTooltip:Show()
end

local function RepBar_OnLeave(self)
    GameTooltip:Hide()
end

-- ── Initialisierung ───────────────────────────────────────────

local function HookRepBar()
    if not ReputationWatchBar then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080[ProjEP Ruf Farmer]|r ReputationWatchBar nicht gefunden!")
        return
    end
    -- Original-Handler sichern, damit nicht-Hauptstadtfraktionen normal funktionieren
    _origRepBarOnEnter = ReputationWatchBar:GetScript("OnEnter")
    ReputationWatchBar:SetScript("OnEnter", RepBar_OnEnter)
    ReputationWatchBar:SetScript("OnLeave", RepBar_OnLeave)
end

-- ── Globale Event-Funktionen fuer ProjEP_RUF_Farmer.xml ──────
-- XML-Frame ist auf Project Epoch zuverlaessiger als CreateFrame in Lua.

function ProjEP_RUF_Farmer_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function ProjEP_RUF_Farmer_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        HookRepBar()
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFF00CCFF[ProjEP Ruf Farmer]|r v" .. ADDON_VERSION .. " geladen."
        )
    end
end
