--------------------------------------------------------------------------------
-- Emojify - Autocomplete Frame Controller
--------------------------------------------------------------------------------

local addonName, ns = ...;

ns.Autocomplete = {};
local Autocomplete = ns.Autocomplete;
local Trie = ns.Trie;

local MIN_SEARCH_LENGTH = ns.Constants.MIN_SEARCH_LENGTH;
local DEBOUNCE_DELAY = ns.Constants.DEBOUNCE_DELAY;
local TRIGGER_CHAR = ns.Constants.TRIGGER_CHAR;

local searchTimer;

local function GetCurrentWord(EditBox)
    local text = EditBox:GetText();
    local cursorPos = EditBox:GetCursorPosition();
    local wordStart = cursorPos;
    local foundTrigger = false;

    for i = cursorPos, 1, -1 do
        local char = string.sub(text, i, i);

        if (char:match("%s")) then
            wordStart = i + 1;
            break;
        end

        if (char == TRIGGER_CHAR) then
            wordStart = i;
            foundTrigger = true;
            break;
        end

        if (i == 1) then
            wordStart = 1;
        end
    end

    local word = string.sub(text, wordStart, cursorPos);
    if (foundTrigger and string.sub(word, 1, 1) == TRIGGER_CHAR) then
        return string.sub(word, 2);
    end

    return "";
end

local function PerformSearch(word)
    if (word == "" or #word < MIN_SEARCH_LENGTH or not Trie.HasMatches(word)) then
        EmojifyAutocompleteFrame:Hide();
        return;
    end

    local matches = Trie.FindMatches(word);
    EmojifyAutocompleteFrame:Show(matches, word);

    if (ACTIVE_CHAT_EDIT_BOX) then
        EmojifyAutocompleteFrame:ClearAllPoints();
        EmojifyAutocompleteFrame:SetPoint("BOTTOMLEFT", ACTIVE_CHAT_EDIT_BOX, "TOPLEFT", 0, 5);
    end
end

function Autocomplete.OnEditBoxTextChanged(EditBox)
    if (searchTimer) then
        searchTimer:Cancel();
    end

    local word = GetCurrentWord(EditBox);
    if (#word < MIN_SEARCH_LENGTH) then
        EmojifyAutocompleteFrame:Hide();
        return;
    end

    searchTimer = C_Timer.After(DEBOUNCE_DELAY, function()
        PerformSearch(word);
    end);
end

function Autocomplete.OnEditBoxFocusLost()
    if (not EmojifyAutocompleteFrame:IsMouseOver()) then
        C_Timer.After(0.2, Autocomplete.OnEditBoxEscapePressed);
    end
end

function Autocomplete.OnEditBoxTabPressed()
    if (EmojifyAutocompleteFrame:IsShown()) then
        EmojifyAutocompleteFrame:ConfirmSelection();
    end
end

function Autocomplete.OnEditBoxArrowPressed(key)
    if (key == "UP") then
        EmojifyAutocompleteFrame:SelectPrevious();
    elseif (key == "DOWN") then
        EmojifyAutocompleteFrame:SelectNext();
    end
end

function Autocomplete.OnEditBoxEscapePressed()
    EmojifyAutocompleteFrame:Hide();
end

function Autocomplete.OnEditBoxKeyDown(key)
    if (EmojifyAutocompleteFrame:IsShown() and (key == "ENTER" or key == "RETURN")) then
        local EditBox = ChatEdit_GetActiveWindow() or ChatEdit_GetLastActiveWindow();
        if (EditBox) then
            local oldText = EditBox:GetText();
            EditBox:SetText("");

            -- Restore text after sending if needed
            C_Timer.After(0.05, function()
                if (oldText and oldText ~= "") then
                    EditBox:SetText(oldText);
                end
            end);
        end

        EmojifyAutocompleteFrame:SendSelectedEmoji();
    end
end

function Autocomplete.OnUpdate()
    if (not ACTIVE_CHAT_EDIT_BOX) then
        EmojifyAutocompleteFrame:Hide();
        return;
    end

    if (EmojifyAutocompleteFrame:IsShown()) then
        EmojifyAutocompleteFrame:UpdateAnimations();
    end
end
