--------------------------------------------------------------------------------
-- Emojify - Chat Bubbles
--------------------------------------------------------------------------------

local addonName, ns = ...;

ns.ChatBubbles = {};
local ChatBubbles = ns.ChatBubbles;

local Animation = ns.Animation;
local DEFAULT_HEIGHT = ns.Constants.DEFAULT_HEIGHT;

function ChatBubbles.OnUpdate()
    local allChatBubbles = C_ChatBubbles.GetAllChatBubbles();

    if (#allChatBubbles == 0) then
        return;
    end

    for _, Bubble in pairs(allChatBubbles) do
        for i = 1, Bubble:GetNumChildren() do
            local Child = select(i, Bubble:GetChildren());

            if (Child and Child:GetObjectType() == "Frame" and Child.String and Child.Center and not Child:IsForbidden()) then
                for j = 1, Child:GetNumRegions() do
                    local Region = select(j, Child:GetRegions());

                    if (Region and not Region:GetName() and Region:IsVisible() and Region.GetText and not Region:IsForbidden()) then
                        local message = Region:GetText() or "";

                        if (string.find(message, "Interface\\AddOns\\Emojify_[^\\]+")) then
                            if (string.find(message, "animated_emojis")) then
                                local newMessage = Animation.UpdateAnimatedTextures(message);
                                if (newMessage ~= message) then
                                    Region:SetText(newMessage);
                                end
                            end
                        else
                            local newMessage = Animation.ProcessEmojiText(message);

                            if (newMessage ~= message) then
                                Region:SetText(newMessage);

                                -- Adjust width for emoji-only bubbles
                                if (string.match(newMessage, "^%s*|TInterface\\AddOns\\Emojify_.-\\.-|t%s*$")) then
                                    local displayWidth = string.match(newMessage, "|T.-:" .. DEFAULT_HEIGHT .. ":(%d+):");
                                    local width = (tonumber(displayWidth) or 0) + 40;
                                    Region:SetWidth(width);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
