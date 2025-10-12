--------------------------------------------------------------------------------
-- Emojify - Picker Button
-- Random emoji button for opening the emoji picker
--------------------------------------------------------------------------------

local addonName, ns = ...;

local EmojiRegistry = ns.EmojiRegistry;

EmojifyPickerButtonMixin = {};

function EmojifyPickerButtonMixin:OnLoad()
    C_Timer.After(1.2, function()
        self:UpdateRandomTexture();
    end);
end

function EmojifyPickerButtonMixin:UpdateRandomTexture()
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

function EmojifyPickerButtonMixin:OnClick()
    EmojifyPickerFrame:SetShown(not EmojifyPickerFrame:IsShown());
end

function EmojifyPickerButtonMixin:OnEnter()
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

function EmojifyPickerButtonMixin:OnLeave()
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
