--------------------------------------------------------------------------------
-- Emojify - Visual Picker Pack Header Mixin
-- Header button that shows/hides emoji packs in the visual picker
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local VisualPicker = ns.VisualPicker;

EmojifyVisualPickerPackHeaderMixin = {};

function EmojifyVisualPickerPackHeaderMixin:OnLoad()
    self:SetPushedTextOffset(1, -1);

    if (ns.IsClassic()) then
        self:GetNormalTexture():SetAlpha(0);
        self:GetHighlightTexture():SetAlpha(0);
        self.CollapseButton:SetAlpha(0);
    end
end

function EmojifyVisualPickerPackHeaderMixin:OnClick()
    if (self.isCollapsed) then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end

    VisualPicker.ToggleSection(self.packName);
end

function EmojifyVisualPickerPackHeaderMixin:OnEnter()
    self.CollapseButton:LockHighlight();
    self.ButtonText:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
end

function EmojifyVisualPickerPackHeaderMixin:OnLeave()
    self.CollapseButton:UnlockHighlight();
    self.ButtonText:SetTextColor(self.normalFontColor:GetRGB());
end

function EmojifyVisualPickerPackHeaderMixin:OnMouseDown()
    self.CollapseButton:UpdatePressedState(true);
end

function EmojifyVisualPickerPackHeaderMixin:OnMouseUp()
    self.CollapseButton:UpdatePressedState(false);
end

function EmojifyVisualPickerPackHeaderMixin:UpdateCollapsedState(isSearchHeader, isCollapsed)
    self.CollapseButton:SetShown(not isSearchHeader);
    self.CollapseButton:UpdateCollapsedState(isCollapsed);
end

EmojifyVisualPickerPackHeaderCollapseMixin = {};

function EmojifyVisualPickerPackHeaderCollapseMixin:UpdatePressedState(pressed)
    if (pressed) then
        self.Icon:AdjustPointsOffset(1, -1);
    else
        self.Icon:AdjustPointsOffset(-1, 1);
    end
end

function EmojifyVisualPickerPackHeaderCollapseMixin:UpdateCollapsedState(isCollapsed)
    local atlas = isCollapsed and "questlog-icon-expand" or "questlog-icon-shrink";
    self.Icon:SetAtlas(atlas);
    self:SetHighlightAtlas(atlas);
end
