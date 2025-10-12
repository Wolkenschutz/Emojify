--------------------------------------------------------------------------------
-- Emojify - Picker UI Mixins
-- UI components for the emote picker window (HORIZONTAL sprite sheets)
--------------------------------------------------------------------------------

local addonName, ns = ...;

local Picker = ns.Picker;
local Animation = ns.Animation;

local GRID_COLUMNS = 6;

EmojifyPickerGridButtonMixin = {};

function EmojifyPickerGridButtonMixin:SetEmoteInfo(emoteInfo)
    self.emoteInfo = emoteInfo;

    local data = emoteInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local buttonSize = self:GetHeight();
    local displayHeight = buttonSize - 4;
    local displayWidth = math.floor(displayHeight * (frameWidth / frameHeight));

    self.Texture:SetTexture(data.texture);
    self.Texture:SetSize(displayWidth, displayHeight);

    if (emoteInfo.isAnimated) then
        self:UpdateAnimation();
    else
        self.Texture:SetTexCoord(
            0,
            frameWidth / data.textureWidth,
            0,
            frameHeight / data.textureHeight
        );
    end
end

function EmojifyPickerGridButtonMixin:UpdateAnimation()
    local data = self.emoteInfo.data;
    local frameWidth = data.width;
    local frameHeight = data.height;
    local frame = Animation.GetCurrentFrame(self.emoteInfo.code);
    local left = frame * frameWidth;
    local right = left + frameWidth;

    self.Texture:SetTexCoord(
        left / data.textureWidth,
        right / data.textureWidth,
        0,
        frameHeight / data.textureHeight
    );
end

function EmojifyPickerGridButtonMixin:OnClick()
    Picker.SendEmoji(self.emoteInfo.code);
end

function EmojifyPickerGridButtonMixin:OnEnter()
    self.Highlight:Show();
    EmojifyPickerFrame:SetPreview(self.emoteInfo);
end

function EmojifyPickerGridButtonMixin:OnLeave()
    self.Highlight:Hide();
end

EmojifyPickerHeaderMixin = {};

function EmojifyPickerHeaderMixin:SetPackInfo(packName, emoteCount, colorCode, isCollapsed)
    self.packName = packName;

    local r, g, b = CreateColorFromRGBHexString(colorCode):GetRGB();

    self.Text:SetText(string.format("%s (%d)", packName, emoteCount));
    self.Text:SetTextColor(r, g, b);
    self.Arrow:SetText(isCollapsed and "+" or "-");
end

function EmojifyPickerHeaderMixin:OnClick()
    Picker.ToggleSection(self.packName);
end

EmojifyPickerFrameMixin = {};

function EmojifyPickerFrameMixin:OnLoad()
    BackdropTemplateMixin.OnBackdropLoaded(self);
    table.insert(UISpecialFrames, self:GetName());

    local view = CreateScrollBoxListLinearView();
    view:SetElementExtentCalculator(function(dataIndex, elementData)
        if (elementData.type == "grid") then
            return 56; -- Grid row height
        end
        return 28;     -- Header height
    end);

    view:SetElementInitializer("EmojifyPickerElementTemplate", function(Frame, elementData)
        if (elementData.type == "header") then
            self:InitializeHeader(Frame, elementData);
        elseif (elementData.type == "grid") then
            self:InitializeGrid(Frame, elementData);
        end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

    self.currentSearch = "";
end

function EmojifyPickerFrameMixin:OnShow()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);

    if (self.isBuilding) then
        return;
    end

    self.isBuilding = true;
    self:RestorePosition();
    self:RebuildPicker();
    self.isBuilding = false;

    self:UpdatePickerAnimations();
end

function EmojifyPickerFrameMixin:OnHide()
    PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);

    Animation.SetVisibleAnimationsFromPicker({});
end

function EmojifyPickerFrameMixin:SavePosition()
    local point, _, relativePoint, x, y = self:GetPoint();
    EmojifyDB.pickerPosition = { point = point, relativePoint = relativePoint, x = x, y = y };
