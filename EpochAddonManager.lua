-- Epoch Addon Manager (Wrath 3.3.5) — safe, styled, and with position saving
-- Features:
-- - ESC menu button "AddOns" + /eam slash
-- - Lists all addons with checkboxes; toggles per character
-- - "Reload UI" only appears after changes
-- - Draggable window; remembers position per-character (EAMDB)
-- - Styled like Blizzard dialog (ESC menu); falls back if SetBackdrop is unavailable
-- - Minimal global leakage (only the slash commands and the saved vars)

local EAM = {}
local DEBUG = false
local function dprint(...) if DEBUG then print("|cffff7f00[EAM]|r", ...) end end

-- ===== Saved Vars =====
-- Per-character DB table:
-- EAMDB = { pos = {point="CENTER", x=0, y=0} }

-- ===== Utilities =====

-- Apply Blizzard dialog-style backdrop (ESC menu look).
-- Some patched clients remove SetBackdrop; so we have a fallback.
function EAM.ApplyDialogBackdrop(f)
  local ok = (type(f.SetBackdrop) == "function")
  if ok then
    f:SetBackdrop({
      bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile     = true, tileSize = 32, edgeSize = 32,
      insets   = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetBackdropColor(0, 0, 0, 1)
    f:SetBackdropBorderColor(1, 1, 1, 1)
    return
  end

  -- Fallback: fake the same look with textures
  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
  bg:SetAllPoints(f)
  f._EAM_bg = bg

  local border = f:CreateTexture(nil, "BORDER")
  border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
  border:SetAllPoints(f)
  f._EAM_border = border
end

-- Safe getter for addon enabled state in Wrath:
local function IsAddonEnabled(i, enabledFlag, name)
  -- Wrath GetAddOnInfo returns: name, title, notes, enabled(bool), loadable, reason
  if enabledFlag ~= nil then return enabledFlag and true or false end
  -- Fallback if needed:
  if IsAddOnLoaded then
    return IsAddOnLoaded(name) and true or false
  end
  return false
end

-- ===== UI Construction =====

function EAM.CreateManagerFrame()
  if EpochAddonManagerFrame then return EpochAddonManagerFrame end

  local f = CreateFrame("Frame", "EpochAddonManagerFrame", UIParent)
  f:SetSize(460, 520)
  f:SetFrameStrata("DIALOG")
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    EAMDB = EAMDB or {}
    EAMDB.pos = { point = point, x = x, y = y }
  end)
  f:Hide()

  -- Position from saved vars (or center)
  EAMDB = EAMDB or {}
  local pos = EAMDB.pos
  f:ClearAllPoints()
  if pos and pos.point then
    f:SetPoint(pos.point, UIParent, pos.point, pos.x or 0, pos.y or 0)
  else
    f:SetPoint("CENTER")
  end

  -- Style like ESC menu
  EAM.ApplyDialogBackdrop(f)

  -- Title
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("Addon Manager")

  -- Close button
  local close = CreateFrame("Button", nil, f, "OptionsButtonTemplate")
  close:SetSize(80, 22)
  close:SetPoint("TOPRIGHT", -10, -10)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  -- Scroll area
  local scroll = CreateFrame("ScrollFrame", "EpochAM_Scroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -44)
  scroll:SetPoint("BOTTOMRIGHT", -30, 56)

  local content = CreateFrame("Frame", "EpochAM_Content", scroll)
  content:SetWidth(400)   -- width for rows
  content:SetHeight(10)   -- will be expanded below
  scroll:SetScrollChild(content)

  -- Reload UI button (hidden until changes)
  local reloadBtn = CreateFrame("Button", "EpochAM_Reload", f, "OptionsButtonTemplate")
  reloadBtn:SetSize(160, 28)
  reloadBtn:SetPoint("BOTTOM", 0, 12)
  reloadBtn:SetText("Reload UI")
  reloadBtn:Hide()
  reloadBtn:SetScript("OnClick", ReloadUI)

  local function MarkChanged()
    if not reloadBtn:IsShown() then reloadBtn:Show() end
  end

  -- Build list of addons
  local y = -2
  local rowH = 24
  local num = GetNumAddOns() or 0

  for i = 1, num do
    local name, titleText, notes, enabled, loadable, reason = GetAddOnInfo(i)

    local row = CreateFrame("Frame", "EpochAM_Row"..i, content)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetSize(380, rowH)

    local cb = CreateFrame("CheckButton", "EpochAM_Check"..i, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 4, 0)
    cb:SetChecked(IsAddonEnabled(i, enabled, name))

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    label:SetText((titleText and titleText ~= "") and titleText or name)

    if not loadable and reason then
      local hint = row:CreateFontString(nil, "OVERLAY", "GameFontDisable")
      hint:SetPoint("LEFT", label, "RIGHT", 6, 0)
      hint:SetText("("..reason..")")
    end

    cb:SetScript("OnClick", function(self)
      if self:GetChecked() then
        EnableAddOn(name)     -- per character
      else
        DisableAddOn(name)    -- per character
      end
      MarkChanged()
    end)

    y = y - rowH
  end

  content:SetHeight(-y + 6)

  return f
end

-- ===== ESC Menu Integration =====

function EAM.EnsureEscButton()
  if EpochAM_AddedEscButton then return end

  local anchor = GameMenuButtonOptions or GameMenuButtonContinue or GameMenuButtonUIOptions
  local btn = CreateFrame("Button", "EpochAddonManagerButton", GameMenuFrame, "GameMenuButtonTemplate")
  btn:SetText("AddOns")
  btn:SetWidth(anchor and anchor:GetWidth() or 154)

  if anchor then
    btn:SetPoint("TOP", anchor, "BOTTOM", 0, -90)
  else
    btn:SetPoint("TOP", GameMenuFrame, "TOP", 0, -150)
  end

  btn:SetScript("OnClick", function()
    HideUIPanel(GameMenuFrame)
    local frame = EAM.CreateManagerFrame()
    if frame:IsShown() then frame:Hide() else frame:Show() end
  end)

  -- shift Logout down slightly (avoid overlap)
  if GameMenuButtonLogout then
    GameMenuButtonLogout:ClearAllPoints()
    GameMenuButtonLogout:SetPoint("TOP", btn, "BOTTOM", 0, -16)
  end

  EpochAM_AddedEscButton = true
end

local function HookGameMenu()
  if EAM._menuHooked then return end
  EAM._menuHooked = true
  if GameMenuFrame_UpdateVisibleButtons then
    hooksecurefunc("GameMenuFrame_UpdateVisibleButtons", EAM.EnsureEscButton)
  else
    GameMenuFrame:HookScript("OnShow", EAM.EnsureEscButton)
  end
end

-- ===== Init =====

local fInit = CreateFrame("Frame")
fInit:RegisterEvent("PLAYER_LOGIN")
fInit:SetScript("OnEvent", function()
  -- Saved vars table
  EAMDB = EAMDB or {}
  HookGameMenu()

  -- Slash: /eam opens/closes manager
  SLASH_EPOCHAM1 = "/eam"
  SlashCmdList["EPOCHAM"] = function()
    local frame = EAM.CreateManagerFrame()
    if frame:IsShown() then frame:Hide() else frame:Show() end
  end

  print("|cff00ff00 Epoch Addon Manager By SuppliedGM loaded.|r Type |cffffff00/eam|r or press ESC → AddOns.")
end)
