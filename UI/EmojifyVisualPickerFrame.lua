--------------------------------------------------------------------------------
-- Emojify - Visual Picker Frame Mixin
-- Main browsable emoji picker window with search and categories
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...;

local Animation = ns.Animation;
local VisualPicker = ns.VisualPicker;
local EmojiRegistry = ns.EmojiRegistry;

local GRID_COLUMNS = 6;

EmojifyVisualPickerMixin = {};

function EmojifyVisualPickerMixin:OnLoad()
    self:SetTitle("Emojify - Visual Picker");
    ButtonFrameTemplate_HidePortrait(self);
    ButtonFrameTemplate_HideAttic(self);

    self.Inset:SetPoint("TOPLEFT", 12, -57);
    self.Inset:SetPoint("BOTTOMRIGHT", -27, 60);
    self.Inset.Bg:SetHorizTile(false);
    self.Inset.Bg:SetVertTile(false);
    self.Inset.Bg:SetAtlas("QuestLog-main-background");
    self.Inset.Bg:SetAlpha(0.8);

    table.insert(UISpecialFrames, self:GetName());

    local view = CreateScrollBoxListLinearView(7, 0, 13, 13);
    view:SetElementExtentCalculator(function(dataIndex, elementData)
        if (elementData.type == "grid") then
            return 56; -- Grid row height
        end
        return 28;     -- Header height
    end);

    view:SetElementInitializer("EmojifyVisualPickerElementTemplate", function(Frame, elementData)
        if (elementData.type == "header") then
            self:InitializeHeader(Frame, elementData);
        elseif (elementData.type == "grid") then
            self:InitializeGrid(Frame, elementData);
        end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

    self.currentSearch = "";

    C_Timer.After(1.2, function()
        self:SetPreview(EmojiRegistry.GetRandomEmoji());
    end);
end

function EmojifyVisualPickerMixin:OnShow()
    if (self.isBuilding) then
        return;
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);

    self.isBuilding = true;
    self:RestorePosition();
    self:RebuildPicker();
    self.isBuilding = false;
end

function EmojifyVisualPickerMixin:OnHide()
    PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);

    Animation.SetVisibleAnimationsFromPicker({});
end

function EmojifyVisualPickerMixin:OnDragStart()
    self:StartMoving();
end

function EmojifyVisualPickerMixin:OnDragStop()
    self:StopMovingOrSizing();
    self:SavePosition();
end

function EmojifyVisualPickerMixin:SavePosition()
    local point, _, relativePoint, x, y = self:GetPoint();
    EmojifyDB.pickerPosition = { point = point, relativePoint = relativePoint, x = x, y = y };
end

function EmojifyVisualPickerMixin:RestorePosition()
    local pos = EmojifyDB.pickerPosition;
    if (pos) then
        self:ClearAllPoints();
        self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y);
    end
end

function EmojifyVisualPickerMixin:OnSearchChanged(SearchBox, searchText)
    SearchBoxTemplate_OnTextChanged(SearchBox);

    if (self.currentSearch == searchText) then
        return;
    end

    self.currentSearch = searchText;
    self:RebuildPicker();
end

function EmojifyVisualPickerMixin:RebuildPicker()
    local dataProvider = CreateDataProvider();

    local sections;
    if (self.currentSearch ~= "") then
        sections = VisualPicker.FilterBySearch(self.currentSearch);
    else
        sections = VisualPicker.GetAllSections();
    end

    for _, section in ipairs(sections) do
        dataProvider:Insert({
            type = "header",
            section = section
        });

        if (not section.isCollapsed) then
            local row = {};

            for i, emoteInfo in ipairs(section.emotes) do
                table.insert(row, emoteInfo);

                if (#row == GRID_COLUMNS or i == #section.emotes) then
                    dataProvider:Insert({
                        type = "grid",
                        emotes = row
                    });

                    row = {};
                end
            end
        end
    end

    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition);
    self:UpdateAnimations();
end

