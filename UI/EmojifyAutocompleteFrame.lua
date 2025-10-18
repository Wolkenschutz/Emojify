--------------------------------------------------------------------------------
-- Emojify - Autocomplete Frame Mixin
-- Dropdown frame that displays matching emojis during typing
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local Animation = ns.Animation;
local EmojiSearch = ns.EmojiSearch;
local VisualPicker = ns.VisualPicker;

local MAX_VISIBLE_AUTOCOMPLETE = ns.Constants.MAX_VISIBLE_AUTOCOMPLETE;
local TRIGGER_CHAR = ns.Constants.TRIGGER_CHAR;

EmojifyAutocompleteFrameMixin = {};

function EmojifyAutocompleteFrameMixin:OnLoad()
    table.insert(UISpecialFrames, self:GetName());

    self:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    });
    self:SetBackdropColor(0, 0, 0, 0.8);
    self:EnableKeyboard(true);

    self.dataProvider = CreateDataProvider();

    local view = CreateScrollBoxListLinearView();
    view:SetElementInitializer("EmojifyAutocompleteButtonTemplate", function(Button, emojiInfo)
        Button:SetEmojiInfo(emojiInfo);
    end);
    view:SetPadding(0, 32, 0, 0, 0);

    view:SetDataProvider(self.dataProvider);
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

    self.matches = {};
    self.currentSearch = "";
    self.selection = 1;
end

function EmojifyAutocompleteFrameMixin:OnShow()
    if (ACTIVE_CHAT_EDIT_BOX) then
        self.ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX;
        self.ignoreArrows = ACTIVE_CHAT_EDIT_BOX:GetAltArrowKeyMode();

        ACTIVE_CHAT_EDIT_BOX:SetAltArrowKeyMode(false);

        -- ElvUI
        self.historyLines = ACTIVE_CHAT_EDIT_BOX.historyLines;
        ACTIVE_CHAT_EDIT_BOX.historyLines = nil;
        -- Prat
        self.history_lines = ACTIVE_CHAT_EDIT_BOX.history_lines;
        ACTIVE_CHAT_EDIT_BOX.history_lines = {};
    end
end

function EmojifyAutocompleteFrameMixin:OnHide()
    if (self.ACTIVE_CHAT_EDIT_BOX) then
        self.ACTIVE_CHAT_EDIT_BOX:SetAltArrowKeyMode(self.ignoreArrows);

        -- ElvUI
        self.ACTIVE_CHAT_EDIT_BOX.historyLines = self.historyLines;
        self.historyLines = nil;
        -- Prat
        self.ACTIVE_CHAT_EDIT_BOX.history_lines = self.history_lines;
        self.history_lines = nil;

        self.ACTIVE_CHAT_EDIT_BOX = nil;
        self.ignoreArrows = nil;
    end

    Animation.SetVisibleAnimationsFromAutocomplete({});
end

function EmojifyAutocompleteFrameMixin:SetMatches(matches, searchText)
    self.matches = matches;
    self.currentSearch = searchText;
    self.selection = 1;

    self.dataProvider:Flush();

    for i, emojiInfo in ipairs(matches) do
        emojiInfo.dataIndex = i;
        self.dataProvider:Insert(emojiInfo);
    end

    local visibleCount = math.min(math.max(2, #matches), MAX_VISIBLE_AUTOCOMPLETE);
    local frameHeight = 16 + (visibleCount * 28);
    self:SetHeight(frameHeight);
    self:Show();

    C_Timer.After(0, function()
        self:UpdateSelection();
        self:UpdateAnimations();
    end);
end

function EmojifyAutocompleteFrameMixin:UpdateSelection()
    self.ScrollBox:ForEachFrame(function(Button)
        Button:SetSelected(Button.dataIndex == self.selection);
    end);
end

function EmojifyAutocompleteFrameMixin:UpdateAnimations()
    if (not self:IsShown()) then
        return;
    end

    local found = {};

    self.ScrollBox:ForEachFrame(function(Button)
        if (Button.emojiInfo and Button.emojiInfo.isAnimated) then
            found[Button.emojiInfo.code] = true;
            Button:UpdateAnimation();
        end
    end);

    Animation.SetVisibleAnimationsFromAutocomplete(found);
end

function EmojifyAutocompleteFrameMixin:SelectNext()
    self.selection = self.selection + 1;

    if (self.selection > #self.matches) then
        self.selection = 1;
    end

    self:ScrollToSelection();
    self:UpdateSelection();
end

function EmojifyAutocompleteFrameMixin:SelectPrevious()
    self.selection = self.selection - 1;

    if (self.selection < 1) then
        self.selection = #self.matches;
    end

    self:ScrollToSelection();
    self:UpdateSelection();
end

function EmojifyAutocompleteFrameMixin:ScrollToSelection()
    local numMatches = #self.matches;
    if (numMatches == 0) then
        return;
    end

    self.ScrollBox:ScrollToElementDataIndex(self.selection, numMatches == 2 and ScrollBoxConstants.AlignBegin or ScrollBoxConstants.AlignCenter);
end

function EmojifyAutocompleteFrameMixin:InsertSelectedEmoji(emojiInfo)
    if (not ACTIVE_CHAT_EDIT_BOX or not emojiInfo) then
        return;
    end

    local text = ACTIVE_CHAT_EDIT_BOX:GetText();
    local cursorPos = ACTIVE_CHAT_EDIT_BOX:GetCursorPosition();

    local wordStart = cursorPos;
    for i = cursorPos, 1, -1 do
        local char = string.sub(text, i, i);
        if (char == TRIGGER_CHAR) then
            wordStart = i;
            break;
        end
    end

    local before = string.sub(text, 1, wordStart - 1);
    local after = string.sub(text, cursorPos + 1);
    local newText = before .. emojiInfo.code .. " " .. after;

    ACTIVE_CHAT_EDIT_BOX:SetText(newText);
    ACTIVE_CHAT_EDIT_BOX:SetCursorPosition(#before + #emojiInfo.code + 1);
    ACTIVE_CHAT_EDIT_BOX:SetFocus();

    EmojiSearch.IncrementUsage(emojiInfo.code);
    self:Hide();
end

function EmojifyAutocompleteFrameMixin:ConfirmSelection()
    if (not ACTIVE_CHAT_EDIT_BOX or #self.matches == 0 or self.selection < 1) then
        return;
    end

    local selectedEmoji = self.matches[self.selection];
    self:InsertSelectedEmoji(selectedEmoji);
end

function EmojifyAutocompleteFrameMixin:OnButtonClick(button)
    if (not button or not button.emojiInfo) then
        return;
    end

    self:InsertSelectedEmoji(button.emojiInfo);
end

function EmojifyAutocompleteFrameMixin:SendSelectedEmoji()
    if (#self.matches == 0 or self.selection < 1) then
        return;
    end

    local selectedEmoji = self.matches[self.selection];
    VisualPicker.SendEmoji(selectedEmoji.code);

    self:Hide();
end
