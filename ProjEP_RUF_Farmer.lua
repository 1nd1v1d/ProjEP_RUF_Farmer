-- ============================================================
-- ProjEP Ruf Farmer
-- Minimap-Button + Info-Fenster fuer Runenstoffspenden
-- bis Ehrfuerchtig bei allen Hauptstadt-Fraktionen
--
-- 20 Runenstoff = 50 Ruf pro Spende am Stadthalter-NPC
-- Optional: Preisanzeige via ProjEP_AH_Trader (gewichteter Ø)
--
-- Lua 5.1 (WotLK 3.3.5 / Project Epoch)
-- ============================================================

local ADDON_VERSION         = "1.0"
local RUNENSTOFF_PRO_SPENDE = 20
local RUF_PRO_SPENDE        = 50

-- Breite jeder Ruf-Stufe in Punkten (WotLK 3.3.5 = Vanilla-Werte)
local STUFEN_BREITE = {
    [1] = 36000,  -- Verhasst
    [2] = 3000,   -- Feindlich
    [3] = 3000,   -- Unfreundlich
    [4] = 3000,   -- Neutral
    [5] = 6000,   -- Freundlich
    [6] = 12000,  -- Wohlgesonnen
    [7] = 21000,  -- Respektvoll
}

-- Hauptstadt-Fraktionen die Runenstoffspenden annehmen (EN + DE)
local HAUPTSTADT_FRAKTIONEN = {
    ["Stormwind"]          = true,  ["Sturmwind"]          = true,
    ["Ironforge"]          = true,  ["Eisenschmiede"]      = true,
    ["Darnassus"]          = true,
    ["Gnomeregan Exiles"]  = true,  ["Gnomereganexil"]     = true,
    ["Orgrimmar"]          = true,
    ["Thunder Bluff"]      = true,  ["Donnerfels"]         = true,
    ["Undercity"]          = true,  ["Unterstadt"]         = true,
    ["Darkspear Trolls"]   = true,  ["Dunkelspeer-Trolle"] = true,
}

local RUNENSTOFF_ITEM_NAMEN = { "Runecloth", "Runenstoff" }

local STANDING_NAMEN = {
    [1]="Verhasst", [2]="Feindlich", [3]="Unfreundlich", [4]="Neutral",
    [5]="Freundlich", [6]="Wohlgesonnen", [7]="Respektvoll", [8]="Ehrfuerchtig",
}

-- ── Hilfsfunktionen ──────────────────────────────────────────

local function FormatMoney(copper)
    copper = math.floor(copper)
    if copper <= 0 then return "|cFFAD8B610c|r" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    local out = ""
    if g > 0 then out = out .. "|cFFFFD700" .. g .. "g|r " end
    if s > 0 or g > 0 then out = out .. "|cFFC0C0C0" .. s .. "s|r " end
    out = out .. "|cFFAD8B61" .. c .. "c|r"
    return out
end

local function GetRunenstoffAHPreis()
    if not PROJEP_AHT then return nil, nil end
    for _, name in ipairs(RUNENSTOFF_ITEM_NAMEN) do
        if PROJEP_AHT.GetPriceAverage then
            local avg = PROJEP_AHT:GetPriceAverage(name)
            if avg and avg > 0 then return avg, "gew. Durchschnitt" end
        end
        if PROJEP_AHT.prices then
            local cur = PROJEP_AHT.prices[name]
            if cur and cur > 0 then return cur, "akt. Preis" end
        end
    end
    return nil, nil
end

local function BerechneSpendenBedarf(standingId, barMax, barValue)
    if standingId >= 8 then return 0, 0 end
    local verbleibend = barMax - barValue
    for i = standingId + 1, 7 do
        verbleibend = verbleibend + (STUFEN_BREITE[i] or 0)
    end
    return math.ceil(verbleibend / RUF_PRO_SPENDE), verbleibend
end

