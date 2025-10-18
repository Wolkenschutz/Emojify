--------------------------------------------------------------------------------
-- Emojify - Chat Message Filter
-- Processes incoming chat messages and replaces emoji codes with textures
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

ns.ChatFilter = {};
local ChatFilter = ns.ChatFilter;
local Animation = ns.Animation;

local CHAT_EVENTS = {
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM"
};

local function EventFilter(chatFrame, event, message, ...)
	local newMessage = Animation.ProcessEmojiText(message);

	return false, newMessage, ...;
end

function ChatFilter.Initialize()
	for _, event in ipairs(CHAT_EVENTS) do
		ChatFrame_AddMessageEventFilter(event, EventFilter);
	end
end
