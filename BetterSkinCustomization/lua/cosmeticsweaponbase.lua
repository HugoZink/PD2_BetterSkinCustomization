dofile(ModPath .. "core.lua")

-- Overridden to prevent the application of skin materials to specific weapon parts
function NewRaycastWeaponBase:_update_materials()
	if not self._parts then
		return
	end

	local use = not self:is_npc() or self:use_thq()
	local use_cc_material_config = use and self._cosmetics_data and true or false
	local is_thq = self:is_npc() and self:use_thq()
	is_thq = is_thq or not self:is_npc() and _G.IS_VR

	if is_thq or use_cc_material_config then
		if not self._materials then
			local material_config_ids = Idstring("material_config")

			for part_id, part in pairs(self._parts) do
				if not BetterSkinCustomization:IsWeaponPartExcluded(self._name_id, part_id) then
					local part_data = managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, self._factory_id, self._blueprint)

					if part_data then
						local new_material_config_ids = self:_material_config_name(part_id, part_data.unit, use_cc_material_config)

						if part.unit:material_config() ~= new_material_config_ids and DB:has(material_config_ids, new_material_config_ids) then
							part.unit:set_material_config(new_material_config_ids, true)
						end
					end
				end
			end

			if use_cc_material_config then
				self._materials = {}
				self._materials_default = {}

				for part_id, part in pairs(self._parts) do
					if not BetterSkinCustomization:IsWeaponPartExcluded(self._name_id, part_id) then
						local materials = part.unit:get_objects_by_type(Idstring("material"))

						for _, m in ipairs(materials) do
							if m:variable_exists(Idstring("wear_tear_value")) then
								self._materials[part_id] = self._materials[part_id] or {}
								self._materials[part_id][m:key()] = m
							end
						end
					end
				end
			end
		end
	elseif self._materials then
		local material_config_ids = Idstring("material_config")

		for part_id, part in pairs(self._parts) do
			if not BetterSkinCustomization:IsWeaponPartExcluded(self._name_id, part_id) then
				if tweak_data.weapon.factory.parts[part_id] then
					local new_material_config_ids = tweak_data.weapon.factory.parts[part_id].material_config or Idstring(self:is_npc() and tweak_data.weapon.factory.parts[part_id].third_unit or tweak_data.weapon.factory.parts[part_id].unit)

					if part.unit:material_config() ~= new_material_config_ids and DB:has(material_config_ids, new_material_config_ids) then
						part.unit:set_material_config(new_material_config_ids, true)
					end
				end
			end
		end

		self._materials = nil
	end
end