-- ── Fraktionsdaten sammeln ────────────────────────────────────
-- Iteriert GetFactionInfo() und filtert Hauptstadtfraktionen.
-- GetFactionInfo(i) in WotLK 3.3.5:
--   name, description, standingId, barMin, barMax, barValue,
--   atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep,
--   isWatched, isChild, factionID, hasBonusRepGain, canBeBonusRep
local function GetFactionData()
    local results  = {}
    local seen     = {}   -- Deduplizierung: gleiche Fraktion per EN+DE-Namen
    local numFacts = GetNumFactions()
    for i = 1, numFacts do
        local name, _, standingId, _, barMax, barValue, _, _, isHeader = GetFactionInfo(i)
        if name and not isHeader and HAUPTSTADT_FRAKTIONEN[name] then
            -- Deduplizieren ueber barMax+barValue+standingId (EN und DE haben identische Werte)
            local key = standingId .. ":" .. barMax .. ":" .. barValue
            if not seen[key] then
                seen[key] = true
                table.insert(results, {
                    name       = name,
                    standingId = standingId,
                    barMax     = barMax,
                    barValue   = barValue,
                })
            end
        end
    end
    return results
end

-- ── Info-Fenster ─────────────────────────────────────────────

local INFO_W   = 660
local MAX_ROWS = 10   -- max gleichzeitig angezeigte Fraktionen

local infoFrame = nil
local rowCells  = {}  -- [rowIdx][colIdx] = FontString

-- Spalten: Fraktion | Stand | Fehl.Ruf | Spenden | Runenstoff | Gesamtkosten
local COL_X = { 14, 155, 258, 338, 398, 458 }
local COL_W = { 138, 100,  76,  57,  57, 185 }
local COL_H = { "LEFT", "RIGHT", "RIGHT", "RIGHT", "RIGHT", "RIGHT" }

