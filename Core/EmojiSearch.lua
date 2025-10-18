--------------------------------------------------------------------------------
-- Emojify - Emoji Search Engine
-- Provides search functionality with usage-based ranking
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

ns.EmojiSearch = {};
local EmojiSearch = ns.EmojiSearch;

local emojis = ns.Emojis;
local animatedEmojis = ns.AnimatedEmojis;

local searchableEmojis = {};

local function GetWeightedUsage(code)
    return ns.VisualPicker.GetUsageCount(code);
end

function EmojiSearch.RebuildSearchIndex()
    table.wipe(searchableEmojis);

    for code, data in pairs(emojis) do
        table.insert(searchableEmojis, {
            code = code,
            lowerCode = string.lower(code),
            data = data,
            isAnimated = false,
            usageCount = GetWeightedUsage(code)
        });
    end

    for code, data in pairs(animatedEmojis) do
        table.insert(searchableEmojis, {
            code = code,
            lowerCode = string.lower(code),
            data = data,
            isAnimated = true,
            usageCount = GetWeightedUsage(code)
        });
    end
end

function EmojiSearch.HasMatches(searchText)
    if (not searchText or searchText == "") then
        return false;
    end

    local lowerSearch = string.lower(searchText);

    for _, emoji in ipairs(searchableEmojis) do
        if (string.find(emoji.lowerCode, lowerSearch, 1, true)) then
            return true;
        end
    end

    return false;
end

function EmojiSearch.FindMatches(searchText)
    if (not searchText or searchText == "") then
        return {};
    end

    local lowerSearch = string.lower(searchText);
    local results = {};

    for _, emoji in ipairs(searchableEmojis) do
        if (string.find(emoji.lowerCode, lowerSearch, 1, true)) then
            table.insert(results, {
                code = emoji.code,
                data = emoji.data,
                isAnimated = emoji.isAnimated,
                usageCount = GetWeightedUsage(emoji.code)
            });
        end
    end

    table.sort(results, function(a, b)
        if (a.usageCount == b.usageCount) then
            return a.code < b.code;
        end
        return a.usageCount > b.usageCount;
    end);

    return results;
end

function EmojiSearch.IncrementUsage(code)
    ns.VisualPicker.IncrementUsage(code);

    for _, emoji in ipairs(searchableEmojis) do
        if (emoji.code == code) then
            emoji.usageCount = GetWeightedUsage(code);
            break;
        end
    end
end
