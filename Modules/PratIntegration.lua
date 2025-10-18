--------------------------------------------------------------------------------
-- Emojify - Prat Integration
-- Protects Emojify texture strings from being modified by Prat modules
--------------------------------------------------------------------------------

if (not Prat) then
    return;
end

Prat:AddModuleExtension(function()
    Prat.RegisterPattern({
        pattern = "|TInterface\\AddOns\\Emojify_.-|t",
        matchfunc = function(link) return Prat:RegisterMatch(link) end,
        type = "FRAME",
        priority = 0
    }, "Emojify_Protection");
end)
