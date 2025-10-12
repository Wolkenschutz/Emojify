--------------------------------------------------------------------------------
-- Emojify - Chat Frame Hooks
--------------------------------------------------------------------------------

local addonName, ns = ...;

ns.ChatFrameHooks = {};
local ChatFrameHooks = ns.ChatFrameHooks;

local Animation = ns.Animation;
local Autocomplete = ns.Autocomplete;

local function IterateVisibleChatFontStrings(Frame)
    if (not Frame or not Frame:IsShown()) then
        return function() end; -- empty iterator
    end

    local sources = {};

    if (Frame.visibleLines) then
        table.insert(sources, Frame.visibleLines);
    end

    local container = Frame.FontStringContainer or Frame.fontStringContainer;
    if (container and container.GetRegions) then
        table.insert(sources, { container:GetRegions() });
    end

    table.insert(sources, { Frame:GetRegions() });

    -- Iterator state
    local sourceIndex = 1
    local itemIndex = 0

    return function()
        while (sourceIndex <= #sources) do
            itemIndex = itemIndex + 1;
            local source = sources[sourceIndex];
            local Item = source[itemIndex];

            if (Item) then
                -- Check if valid fontstring
                if (Item.GetText and Item:IsShown()) then
                    return Item;
                end
            else
                -- Move to next source
                sourceIndex = sourceIndex + 1;
                itemIndex = 0;
            end
        end

        return nil;
    end
end

local function UpdateVisibleEmojis()
    local foundAnimations = {}

    for _, frameName in pairs(CHAT_FRAMES) do
        local ChatFrame = _G[frameName];

        for FontString in IterateVisibleChatFontStrings(ChatFrame) do
            local message = FontString:GetText() or "";

            if (message ~= "" and string.find(message, "Interface\\AddOns\\Emojify_[^\\]+\\animated_emojis")) then
                local newMessage = Animation.UpdateAnimatedTextures(message);

                if (newMessage ~= message) then
                    if (FontString.messageInfo) then
                        FontString.messageInfo.message = newMessage;
                    end

                    FontString:SetText(newMessage);
                end

                for code in string.gmatch(message, "Interface\\AddOns\\Emojify_[^\\]+\\animated_emojis\\([^:]+)") do
                    foundAnimations[code] = true;
                end
            end
        end
    end

    Animation.SetVisibleAnimationsFromChat(foundAnimations);
end

local function HookChatFrame(frameName)
    local ChatFrame = _G[frameName];

    if (ChatFrame and not ChatFrame.emojifyHooked) then
        ChatFrame.emojifyHooked = true;

        local ScrollBar = ChatFrame.ScrollBar;
        if (ScrollBar) then
            ScrollBar:RegisterCallback(ScrollBarMixin.Event.OnScroll, UpdateVisibleEmojis);
        end

        local Tab = _G[frameName .. "Tab"];
        if (Tab) then
            Tab:HookScript("OnClick", UpdateVisibleEmojis);
        end

        local EditBox = _G[frameName .. "EditBox"];
        if (EditBox) then
            EditBox:HookScript("OnTextChanged", function(self)
                Autocomplete.OnEditBoxTextChanged(self);
            end);

            EditBox:HookScript("OnEditFocusLost", function()
                Autocomplete.OnEditBoxFocusLost();
            end);

            EditBox:HookScript("OnEscapePressed", function()
                Autocomplete.OnEditBoxEscapePressed();
            end);

            EditBox:HookScript("OnTabPressed", function()
                Autocomplete.OnEditBoxTabPressed();
            end);

            EditBox:HookScript("OnArrowPressed", function(self, key)
                Autocomplete.OnEditBoxArrowPressed(key);
            end);

            EditBox:HookScript("OnKeyDown", function(self, key)
                Autocomplete.OnEditBoxKeyDown(key);
            end);
        end

        if (not ChatFrame.EmojifyPicker) then
            local EmojifyPicker = CreateFrame("Button", nil, ChatFrame, "EmojifyPickerButtonTemplate");
            EmojifyPicker:SetPoint("BOTTOMRIGHT", -10, 10);

            ChatFrame:HookScript("OnEnter", function()
                EmojifyPicker:Show();
            end);
            ChatFrame:HookScript("OnLeave", function()
                EmojifyPicker:Hide();
                GameTooltip:Hide();
            end);

            ChatFrame.EmojifyPicker = EmojifyPicker;
        end
    end
end

local OriginalOpenNewWindow = FCF_OpenNewWindow;
FCF_OpenNewWindow = function(...)
    local frameName = OriginalOpenNewWindow(...);
    HookChatFrame(frameName:GetName());
    return frameName;
end

local OriginalOpenTemporaryWindow = FCF_OpenTemporaryWindow;
FCF_OpenTemporaryWindow = function(chatType, ...)
    local frameName = OriginalOpenTemporaryWindow(chatType, ...);
    HookChatFrame(frameName:GetName());
    return frameName;
end

function ChatFrameHooks.Initialize()
    for _, frameName in pairs(CHAT_FRAMES) do
        HookChatFrame(frameName);
    end
end

function ChatFrameHooks.OnUpdate()
    UpdateVisibleEmojis();
end