function EmojifyVisualPickerMixin:InitializeHeader(Frame, data)
    Frame:SetHeight(28);

    if (Frame.Grid) then
        for _, Button in ipairs(Frame.Grid) do
            Button:Hide();
        end
    end

    if (not Frame.Header) then
        Frame.Header = CreateFrame("Button", nil, Frame, "EmojifyVisualPickerPackHeaderButtonTemplate");
        Frame.Header:SetPoint("TOPLEFT");
        Frame.Header:SetPoint("TOPRIGHT");
    end

    local section = data.section;
    local packName = section.packName;
    local isCollapsed = section.isCollapsed;
    local colorCode = VisualPicker.ExtractPackColorCode(packName);
    local normalFontColor = CreateColorFromRGBHexString(colorCode);

    Frame.Header.normalFontColor = normalFontColor;
    Frame.Header.isCollapsed = isCollapsed;
    Frame.Header.packName = packName;

    Frame.Header.ButtonText:SetFormattedText("%s (%d)", packName, #section.emotes);
    Frame.Header.ButtonText:SetTextColor(normalFontColor:GetRGB());
    Frame.Header:UpdateCollapsedState(packName == EMOJIFY_SEARCH_RESULTS, isCollapsed);
    Frame.Header:Show();
end

function EmojifyVisualPickerMixin:InitializeGrid(Frame, data)
    Frame:SetHeight(56);

    if (Frame.Header) then
        Frame.Header:Hide();
    end

    if (not Frame.Grid) then
        Frame.Grid = {};

        for i = 1, GRID_COLUMNS do
            local Button = CreateFrame("Button", nil, Frame, "EmojifyVisualPickerGridButtonTemplate");
            Button:SetPoint("TOPLEFT", 5 + (i - 1) * 52, 0);
            Frame.Grid[i] = Button;
        end
    end

    for i = 1, GRID_COLUMNS do
        local Button = Frame.Grid[i];
        local emoteInfo = data.emotes[i];

        if (emoteInfo) then
            Button:SetEmoteInfo(emoteInfo);
            Button:Show();
        else
            Button:Hide();
        end
    end
end

function EmojifyVisualPickerMixin:UpdateAnimations()
    if (not self:IsShown()) then
        return;
    end

    local found = {};

    self.ScrollBox:ForEachFrame(function(Frame)
        if (Frame.Grid) then
            for _, Button in ipairs(Frame.Grid) do
                if (Button:IsShown() and Button.emoteInfo and Button.emoteInfo.isAnimated) then
                    found[Button.emoteInfo.code] = true;
                    Button:UpdateAnimation();
                end
            end
        end
    end);

    if (self.currentPreview and self.currentPreview.isAnimated) then
        found[self.currentPreview.code] = true;
        self:UpdatePreviewAnimation();
    end

    Animation.SetVisibleAnimationsFromPicker(found);
end

function EmojifyVisualPickerMixin:SetPreview(emoteInfo)
    self.currentPreview = emoteInfo;

    local data = emoteInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local displayHeight = 32;
    local displayWidth = math.floor(displayHeight * (frameWidth / frameHeight));

    self.PreviewBar.Icon:SetTexture(data.texture);
    self.PreviewBar.Icon:SetSize(displayWidth, displayHeight);
    self.PreviewBar.Code:SetText(emoteInfo.code);

    if (emoteInfo.isAnimated) then
        self:UpdatePreviewAnimation();
    else
        self.PreviewBar.Icon:SetTexCoord(
            0,
            frameWidth / data.textureWidth,
            0,
            frameHeight / data.textureHeight
        );
    end

    self:UpdateAnimations();
end

function EmojifyVisualPickerMixin:UpdatePreviewAnimation()
    local data = self.currentPreview.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local frame = Animation.GetCurrentFrame(self.currentPreview.code);
    local left = frame * frameWidth;
    local right = left + frameWidth;

    self.PreviewBar.Icon:SetTexCoord(
        left / data.textureWidth,
        right / data.textureWidth,
        0,
        frameHeight / data.textureHeight
    );
end
