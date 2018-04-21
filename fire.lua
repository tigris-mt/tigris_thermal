-- Increase fuel time by this factor.
local factor = tonumber(minetest.settings:get("tigris.thermal.fire_factor")) or 10

local fs = smartfs.create("tigris_thermal:fire", function(state)
    state:size(8, 6)
    state:inventory(0, 0, 1, 1, "fuel"):usePosition(state.location.pos)
    state:inventory(0, 2, 8, 4, "main")

    state:element("code", {name = "listring", code = "listring[context;fuel]listring[current_player;main]"})

    local progress = minetest.get_meta(state.location.pos):get_int("progress")

    state:element("code", {name = "progress",
        code = "image[2,0;1,1;default_furnace_fire_bg.png^[lowpart:"..(progress)..":default_furnace_fire_fg.png]"})
end)

local function swap_node(pos, name)
    local node = minetest.get_node(pos)
    if node.name == name then
        return
    end
    node.name = name
    minetest.swap_node(pos, node)
end

local function tn(d)
    local a = {
        description = "Heating Fire",

        groups = {snappy = 3, not_in_creative_inventory = d.groups and d.groups.not_in_creative_inventory},
        sounds = default.node_sound_wood_defaults(),
        is_ground_content = false,

        drop = "tigris_thermal:fire",

        can_dig = function(pos, player)
            return minetest.get_meta(pos):get_inventory():is_empty("fuel")
        end,

        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            if minetest.is_protected(pos, player:get_player_name()) then
                return 0
            elseif minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
                return stack:get_count()
            else
                return 0
            end
        end,

        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
            if minetest.is_protected(pos, player:get_player_name()) then
                return 0
            end
            return stack:get_count()
        end,

        on_timer = function(pos, dtime)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local fuel_list = inv:get_list("fuel")

            local remaining = meta:get_float("remaining")
            local total = meta:get_int("total")

            if remaining <= 0 then
                local f, a = minetest.get_craft_result({method = "fuel", width = 1, items = fuel_list})
                if f.time ~= 0 then
                    inv:set_stack("fuel", 1, a.items[1])
                    remaining = f.time
                    total = f.time
                end
            end

            if remaining > 0 then
                remaining = remaining - (dtime / factor)
            end

            local percent = math.floor(math.max(0, remaining) / math.max(1, total) * 100)
            local rc = false

            if remaining > 0 then
                swap_node(pos, "tigris_thermal:fire_active")
                meta:set_string("infotext", "Active fire\n(Fuel: " .. percent .. "%)")
                rc = true
            else
                swap_node(pos, "tigris_thermal:fire")
                meta:set_string("infotext", "Inactive fire")
                minetest.get_node_timer(pos):stop()
            end

            meta:set_int("total", total)
            meta:set_float("remaining", remaining)
            meta:set_int("progress", percent)
            fs:attach_to_node(pos)

            return rc
        end,

        on_receive_fields = smartfs.nodemeta_on_receive_fields,
    }
    for k,v in pairs(a) do
        d[k] = v
    end

    return d
end

minetest.register_node("tigris_thermal:fire", tn{
    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_construct = function(pos)
        local inv = minetest.get_meta(pos):get_inventory()
        inv:set_size("fuel", 1)
        fs:attach_to_node(pos)
    end,
})

minetest.register_node("tigris_thermal:fire_active", tn{
    light_source = 12,
    groups = {not_in_creative_inventory = 1},
})

tigris.thermal.register_heat_source("tigris_thermal:fire_active")
