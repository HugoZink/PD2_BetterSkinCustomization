if not BetterSkinCustomization then
    _G.BetterSkinCustomization = {}

    BetterSkinCustomization._modPath = ModPath
    BetterSkinCustomization._savePath = SavePath .. "betterskincustomization.json"

    -- This table holds the following:
    -- Keys are weapon ID's.
    -- Value is a table where the keys are weaponfactory part names, and the values are just true.
    -- If a part is present in this table, the part will NOT listen to any weaponskins that are applied to it.
    -- This allows you to exclude certain weaponparts from getting affected by skins.
    -- Particularly useful for weapon color customization, where normally the "unaffected" parts are the same ugly black default matte plastic material.
    -- Now you can have your tacticool camo grips,
    -- without looking like your gun was made in Substance Painter with the default "gun" material pasted over the whole fucking thing

    -- Example: 
    --[[
        {
            p226 = {
                wpn_fps_pis_p226_body_standard = true
            }
        }
    ]]

    BetterSkinCustomization.excluded_weaponskin_parts = {}

    function BetterSkinCustomization:IsWeaponPartExcluded(weapon_id, part_id)
        if not self.excluded_weaponskin_parts then -- Table is empty, shouldn't really happen but if the save is somehow corrupt this could happen.
            return false
        elseif not self.excluded_weaponskin_parts[weapon_id] then -- This weapon has no excluded parts whatsoever.
            return false
        elseif not self.excluded_weaponskin_parts[weapon_id][part_id] then -- This particular part is not excluded.
            return false
        else -- This part is excluded.
            return true
        end
    end

    -- Load menu settings
    function BetterSkinCustomization:Load()
        local file = io.open(self._savePath, 'r')
        if file then
            local tbl = json.decode(file:read('*all'))
            file:close()

            if not tbl or type(table) ~= "table" then
                tbl = {}
            end

            self.excluded_weaponskin_parts = tbl
        end
    end

    -- Save current menu settings
    function BetterSkinCustomization:Save()
        local file = io.open(self._savePath, 'w+')
        if file then
            file:write(json.encode(self.excluded_weaponskin_parts))
            file:close()
        end
    end

    -- Immediately load/save settings to write a file and to load the settings early
    -- The settings loading is quarantined to a different file so that if the settings file is corrupt,
    -- it won't abort execution of this file. It will then overwrite the corrupt settings with fresh defaults.
    dofile(ModPath .. "loadsettings.lua")
    BetterSkinCustomization:Save()

    -- Create BeardLib MenuUI
    Hooks:Add("MenuManagerPostInitialize", "MenuManagerPostInitialize_BetterSkinCustomization_CreateMenu", function(menu_manager, nodes)
        local menu = MenuUI:new({
            name = "BetterSkinCustomization_Menu",
            max_width = 600,
            max_height = 250,
            layer = 10
        })

        local group = menu:DivGroup({
            name = "bsc_weaponmodlist",
            text = "Weaponmods to exclude from skins on this weapon"
        })

        BetterSkinCustomization._menu = menu
        BetterSkinCustomization._menu_modlist = group
    end)

    -- Update the menu with a list of weapon parts to enable/disable
    function BetterSkinCustomization:UpdateBlueprint(weapon)
        if not weapon or not weapon.weapon_id or not weapon.blueprint or not self._menu then
            return
        end

        -- Destroy the existing list, has no use anymore
        if self._menu_modlist then
            self._menu_modlist:Destroy()
            self._menu_modlist = nil
        end

        self._menu_modlist = self._menu:DivGroup({
            name = "bsc_weaponmodlist",
            text = "Weaponmods to exclude from skins on this weapon"
        })

        for _, part_id in pairs(weapon.blueprint) do
            local text = managers.localization:text(tweak_data.weapon.factory.parts[part_id].name_id)
            -- If this part has no localization (default or dummy parts etc), just display the raw ID 
            if string.find(text, "ERROR:") then
                text = part_id
            end

            local excluded = self:IsPartExcluded(weapon.weapon_id, part_id)

            self._menu_modlist:Button({
                name = "bsc_toggle_" .. part_id,
                text = text,
                enabled_alpha = excluded and 1 or 0.5,
                background_color = excluded and Color(0, 0, 1) or Color(0, 0, 0.5),
                max_width = 500,
                max_height = 200,
                on_callback = function(item)
                    -- Perform the exclusion and also obtain a result, then set that as color for this button.
                    local is_excluded = self:TogglePart(weapon.weapon_id, part_id)

                    if is_excluded then
                        item:Configure({
                            background_color = Color(0, 0, 1),
                            enabled_alpha = 1
                        })
                    else
                        item:Configure({
                            background_color = Color(0, 0, 0.5),
                            enabled_alpha = 0.5
                        })
                    end
                end
            })
        end
    end

    -- Exclude a weapon+part ID from getting skinned
    function BetterSkinCustomization:ExcludePart(weapon_id, part_id)
        if not weapon_id or not part_id then
            log("[BetterSkinCustomization] weapon_id or part_id was nil while trying to exclude a part!")
            return
        end

        if not self.excluded_weaponskin_parts[weapon_id] then
            self.excluded_weaponskin_parts[weapon_id] = {}
        end

        self.excluded_weaponskin_parts[weapon_id][part_id] = true

        self:Save()
    end

    -- Include a previously excluded part
    function BetterSkinCustomization:IncludePart(weapon_id, part_id)
        if not weapon_id or not part_id then
            log("[BetterSkinCustomization] weapon_id or part_id was nil while trying to include a part!")
            return
        end

        -- Shouldn't happen but you never know
        if not self.excluded_weaponskin_parts[weapon_id] then
            -- My job here is done!
            return
        end

        self.excluded_weaponskin_parts[weapon_id][part_id] = nil

        self:Save()
    end

    -- Toggle exclusions on/off
    function BetterSkinCustomization:TogglePart(...)
        if self:IsPartExcluded(...) then
            self:IncludePart(...)
            return false
        else
            self:ExcludePart(...)
            return true
        end
    end

    -- Is this part excluded?
    function BetterSkinCustomization:IsPartExcluded(weapon_id, part_id)
        if not weapon_id or not part_id then
            return false
        end

        if not self.excluded_weaponskin_parts[weapon_id] then
            return false
        end

        if not self.excluded_weaponskin_parts[weapon_id][part_id] then
            return false
        end

        return true
    end
end
