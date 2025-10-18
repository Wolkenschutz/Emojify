--------------------------------------------------------------------------------
-- Emojify - Visual Picker Grid Button Mixin
-- Individual emoji button in the visual picker
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local VisualPicker = ns.VisualPicker;
local Animation = ns.Animation;

EmojifyVisualPickerGridMixin = {};

function EmojifyVisualPickerGridMixin:SetEmoteInfo(emoteInfo)
    self.emoteInfo = emoteInfo;

    local data = emoteInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local buttonSize = self:GetHeight();
    local displayHeight = buttonSize - 4;
    local displayWidth = math.floor(displayHeight * (frameWidth / frameHeight));

    self.Texture:SetTexture(data.texture);
    self.Texture:SetSize(displayWidth, displayHeight);

    if (emoteInfo.isAnimated) then
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

function EmojifyVisualPickerGridMixin:UpdateAnimation()
    local data = self.emoteInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local frame = Animation.GetCurrentFrame(self.emoteInfo.code);
    local left = frame * frameWidth;
    local right = left + frameWidth;

    self.Texture:SetTexCoord(
        left / data.textureWidth,
        right / data.textureWidth,
        0,
        frameHeight / data.textureHeight
    );
end

function EmojifyVisualPickerGridMixin:OnClick()
    VisualPicker.SendEmoji(self.emoteInfo.code);
end

function EmojifyVisualPickerGridMixin:OnEnter()
    self.Highlight:Show();
    EmojifyVisualPickerFrame:SetPreview(self.emoteInfo);
end

function EmojifyVisualPickerGridMixin:OnLeave()
    self.Highlight:Hide();
end
