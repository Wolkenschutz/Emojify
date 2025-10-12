--------------------------------------------------------------------------------
-- Emojify - Autocomplete Mixins
--------------------------------------------------------------------------------

local addonName, ns = ...;

local Animation = ns.Animation;
local Trie = ns.Trie;

local MAX_VISIBLE_AUTOCOMPLETE = ns.Constants.MAX_VISIBLE_AUTOCOMPLETE;
local TRIGGER_CHAR = ns.Constants.TRIGGER_CHAR;

EmojifyAutocompleteButtonMixin = {};

function EmojifyAutocompleteButtonMixin:SetEmojiInfo(emojiInfo)
    self.emojiInfo = emojiInfo;
    self.dataIndex = emojiInfo.dataIndex;

    local data = emojiInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local displayWidth = math.floor(self.Texture:GetHeight() * (frameWidth / frameHeight));

    self.Text:SetText(emojiInfo.code);
    self.Texture:SetTexture(data.texture);
    self.Texture:SetWidth(displayWidth);

    if (emojiInfo.isAnimated) then
        self:UpdateAnimation();
    else
        self.Texture:SetTexCoord(
            0,
            frameWidth / data.textureWidth,
            0,
            frameHeight / data.textureHeight
        );
    end
end

function EmojifyAutocompleteButtonMixin:UpdateAnimation()
    if (not self.emojiInfo or not self.emojiInfo.isAnimated) then
        return;
    end

    local data = self.emojiInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local frame = Animation.GetCurrentFrame(self.emojiInfo.code);
    local left = frame * frameWidth;
    local right = left + frameWidth;

    self.Texture:SetTexCoord(
        left / data.textureWidth,
        right / data.textureWidth,
        0,
        frameHeight / data.textureHeight
    );
end

function EmojifyAutocompleteButtonMixin:SetSelected(selected)
    self.selected = selected;

    if (self:IsMouseOver()) then
        self.Highlight:Show();
        self.Highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3);
    elseif (selected) then
        self.Highlight:Show();
        self.Highlight:SetColorTexture(0.4, 0.4, 0.8, 0.5);
    elseif (not self:IsMouseOver()) then
        self.Highlight:Hide();
    end
end

function EmojifyAutocompleteButtonMixin:OnClick()
    local Frame = self:GetParent():GetParent():GetParent();
    Frame:OnButtonClick(self);
end

function EmojifyAutocompleteButtonMixin:OnEnter()
    if (not self.selected) then
        self.Highlight:Show();
        self.Highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3);
    end
end

function EmojifyAutocompleteButtonMixin:OnLeave()
    if (not self.selected) then
        self.Highlight:Hide();
    end
end

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
    self.selection = 1;
    self.currentSearch = "";
end

function EmojifyAutocompleteFrameMixin:OnShow()
    if (ACTIVE_CHAT_EDIT_BOX) then
        self.ignoreArrows = ACTIVE_CHAT_EDIT_BOX:GetAltArrowKeyMode();
        self.ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX;
        ACTIVE_CHAT_EDIT_BOX:SetAltArrowKeyMode(false);
    end

    self:UpdateAutocompleteAnimations();
end

function EmojifyAutocompleteFrameMixin:OnHide()
    if (self.ACTIVE_CHAT_EDIT_BOX) then
        self.ACTIVE_CHAT_EDIT_BOX:SetAltArrowKeyMode(self.ignoreArrows);
        self.ACTIVE_CHAT_EDIT_BOX = nil;
        self.ignoreArrows = nil;
    end

    Animation.SetVisibleAnimationsFromAutocomplete({});
end

function EmojifyAutocompleteFrameMixin:Show(matches, searchText)
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

    self:UpdateSelection();
    self:SetShown(true);
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

    self.ScrollBox:ForEachFrame(function(Button)
        Button:UpdateAnimation();
    end);

    self:UpdateSelection();
    self:UpdateAutocompleteAnimations();
end

function EmojifyAutocompleteFrameMixin:UpdateAutocompleteAnimations()
    if (not self:IsShown()) then
        return;
    end

    local found = {};

    self.ScrollBox:ForEachFrame(function(Button)
        if (Button:IsShown() and Button.emojiInfo and Button.emojiInfo.isAnimated) then
            found[Button.emojiInfo.code] = true;
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
    if (#self.matches == 0) then
        return;
    end

    self.ScrollBox:ScrollToElementDataIndex(self.selection, ScrollBoxConstants.AlignCenter);
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

    Trie.IncrementUsage(emojiInfo.code);
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
    ns.Picker.SendEmoji(selectedEmoji.code);

    self:Hide();
end
