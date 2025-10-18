--------------------------------------------------------------------------------
-- Emojify - Visual Picker Chat Button Mixin
-- Button attached to chat frames to open the visual picker
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local EmojiRegistry = ns.EmojiRegistry;

EmojifyVisualPickerChatButtonMixin = {};

function EmojifyVisualPickerChatButtonMixin:OnLoad()
    C_Timer.After(1.2, function()
        self:UpdateRandomTexture();
    end);
end

function EmojifyVisualPickerChatButtonMixin:UpdateRandomTexture()
    local emojiInfo = EmojiRegistry.GetRandomEmoji();
    self.emojiInfo = emojiInfo;

    local data = emojiInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local displayWidth = math.floor(self:GetHeight() * (frameWidth / frameHeight));

    self:SetWidth(displayWidth);
    self.Texture:SetTexture(data.texture);
    self.Texture:SetTexCoord(
        0,
        frameWidth / data.textureWidth,
        0,
        frameHeight / data.textureHeight
    );
end

function EmojifyVisualPickerChatButtonMixin:OnClick()
    EmojifyVisualPickerFrame:SetShown(not EmojifyVisualPickerFrame:IsShown());
end

function EmojifyVisualPickerChatButtonMixin:OnEnter()
    if (self.mouseEnter) then
        return;
    end

    self.Texture:SetDesaturation(0);
    self:UpdateRandomTexture();
    self.mouseEnter = true;
    self:Show();

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(EMOJIFY_PICKERBUTTON_TOOLTIP, 1, 1, 1);
    GameTooltip:AddLine(self.emojiInfo.code, nil, nil, nil);
    GameTooltip:Show();
end

function EmojifyVisualPickerChatButtonMixin:OnLeave()
    self.Texture:SetDesaturation(1);
    self.mouseEnter = false;

    for _, mouseFocus in ipairs(GetMouseFoci()) do
        local mouseName = mouseFocus.GetName and mouseFocus:GetName();
        if (not mouseName or mouseName ~= self:GetParent():GetName()) then
            self:Hide();
        end
    end

    GameTooltip:Hide();
end
