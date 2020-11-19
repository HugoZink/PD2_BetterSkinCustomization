dofile(ModPath .. "core.lua")

Hooks:PostHook(BlackMarketManager, "view_weapon", "bsc_blackmarketmanager_viewweapon_populatepartexclusionsmenu", function(self, category, slot)
    if not self._global.crafted_items[category] or not self._global.crafted_items[category][slot] then
        return
    end

    local weapon = self._global.crafted_items[category][slot]

    -- weapon.id is the non-factory ID
    -- weapon.blueprint is a table with weaponfactory part ID's as values. Keys are numerical.
    --[[
    {"locked_name":false,"weapon_id":"sparrow","equipped":true,"global_values":{"wpn_fps_pis_sparrow_b_threaded":"berry","wpn_fps_upg_pis_ns_edge":"vmp"},"factory_id":"wpn_fps_pis_sparrow","blueprint":["wpn_fps_pis_sparrow_body_rpl","wpn_fps_pis_sparrow_g_dummy","wpn_fps_pis_sparrow_m_standard","wpn_fps_pis_sparrow_sl_rpl","wpn_fps_pis_sparrow_b_threaded","wpn_fps_upg_pis_ns_edge"]}
    ]]
    BetterSkinCustomization:UpdateBlueprint(weapon)
end)
