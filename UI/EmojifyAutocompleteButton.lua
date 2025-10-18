--------------------------------------------------------------------------------
-- Emojify - Autocomplete Button Mixin
-- Individual button in the autocomplete dropdown list
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local Animation = ns.Animation;

EmojifyAutocompleteButtonMixin = {};

function EmojifyAutocompleteButtonMixin:SetEmojiInfo(emojiInfo)
    self.emojiInfo = emojiInfo;
    self.dataIndex = emojiInfo.dataIndex;

    local selection = self:GetParent():GetParent():GetParent().selection;
    self:SetSelected(self.dataIndex == selection);

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