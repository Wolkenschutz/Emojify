--------------------------------------------------------------------------------
-- Emojify - Main
-- Initialization and update loop
--------------------------------------------------------------------------------

local addonName, ns = ...;

local Animation = ns.Animation;
local Trie = ns.Trie;
local Autocomplete = ns.Autocomplete;
local ChatFilter = ns.ChatFilter;
local ChatBubbles = ns.ChatBubbles;
local ChatFrameHooks = ns.ChatFrameHooks;
local EmojiRegistry = ns.EmojiRegistry;
local Picker = ns.Picker;

local FIXED_FRAME_RATE = ns.Constants.FIXED_FRAME_RATE;
local AUTO_CLOSE_TIME = ns.Constants.AUTO_CLOSE_TIME;

local animationTimer = 0;
local autoCloseTimer = 0;

--------------------------------------------------------------------------------
-- Event Handler
--------------------------------------------------------------------------------

local function OnEvent(self, event, addon)
    if (addon ~= addonName) then
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
        Trie.RebuildAutocomplete();
    end);
end


local function OnUpdate(self, elapsed)
    animationTimer = animationTimer + elapsed;

    if (animationTimer >= FIXED_FRAME_RATE) then
        local deltaTime = animationTimer;
        animationTimer = 0;

        if (Animation.HasVisibleAnimations() or EmojifyAutocompleteFrame:IsShown() or EmojifyPickerFrame:IsShown()) then
            Animation.OnUpdate(deltaTime);
            Autocomplete.OnUpdate();
            ChatFrameHooks.OnUpdate();
            Picker.OnUpdate();
        end

        ChatBubbles.OnUpdate();

        if (not ACTIVE_CHAT_EDIT_BOX) then
            EmojifyAutocompleteFrame:Hide();
        end
    end

    autoCloseTimer = autoCloseTimer + elapsed;
    if (autoCloseTimer >= AUTO_CLOSE_TIME) then
        autoCloseTimer = 0;

        if (ACTIVE_CHAT_EDIT_BOX and not ACTIVE_CHAT_EDIT_BOX:HasFocus() and not EmojifyAutocompleteFrame:IsMouseOver()) then
            EmojifyAutocompleteFrame:Hide();
        end
    end
end

local Handler = CreateFrame("Frame");
Handler:RegisterEvent("ADDON_LOADED");
Handler:SetScript("OnEvent", OnEvent);
Handler:SetScript("OnUpdate", OnUpdate);
