--------------------------------------------------------------------------------
-- Emojify - Main Entry Point
-- Initializes the addon, registers events and manages the update loop
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local Animation = ns.Animation;
local EmojiSearch = ns.EmojiSearch;
local Autocomplete = ns.Autocomplete;
local ChatFilter = ns.ChatFilter;
local ChatBubbles = ns.ChatBubbles;
local ChatFrameHooks = ns.ChatFrameHooks;
local EmojiRegistry = ns.EmojiRegistry;
local VisualPicker = ns.VisualPicker;
local Constants = ns.Constants;

local FIXED_FRAME_RATE = Constants.FIXED_FRAME_RATE;
local AUTO_CLOSE_TIME = Constants.AUTO_CLOSE_TIME;

local animationTimer = 0;
local autoCloseTimer = 0;

local function OnUpdate(self, elapsed)
    animationTimer = animationTimer + elapsed;

    if (animationTimer >= FIXED_FRAME_RATE) then
        if (Animation.HasVisibleAnimations()) then
            Animation.OnUpdate(animationTimer);
            Autocomplete.OnUpdate();
            ChatFrameHooks.OnUpdate();
            VisualPicker.OnUpdate();
        end

        ChatBubbles.OnUpdate();

        if (not ACTIVE_CHAT_EDIT_BOX) then
            EmojifyAutocompleteFrame:Hide();
        end

        animationTimer = 0;
    end

    autoCloseTimer = autoCloseTimer + elapsed;
    if (autoCloseTimer >= AUTO_CLOSE_TIME) then
        if (ACTIVE_CHAT_EDIT_BOX and not ACTIVE_CHAT_EDIT_BOX:HasFocus() and not EmojifyAutocompleteFrame:IsMouseOver()) then
            EmojifyAutocompleteFrame:Hide();
        end

        autoCloseTimer = 0;
    end
end

local function OnEvent(self, event, addon)
    if (addon ~= ADDON_NAME) then
        return;
    end

    self:UnregisterEvent(event);

    if (EmojifyDB == nil) then
        EmojifyDB = {
            usageCount = {},
            lastUsed = {},
            collapsedPacks = {},
        };
    end

    ChatFrameHooks.Initialize();
    ChatFilter.Initialize();

    -- Rebuild data after a short delay to ensure all packs are loaded
    C_Timer.After(1, function()
        EmojiRegistry.RebuildEmojiCodes();
        EmojiSearch.RebuildSearchIndex();
    end);

    self:SetScript("OnUpdate", OnUpdate);
end

local Handler = CreateFrame("Frame");
Handler:RegisterEvent("ADDON_LOADED");
Handler:SetScript("OnEvent", OnEvent);
