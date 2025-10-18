--------------------------------------------------------------------------------
-- Emojify - Emoji Registry & Pack API
-- Public API for registering emoji packs and managing emoji data
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local EmojiRegistry = {};
ns.EmojiRegistry = EmojiRegistry;

local Animation = ns.Animation;
local Constants = ns.Constants;

local emojis = ns.Emojis;
local animatedEmojis = ns.AnimatedEmojis;
local packs = ns.Packs;

local DEFAULT_FRAME_DELAY = Constants.DEFAULT_FRAME_DELAY;

local EmojifyAnimatedEmojiMixin = {};

function EmojifyAnimatedEmojiMixin:SetDefaultDelay(delayMs)
    assert(type(delayMs) == "number" and delayMs > 0, "Delay must be a positive number (in milliseconds)");

    self.data.defaultDelay = delayMs / 1000;
    return self;
end

function EmojifyAnimatedEmojiMixin:SetFrameDelay(frameIndex, delayMs)
    assert(type(frameIndex) == "number" and frameIndex >= 0, "Frame index must be >= 0");
    assert(type(delayMs) == "number" and delayMs > 0, "Delay must be a positive number (in milliseconds)");

    self.data.customDelays[frameIndex] = delayMs / 1000;
    return self;
end

local EmojifyPackMixin = {};

function EmojifyPackMixin:AddEmoji(code, widthOrSize, height)
    assert(code and code ~= "", "Emoji code cannot be empty");
    assert(not emojis[code] and not animatedEmojis[code], "Emoji code '" .. code .. "' already exists");

    local width = widthOrSize;
    height = height or widthOrSize;

    local data = {
        code = code,
        width = width,
        height = height,
        textureWidth = math.pow(2, math.ceil(math.log(width) / math.log(2))),
        textureHeight = height,
        texture = self.packPath .. "\\emojis\\" .. code
    };

    emojis[code] = data;
    return self;
end

function EmojifyPackMixin:AddAnimatedEmoji(code, frames, widthOrSize, height)
    assert(code and code ~= "", "Emoji code cannot be empty");
    assert(frames and frames >= 1, "Frames must be >= 1");
    assert(not emojis[code] and not animatedEmojis[code], "Emoji code '" .. code .. "' already exists");

    local width = widthOrSize;
    height = height or widthOrSize;

    local data = {
        code = code,
        frames = frames,
        width = width,
        height = height,
        textureWidth = math.pow(2, math.ceil(math.log(frames * width) / math.log(2))),
        textureHeight = height,
        texture = self.packPath .. "\\animated_emojis\\" .. code,
        defaultDelay = DEFAULT_FRAME_DELAY / 1000,
        customDelays = {}
    };

    animatedEmojis[code] = data;

    Animation.RegisterAnimatedEmoji(code, data);

    local animatedEmoji = CreateFromMixins(EmojifyAnimatedEmojiMixin);
    animatedEmoji.code = code;
    animatedEmoji.data = data;

    return animatedEmoji;
end

-- Aliases
EmojifyPackMixin.Emoji = EmojifyPackMixin.AddEmoji;
EmojifyPackMixin.Static = EmojifyPackMixin.AddEmoji;
EmojifyPackMixin.AnimatedEmoji = EmojifyPackMixin.AddAnimatedEmoji;
EmojifyPackMixin.Animated = EmojifyPackMixin.AddAnimatedEmoji;
EmojifyPackMixin.Anim = EmojifyPackMixin.AddAnimatedEmoji;

function Emojify:RegisterPack(packName)
    local cleanPackName = string.gsub(packName, "Emojify_", "");

    assert(cleanPackName and cleanPackName ~= "", "EmojifyPack addon name cannot be empty");
    assert(not packs[cleanPackName], "Pack '" .. cleanPackName .. "' already registered");

    local packPath = "Interface\\AddOns\\" .. packName;
    local version = C_AddOns.GetAddOnMetadata(packName, "Version") or UNKNOWN;
    local description = C_AddOns.GetAddOnMetadata(packName, "Notes") or UNKNOWN;

    local pack = CreateFromMixins(EmojifyPackMixin);
    pack.packName = cleanPackName;
    pack.packPath = packPath;
    pack.version = version;
    pack.description = description;

    packs[cleanPackName] = pack;

    return pack;
end

function Emojify:GetPack(packName)
    return packs[packName];
end

-- Aliases
Emojify.CreatePack = Emojify.RegisterPack;

function EmojiRegistry.RebuildEmojiCodes()
    table.wipe(ns.AllEmojiCodes);

    for code, data in pairs(emojis) do
        table.insert(ns.AllEmojiCodes, { code = code, isAnimated = false, data = { width = data.width, height = data.height } });
    end

    for code, data in pairs(animatedEmojis) do
        table.insert(ns.AllEmojiCodes, { code = code, isAnimated = true, data = { width = data.width, height = data.height } });
    end
end

function EmojiRegistry.GetRandomEmoji()
    local numCodes = #ns.AllEmojiCodes;

    if (numCodes == 0) then
        return {
            code = "NONE",
            data = {
                texture = string.format("Interface\\AddOns\\%s\\icon", ADDON_NAME),
                width = 22,
                height = 22,
                textureWidth = 32,
                textureHeight = 32
            },
            isAnimated = false
        };
    end

    local randomIndex = math.random(1, numCodes);
    local emojiInfo = ns.AllEmojiCodes[randomIndex];

    while (emojiInfo.isAnimated or emojiInfo.data.width ~= emojiInfo.data.height) do
        randomIndex = math.random(1, numCodes);
        emojiInfo = ns.AllEmojiCodes[randomIndex];
    end

    return {
        code = emojiInfo.code,
        data = emojis[emojiInfo.code],
        isAnimated = false
    };
end
