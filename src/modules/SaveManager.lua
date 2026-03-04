local httpService = game:GetService('HttpService')

local SaveManager = {} do
    SaveManager.Folder = 'Dig Training - NebulaX'
    SaveManager.Ignore = {}
    
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object) return { type = 'Toggle', idx = idx, value = object.Value } end,
            Load = function(idx, data)
                if Toggles[idx] then Toggles[idx].Value = data.value end
            end,
        },
        Slider = {
            Save = function(idx, object) return { type = 'Slider', idx = idx, value = tonumber(object.Value) } end,
            Load = function(idx, data)
                if Options[idx] then Options[idx].Value = tonumber(data.value) end
            end,
        },
        Dropdown = {
            Save = function(idx, object) return { type = 'Dropdown', idx = idx, value = object.Value } end,
            Load = function(idx, data)
                if Options[idx] then Options[idx].Value = data.value end
            end,
        },
        ColorPicker = {
            Save = function(idx, object) return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency } end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx].Value = Color3.fromHex(data.value)
                    Options[idx].Transparency = data.transparency
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object) return { type = 'KeyPicker', idx = idx, value = object.Value } end,
            Load = function(idx, data)
                if Options[idx] then Options[idx].Value = data.value end
            end,
        },
        Input = {
            Save = function(idx, object) return { type = 'Input', idx = idx, text = object.Value } end,
            Load = function(idx, data)
                if Options[idx] then Options[idx].Value = tostring(data.text) end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do self.Ignore[key] = true end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if (not name) then return false, 'no config file is selected' end
        local fullPath = self.Folder .. '/User/' .. name .. '.json'

        local data = { DataSave = {} }

        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            data.DataSave[idx] = toggle.Value
        end

        for idx, option in next, Options do
            if self.Ignore[idx] then continue end
            data.DataSave[idx] = option.Value
        end 

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then return false, 'failed to encode data' end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if (not name) then return false, 'no config file is selected' end
        local file = self.Folder .. '/User/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success or not decoded.DataSave then return false, 'decode error' end

        for flag, value in next, decoded.DataSave do
            task.spawn(function()
                if Toggles[flag] then
                    Toggles[flag].Value = value
                elseif Options[flag] then
                    Options[flag].Value = value
                end
            end)
        end
        return true
    end

    function SaveManager:BuildFolderTree()
        local paths = { self.Folder, self.Folder .. '/User' }
        for i = 1, #paths do
            if not isfolder(paths[i]) then makefolder(paths[i]) end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. '/User')
        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(out, name) end
            end
        end
        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. '/User/autoload.txt') then
            local name = readfile(self.Folder .. '/User/autoload.txt')
            self:Load(name)
        end
    end

    function SaveManager:BuildConfigSection(tab)
        local section = tab:PageSection({ Title = "Configuration" })
        local form = section:Form()

        local configInput = form:Row():Right():Input({
            Placeholder = "Config Name...",
            ValueChanged = function(self, v) end
        })
        configInput.Type = "Input"
        Options["SaveManager_ConfigName"] = configInput

        local configList = form:Row():Right():PullDownButton({
            Label = "Select Config",
            Options = self:RefreshConfigList(),
            ValueChanged = function(self, v) end
        })
        configList.Type = "Dropdown"
        Options["SaveManager_ConfigList"] = configList

        local btnRow = form:Row()
        btnRow:Right():Button({
            Label = "Create",
            Pushed = function()
                local name = Options["SaveManager_ConfigName"].Value
                if name ~= "" then 
                    self:Save(name)
                    configList:Option(name)
                end
            end
        })

        btnRow:Right():Button({
            Label = "Load",
            Pushed = function()
                local name = Options["SaveManager_ConfigList"].Value
                if name then self:Load(name) end
            end
        })
        
        btnRow:Right():Button({
            Label = "Refresh",
            Pushed = function()
                configList:Options(self:RefreshConfigList())
            end
        })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
