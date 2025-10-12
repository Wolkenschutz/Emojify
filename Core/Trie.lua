--------------------------------------------------------------------------------
-- Emojify - Autocomplete Trie
--------------------------------------------------------------------------------

local addonName, ns = ...;

ns.Trie = {};
local Trie = ns.Trie;

local emojis = ns.Emojis;
local animatedEmojis = ns.AnimatedEmojis;

local autocompleteTrie;

local function GetWeightedUsage(code)
    return ns.Picker.GetUsageCount(code);
end

local TrieNode = {};
TrieNode.__index = TrieNode;

function TrieNode:new()
    return setmetatable({
        children = {},
        emojis = {},
        hasMatches = false
    }, TrieNode);
end

local TrieImpl = {};
TrieImpl.__index = TrieImpl;

function TrieImpl:new()
    return setmetatable({
        root = TrieNode:new()
    }, TrieImpl);
end

function TrieImpl:Insert(code, data, isAnimated)
    local node = self.root;

    for i = 1, #code do
        local char = string.sub(code, i, i);

        if (not node.children[char]) then
            node.children[char] = TrieNode:new();
        end

        node = node.children[char];
        node.hasMatches = true;
    end

    table.insert(node.emojis, {
        code = code,
        data = data,
        isAnimated = isAnimated,
        usageCount = GetWeightedUsage(code)
    });
end

function TrieImpl:HasMatches(prefix)
    local node = self.root;

    for i = 1, #prefix do
        local char = string.sub(prefix, i, i);
        node = node.children[char];

        if (not node) then
            return false;
        end
    end

    return node.hasMatches;
end

function TrieImpl:FindMatches(prefix)
    local node = self.root;

    for i = 1, #prefix do
        local char = string.sub(prefix, i, i);
        node = node.children[char];

        if (not node) then
            return {};
        end
    end

    local results = {};
    local function CollectEmojis(n)
        for _, emojiInfo in ipairs(n.emojis) do
            table.insert(results, emojiInfo);
        end

        for _, child in pairs(n.children) do
            CollectEmojis(child);
        end
    end
    CollectEmojis(node);

    table.sort(results, function(a, b)
        return a.usageCount > b.usageCount;
    end);

    return results;
end

function TrieImpl:IncrementUsage(code)
    ns.Picker.IncrementUsage(code);

    local node = self.root;

    for i = 1, #code do
        local char = string.sub(code, i, i);
        node = node.children[char];

        if (not node) then
            return;
        end
    end

    for _, emoji in ipairs(node.emojis) do
        if (emoji.code == code) then
            emoji.usageCount = GetWeightedUsage(code);
            break;
        end
    end
end

function Trie.RebuildAutocomplete()
    autocompleteTrie = TrieImpl:new();

    for code, data in pairs(emojis) do
        autocompleteTrie:Insert(code, data, false);
    end

    for code, data in pairs(animatedEmojis) do
        autocompleteTrie:Insert(code, data, true);
    end
end

function Trie.HasMatches(prefix)
    return autocompleteTrie:HasMatches(prefix);
end

function Trie.FindMatches(prefix, maxResults)
    return autocompleteTrie:FindMatches(prefix, maxResults);
end

function Trie.IncrementUsage(code)
    autocompleteTrie:IncrementUsage(code);
end