end

function EmojifyPickerFrameMixin:RestorePosition()
    local pos = EmojifyDB.pickerPosition;
    if (pos) then
        self:ClearAllPoints();
        self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y);
    end
end

function EmojifyPickerFrameMixin:OnDragStart()
    self:StartMoving();
end

function EmojifyPickerFrameMixin:OnDragStop()
    self:StopMovingOrSizing();
    self:SavePosition();
end

function EmojifyPickerFrameMixin:OnSearchChanged(searchText)
    if (self.currentSearch == searchText) then
        return;
    end

    self.currentSearch = searchText;
    self:RebuildPicker();
end

function EmojifyPickerFrameMixin:RebuildPicker()
    local dataProvider = CreateDataProvider();

    local sections;
    if (self.currentSearch ~= "") then
        sections = Picker.FilterBySearch(self.currentSearch);
    else
        sections = Picker.GetAllSections();
    end

    for _, section in ipairs(sections) do
        dataProvider:Insert({
            type = "header",
            packName = section.packName,
            emoteCount = #section.emotes,
            colorCode = Picker.ExtractPackColor(section.packName),
            isCollapsed = section.isCollapsed
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
end

function EmojifyPickerFrameMixin:InitializeHeader(Frame, data)
    Frame:SetHeight(28);

    if (Frame.Grid) then
        for _, Button in ipairs(Frame.Grid) do
            Button:Hide();
        end
    end

    if (not Frame.Header) then
        Frame.Header = CreateFrame("Button", nil, Frame, "EmojifyPickerHeaderTemplate");
        Frame.Header:SetPoint("TOPLEFT");
        Frame.Header:SetPoint("TOPRIGHT");
    end

    Frame.Header:SetPackInfo(data.packName, data.emoteCount, data.colorCode, data.isCollapsed);
    Frame.Header:Show();
end

function EmojifyPickerFrameMixin:InitializeGrid(Frame, data)
    Frame:SetHeight(56);

    if (Frame.Header) then
        Frame.Header:Hide();
    end

    if (not Frame.Grid) then
        Frame.Grid = {};

        for i = 1, GRID_COLUMNS do
            local Button = CreateFrame("Button", nil, Frame, "EmojifyPickerGridButtonTemplate");
            Button:SetPoint("TOPLEFT", 4 + (i - 1) * 52, -4);
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

function EmojifyPickerFrameMixin:UpdateAnimations()
    if (not self:IsShown()) then
        return;
    end

    self.ScrollBox:ForEachFrame(function(Frame)
        if (Frame.Grid) then
            for _, Button in ipairs(Frame.Grid) do
                if (Button:IsShown() and Button.emoteInfo and Button.emoteInfo.isAnimated) then
                    Button:UpdateAnimation();
                end
            end
        end
    end);

    if (self.currentPreview and self.currentPreview.isAnimated) then
        self:UpdatePreviewAnimation();
    end

    self:UpdatePickerAnimations();
end

function EmojifyPickerFrameMixin:UpdatePickerAnimations()
    if (not self:IsShown()) then
        return;
    end

    local found = {};

    self.ScrollBox:ForEachFrame(function(Frame)
        if (Frame.Grid) then
            for _, Button in ipairs(Frame.Grid) do
                if (Button:IsShown() and Button.emoteInfo and Button.emoteInfo.isAnimated) then
                    found[Button.emoteInfo.code] = true;
                end
            end
        end
    end);

    if (self.currentPreview and self.currentPreview.isAnimated) then
        found[self.currentPreview.code] = true;
    end

    Animation.SetVisibleAnimationsFromPicker(found);
end

function EmojifyPickerFrameMixin:SetPreview(emoteInfo)
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

    self:UpdatePickerAnimations();
end

function EmojifyPickerFrameMixin:UpdatePreviewAnimation()
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
