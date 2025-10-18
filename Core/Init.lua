--------------------------------------------------------------------------------
-- Emojify - Core Initialization & Constants
-- Defines global constants, namespaces and utility functions
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

-- Public API
Emojify = {};

ns.Constants = {};
ns.Emojis = {};
ns.AnimatedEmojis = {};
ns.Packs = {};
ns.AllEmojiCodes = {};

ns.Constants.FIXED_FRAME_RATE = 0.01;
ns.Constants.DEFAULT_HEIGHT = 24;
ns.Constants.MIN_SEARCH_LENGTH = 2;
ns.Constants.DEBOUNCE_DELAY = 0.1;
ns.Constants.MAX_VISIBLE_AUTOCOMPLETE = 9;
ns.Constants.AUTO_CLOSE_TIME = 2;
ns.Constants.USAGE_DECAY_DAYS = 30;
ns.Constants.TRIGGER_CHAR = ":";
ns.Constants.DEFAULT_FRAME_DELAY = 40;

function ns.EscapePattern(str)
	return (string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"));
end