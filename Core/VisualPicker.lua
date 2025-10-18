--------------------------------------------------------------------------------
-- Emojify - Visual Picker Controller
-- Manages visual picker data, sections and usage tracking
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

ns.VisualPicker = {};
local VisualPicker = ns.VisualPicker;

local FREQUENT_COUNT = 18;
local USAGE_DECAY_DAYS = ns.Constants.USAGE_DECAY_DAYS;

local function IsPackCollapsed(packName)
    return EmojifyDB.collapsedPacks[packName] or false;
end

local function TogglePackCollapsed(packName)
    EmojifyDB.collapsedPacks[packName] = not EmojifyDB.collapsedPacks[packName];
end

local function GetWeightedUsage(code)
    local count = EmojifyDB.usageCount[code] or 0;
    local lastUsed = EmojifyDB.lastUsed[code] or 0;

    if (count == 0) then
        return 0
    end

    local currentTime = time()
    local daysSince = (currentTime - lastUsed) / 86400
    local decayFactor = math.exp(-daysSince / USAGE_DECAY_DAYS)

    return count * decayFactor
end

local function BuildFrequentlyUsed()
    local allEmojis = {};

    for code, data in pairs(ns.Emojis) do
        table.insert(allEmojis, {
            code = code,
            data = data,
            isAnimated = false,
            packName = string.match(data.texture, "Interface\\AddOns\\Emojify_([^\\]+)"),
            usageCount = VisualPicker.GetUsageCount(code)
        });
    end

    for code, data in pairs(ns.AnimatedEmojis) do
        table.insert(allEmojis, {
            code = code,
            data = data,
            isAnimated = true,
            packName = string.match(data.texture, "Interface\\AddOns\\Emojify_([^\\]+)"),
            usageCount = VisualPicker.GetUsageCount(code)
        });
    end

    table.sort(allEmojis, function(a, b)
        if (a.usageCount == b.usageCount) then
            return a.code < b.code;
        end

        return a.usageCount > b.usageCount;
    end);

    local frequent = {};
    for i = 1, math.min(FREQUENT_COUNT, #allEmojis) do
        if (allEmojis[i].usageCount > 0) then
            table.insert(frequent, allEmojis[i]);
        end
    end

    return frequent;
end

local function BuildPackEmotes(packName)
    local packEmojis = {};
    local packPath = "Interface\\AddOns\\Emojify_" .. packName;

    for code, data in pairs(ns.Emojis) do
        if (string.find(data.texture, packPath, 1, true)) then
            table.insert(packEmojis, {
                code = code,
                data = data,
                isAnimated = false,
                packName = packName
            });
        end
    end

    for code, data in pairs(ns.AnimatedEmojis) do
        if (string.find(data.texture, packPath, 1, true)) then
            table.insert(packEmojis, {
                code = code,
                data = data,
                isAnimated = true,
                packName = packName
            });
        end
    end

    table.sort(packEmojis, function(a, b)
        return a.code < b.code;
    end);

    return packEmojis;
end

local function BuildAllSections()
    local sections = {};

    for packName in pairs(ns.Packs) do
        local packEmotes = BuildPackEmotes(packName);
        if (#packEmotes > 0) then
            table.insert(sections, {
                packName = packName,
                emotes = packEmotes,
                isCollapsed = IsPackCollapsed(packName)
            });
        end
    end

    table.sort(sections, function(a, b)
        return a.packName < b.packName;
    end);

    local frequent = BuildFrequentlyUsed();
    if (#frequent > 0) then
        table.insert(sections, 1, {
            packName = EMOJIFY_FREQUENTLY_USED,
            emotes = frequent,
            isCollapsed = IsPackCollapsed(EMOJIFY_FREQUENTLY_USED)
        });
    end

    return sections;
end

local function FilterEmotesBySearch(searchText)
    if (not searchText or searchText == "") then
        return BuildAllSections();
    end

    local lowerSearch = string.lower(searchText);
    local results = {};

    for code, data in pairs(ns.Emojis) do
        if (string.find(string.lower(code), lowerSearch, 1, true)) then
            table.insert(results, {
                code = code,
                data = data,
                isAnimated = false,
                packName = string.match(data.texture, "Interface\\AddOns\\Emojify_([^\\]+)")
            });
        end
    end

    for code, data in pairs(ns.AnimatedEmojis) do
        if (string.find(string.lower(code), lowerSearch, 1, true)) then
            table.insert(results, {
                code = code,
                data = data,
                isAnimated = true,
                packName = string.match(data.texture, "Interface\\AddOns\\Emojify_([^\\]+)")
            });
        end
    end

    return { {
        packName = EMOJIFY_SEARCH_RESULTS,
        emotes = results,
        isCollapsed = false
    } };
end

function VisualPicker.SendEmoji(code)
    local EditBox = ChatEdit_GetActiveWindow() or ChatEdit_GetLastActiveWindow();
    if (EditBox) then
        local oldText = EditBox:GetText();
        EditBox:SetText(code);
        ChatEdit_SendText(EditBox, 1);
        EditBox:SetText(oldText or "");
        VisualPicker.IncrementUsage(code);
    end
end

function VisualPicker.GetAllSections()
    return BuildAllSections();
end

function VisualPicker.FilterBySearch(searchText)
    return FilterEmotesBySearch(searchText);
end

function VisualPicker.ToggleSection(packName)
    TogglePackCollapsed(packName);
    EmojifyVisualPickerFrame:RebuildPicker();
end

function VisualPicker.ExtractPackColorCode(packName)
    local pack = ns.Packs[packName];
    if (not pack) then
        return "cccccc";
    end

    local title = C_AddOns.GetAddOnMetadata("Emojify_" .. packName, "Title") or "";
    local colorCode = string.match(title, "|cff(%x%x%x%x%x%x)");
    return colorCode or "cccccc";
end

function VisualPicker.IncrementUsage(code)
    local currentWeighted = GetWeightedUsage(code);
    EmojifyDB.usageCount[code] = currentWeighted + 1;
    EmojifyDB.lastUsed[code] = time();
end

function VisualPicker.GetUsageCount(code)
    return GetWeightedUsage(code);
end

function VisualPicker.OnUpdate()
    EmojifyVisualPickerFrame:UpdateAnimations()
end
