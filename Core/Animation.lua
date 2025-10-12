--------------------------------------------------------------------------------
-- Emojify - Animation System
--------------------------------------------------------------------------------

local addonName, ns = ...;

ns.Animation = {};
local Animation = ns.Animation;

local emojis = ns.Emojis;
local animatedEmojis = ns.AnimatedEmojis;
local allEmojiCodes = ns.AllEmojiCodes;

local DEFAULT_HEIGHT = ns.Constants.DEFAULT_HEIGHT;
local DEFAULT_FRAME_DELAY = ns.Constants.DEFAULT_FRAME_DELAY;

local activeAnimations = {};
local visibleInChat = {};
local visibleInPicker = {};
local visibleInAutocomplete = {};
local visibleAnimations = {};
local currentFrames = {};
local timeAccumulated = {};
local hasVisibleAnimations = false;

function Animation.RegisterAnimatedEmoji(code, data)
    activeAnimations[code] = data;
    currentFrames[code] = 0;
    timeAccumulated[code] = 0;
end

function Animation.HasVisibleAnimations()
    return hasVisibleAnimations;
end

local function RebuildVisibleAnimations()
    table.wipe(visibleAnimations);

    for code in pairs(visibleInChat) do
        visibleAnimations[code] = true;
    end
    for code in pairs(visibleInPicker) do
        visibleAnimations[code] = true;
    end
    for code in pairs(visibleInAutocomplete) do
        visibleAnimations[code] = true;
    end

    hasVisibleAnimations = next(visibleAnimations) ~= nil;
end

function Animation.SetVisibleAnimationsFromChat(foundCodes)
    table.wipe(visibleInChat);

    for code in pairs(foundCodes) do
        visibleInChat[code] = true;
    end

    RebuildVisibleAnimations();
end

function Animation.SetVisibleAnimationsFromPicker(foundCodes)
    table.wipe(visibleInPicker);

    for code in pairs(foundCodes) do
        visibleInPicker[code] = true;
    end

    RebuildVisibleAnimations();
end

function Animation.SetVisibleAnimationsFromAutocomplete(foundCodes)
    table.wipe(visibleInAutocomplete);

    for code in pairs(foundCodes) do
        visibleInAutocomplete[code] = true;
    end

    RebuildVisibleAnimations();
end

function Animation.GetCurrentFrame(code)
    return currentFrames[code] or 0;
end

function Animation.GetFrameDelay(code, frameIndex)
    local data = activeAnimations[code];
    if (not data) then
        return DEFAULT_FRAME_DELAY / 1000;
    end

    return data.customDelays[frameIndex] or data.defaultDelay or (DEFAULT_FRAME_DELAY / 1000);
end

function Animation.ProcessEmojiText(message)
    local newMessage = message;
    local hasAnimated = false;

    for _, emojiInfo in ipairs(allEmojiCodes) do
        local code = emojiInfo.code;
        local isAnimated = emojiInfo.isAnimated;

        if (string.find(newMessage, code)) then
            local data = isAnimated and animatedEmojis[code] or emojis[code];
            local frameWidth = data.width;
            local frameHeight = data.height;
            local displayHeight = DEFAULT_HEIGHT;
            local displayWidth = math.floor(displayHeight * (frameWidth / frameHeight));

            local left, right;
            if (isAnimated) then
                hasAnimated = true;
                left = currentFrames[code] * frameWidth;
                right = left + frameWidth;
            else
                left = 0;
                right = frameWidth;
            end

            local escapedCode = ns.EscapePattern(code);
            newMessage = string.gsub(
                newMessage,
                "%f[%w_]" .. escapedCode .. "%f[^%w_]",
                string.format(
                    "|T%s:%d:%d:0:0:%d:%d:%d:%d:0:%d|t",
                    data.texture, displayHeight, displayWidth,
                    data.textureWidth, data.textureHeight,
                    left, right, data.height
                )
            );
        end
    end

    return newMessage, hasAnimated;
end

function Animation.UpdateAnimatedTextures(message)
    local newMessage = message;

    for code in string.gmatch(message, "Interface\\AddOns\\Emojify_[^\\]+\\animated_emojis\\([^:]+)") do
        local data = animatedEmojis[code];
        local frameWidth = data.width;
        local frameHeight = data.height;
        local displayHeight = DEFAULT_HEIGHT;
        local displayWidth = math.floor(displayHeight * (frameWidth / frameHeight));
        local left = currentFrames[code] * frameWidth;
        local right = left + frameWidth;
        local texture = data.texture;

        local escapedTexture = string.gsub(texture, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1");
        newMessage = string.gsub(
            newMessage,
            "|T" .. escapedTexture .. ".-:.-:.-:.-:.-:.-:.-:.-:.-:.-:.-|t",
            string.format(
                "|T%s:%d:%d:0:0:%d:%d:%d:%d:0:%d|t",
                texture, displayHeight, displayWidth,
                data.textureWidth, data.textureHeight,
                left, right, data.height
            )
        );
    end

    return newMessage;
end

function Animation.OnUpdate(deltaTime)
    for code in pairs(visibleAnimations) do
        local animData = activeAnimations[code];
        if (not animData) then
            visibleAnimations[code] = nil; -- Clean up invalid entry
        else
            timeAccumulated[code] = timeAccumulated[code] + deltaTime;

            local currentFrame = currentFrames[code];
            local frameDelay = Animation.GetFrameDelay(code, currentFrame);

            while (timeAccumulated[code] >= frameDelay) do
                timeAccumulated[code] = timeAccumulated[code] - frameDelay;
                currentFrames[code] = currentFrames[code] + 1;

                if (currentFrames[code] >= animData.frames) then
                    currentFrames[code] = 0;
                end

                currentFrame = currentFrames[code];
                frameDelay = Animation.GetFrameDelay(code, currentFrame);
            end
        end
    end
end