local function CreateInfoFrame()
    infoFrame = CreateFrame("Frame", "ProjEP_RUF_Farmer_InfoFrame", UIParent)
    infoFrame:SetWidth(INFO_W)
    infoFrame:SetHeight(80 + MAX_ROWS * 22 + 85)
    infoFrame:SetPoint("CENTER", UIParent, "CENTER")
    infoFrame:SetFrameStrata("HIGH")
    infoFrame:SetMovable(true)
    infoFrame:EnableMouse(true)
    infoFrame:RegisterForDrag("LeftButton")
    infoFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    infoFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    infoFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    -- Titel
    local title = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cFF00CCFFProjEP Ruf Farmer|r")

    -- Schliessen-Button
    local closeBtn = CreateFrame("Button", nil, infoFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Spalten-Header
    local HEADER_Y = -42
    local headers  = { "Fraktion", "Stand", "Fehl. Ruf", "Spenden", "Runenstoff", "Gesamtkosten" }
    for i, h in ipairs(headers) do
        local fs = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", COL_X[i], HEADER_Y)
        fs:SetWidth(COL_W[i])
        fs:SetJustifyH(COL_H[i])
        fs:SetText("|cFFFFD700" .. h .. "|r")
    end

    -- Trennlinie unter Header
    local sep1 = infoFrame:CreateTexture(nil, "ARTWORK")
    sep1:SetTexture(0.4, 0.4, 0.4, 0.9)
    sep1:SetPoint("TOPLEFT",  14, HEADER_Y - 16)
    sep1:SetPoint("TOPRIGHT", -14, HEADER_Y - 16)
    sep1:SetHeight(1)

    -- Fraktions-Zeilen (vorgefertigt, per PopulateInfoFrame befuellt)
    for row = 1, MAX_ROWS do
        rowCells[row] = {}
        local rowY = HEADER_Y - 20 - (row - 1) * 22
        for col = 1, 6 do
            local fs = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("TOPLEFT", COL_X[col], rowY)
            fs:SetWidth(COL_W[col])
            fs:SetJustifyH(COL_H[col])
            rowCells[row][col] = fs
        end
    end

    -- Trennlinie vor Gesamt-Block
    infoFrame.sep2 = infoFrame:CreateTexture(nil, "ARTWORK")
    infoFrame.sep2:SetTexture(0.4, 0.4, 0.4, 0.9)
    infoFrame.sep2:SetHeight(1)

    -- Gesamt-Runenstoff + AH-Preis (3 Zeilen)
    infoFrame.fsTotal  = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoFrame.fsPreis  = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoFrame.fsGesamt = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

    infoFrame:Hide()
end

local function PopulateInfoFrame()
    if not infoFrame then CreateInfoFrame() end

    local factions = GetFactionData()
    local numRows  = math.min(#factions, MAX_ROWS)

    -- AH-Preis einmal holen (fuer alle Zeilen)
    local avgPreis, ahQuelle = GetRunenstoffAHPreis()

    -- Zeilen befuellen / leeren
    for row = 1, MAX_ROWS do
        if row <= numRows then
            local f = factions[row]
            local spenden, verbleibend = BerechneSpendenBedarf(f.standingId, f.barMax, f.barValue)
            local runenstoff = spenden * RUNENSTOFF_PRO_SPENDE
            local standing   = STANDING_NAMEN[f.standingId] or "?"

            if f.standingId >= 8 then
                rowCells[row][1]:SetText("|cFF00FF00" .. f.name .. "|r")
                rowCells[row][2]:SetText("|cFF00FF00" .. standing .. "|r")
                rowCells[row][3]:SetText("|cFF00FF00-|r")
                rowCells[row][4]:SetText("|cFF00FF00-|r")
                rowCells[row][5]:SetText("|cFF00FF00-|r")
                rowCells[row][6]:SetText("|cFF00FF00-|r")
            else
                local kostenText
                if avgPreis then
                    kostenText = FormatMoney(avgPreis * runenstoff)
                else
                    kostenText = "|cFF888888-|r"
                end
                rowCells[row][1]:SetText(f.name)
                rowCells[row][2]:SetText("|cFFCCCCCC" .. standing .. "|r")
                rowCells[row][3]:SetText("|cFFFFFF80" .. verbleibend .. "|r")
                rowCells[row][4]:SetText("|cFF80FF80" .. spenden .. "x|r")
                rowCells[row][5]:SetText("|cFFFFAA00" .. runenstoff .. "x|r")
                rowCells[row][6]:SetText(kostenText)
            end
        else
            for col = 1, 6 do rowCells[row][col]:SetText("") end
        end
    end

    -- Kein Ruf gefunden (Ruf-Panel noch nie geoeffnet?)
    if numRows == 0 then
        rowCells[1][1]:SetText("|cFFFF8080Keine Hauptstadtfraktionen gefunden.|r")
        rowCells[1][1]:SetJustifyH("LEFT")
        for col = 2, 5 do rowCells[1][col]:SetText("") end
    end

    -- Gesamtrunenstoff ueber alle nicht-Exalted-Fraktionen
    local totalRunenstoff = 0
    for _, f in ipairs(factions) do
        if f.standingId < 8 then
            local sp = BerechneSpendenBedarf(f.standingId, f.barMax, f.barValue)
            totalRunenstoff = totalRunenstoff + sp * RUNENSTOFF_PRO_SPENDE
        end
    end

    -- Trennlinie + Gesamt-Block positionieren
    local usedRows = math.max(numRows, 1)
    local sepY     = -42 - 20 - usedRows * 22 - 4
    infoFrame.sep2:SetPoint("TOPLEFT",  14, sepY)
    infoFrame.sep2:SetPoint("TOPRIGHT", -14, sepY)

    local blockY = sepY - 16
    infoFrame.fsTotal:SetPoint("TOPLEFT",  14, blockY)
    infoFrame.fsPreis:SetPoint("TOPLEFT",  14, blockY - 20)
    infoFrame.fsGesamt:SetPoint("TOPLEFT", 14, blockY - 40)

    if totalRunenstoff == 0 then
        infoFrame.fsTotal:SetText("|cFF00FF00Alle Fraktionen bereits Ehrfuerchtig!|r")
        infoFrame.fsPreis:SetText("")
        infoFrame.fsGesamt:SetText("")
    else
        infoFrame.fsTotal:SetText(
            "Runenstoff gesamt: |cFFFFAA00" .. totalRunenstoff .. "x|r")
        if avgPreis then
            infoFrame.fsPreis:SetText(
                "|cFF00CCFF[AH Trader – " .. ahQuelle .. "]|r  " ..
                "Preis/Stk: " .. FormatMoney(avgPreis))
            infoFrame.fsGesamt:SetText(
                "Gesamtkosten gesamt: " .. FormatMoney(avgPreis * totalRunenstoff))
        else
            infoFrame.fsPreis:SetText("|cFF888888(ProjEP AH Trader nicht vorhanden – keine Kostenberechnung)|r")
            infoFrame.fsGesamt:SetText("")
        end
    end

    -- Frame-Hoehe dynamisch anpassen
    local bottomY = math.abs(blockY) + 60
    infoFrame:SetHeight(math.max(bottomY, 160))
end

local function ToggleInfoFrame()
    if not infoFrame then CreateInfoFrame() end
    if infoFrame:IsShown() then
        infoFrame:Hide()
    else
        PopulateInfoFrame()
        infoFrame:Show()
    end
end

-- ── Minimap-Button ────────────────────────────────────────────

local mmButton  = nil
local mmAngle   = 3.9   -- Standard-Position: links unten (~225 Grad)
local MM_RADIUS = 82

local function UpdateMMButtonPos()
    local x = math.cos(mmAngle) * MM_RADIUS
    local y = math.sin(mmAngle) * MM_RADIUS
    mmButton:ClearAllPoints()
    mmButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    mmButton = CreateFrame("Button", "ProjEP_RUF_Farmer_MMButton", Minimap)
    mmButton:SetWidth(31)
    mmButton:SetHeight(31)
    mmButton:SetFrameStrata("MEDIUM")
    mmButton:SetFrameLevel(8)
    mmButton:RegisterForDrag("LeftButton")
    mmButton:RegisterForClicks("LeftButtonUp")

    -- Hintergrund-Kreis
    local bg = mmButton:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Background")
    bg:SetAllPoints()

    -- Icon: Runenstoff
    local icon = mmButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Fabric_Runecloth_01")
    icon:SetWidth(18)
    icon:SetHeight(18)
    icon:SetPoint("CENTER", 0, 1)

    -- Runder Rand
    local border = mmButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(56)
    border:SetHeight(56)
    border:SetPoint("TOPLEFT")

    -- Drag: verschiebt den Button entlang des Minimap-Rings
    mmButton:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local cx, cy = Minimap:GetCenter()
            local scale  = UIParent:GetEffectiveScale()
            local mx, my = GetCursorPosition()
            mx = mx / scale
            my = my / scale
            mmAngle = math.atan2(my - cy, mx - cx)
            UpdateMMButtonPos()
            if ProjEP_RUF_Farmer_DB then
                ProjEP_RUF_Farmer_DB.mmAngle = mmAngle
            end
        end)
    end)
    mmButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    -- Klick: Info-Fenster toggeln
    mmButton:SetScript("OnClick", function(self, btn)
        ToggleInfoFrame()
    end)

    -- Hover-Tooltip
    mmButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF00CCFFProjEP Ruf Farmer|r")
        GameTooltip:AddLine("Klick: Runenstoff-Uebersicht", 1, 1, 1)
        GameTooltip:AddLine("Drag: Position verschieben",   0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    mmButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateMMButtonPos()
end

-- ── Globale Event-Funktionen fuer ProjEP_RUF_Farmer.xml ──────

function ProjEP_RUF_Farmer_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function ProjEP_RUF_Farmer_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        -- SavedVariables: Minimap-Winkel wiederherstellen
        if ProjEP_RUF_Farmer_DB and ProjEP_RUF_Farmer_DB.mmAngle then
            mmAngle = ProjEP_RUF_Farmer_DB.mmAngle
        end
        -- SavedVariables initialisieren
        if not ProjEP_RUF_Farmer_DB then
            ProjEP_RUF_Farmer_DB = { mmAngle = mmAngle }
        end
        CreateMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFF00CCFF[ProjEP Ruf Farmer]|r v" .. ADDON_VERSION .. " geladen."
        )
    end
end
