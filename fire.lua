-- Increase fuel time by this factor.
local factor = tonumber(minetest.settings:get("tigris.thermal.fire_factor")) or 10

local fs = smartfs.create("tigris_thermal:fire", function(state)
    state:size(8, 5)
    state:inventory(0, 0, 1, 1, "fuel"):usePosition(state.location.pos)
    state:inventory(0, 1, 8, 4, "main")

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

        tiles = {"default_cobble.png^default_flint.png"},

        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-8/16, -8/16, -8/16, 8/16, -4/16, 8/16},
                {-8/16, -8/16, -8/16, -4/16, 8/16, 8/16},
                {4/16, -8/16, -8/16, 8/16, 8/16, 8/16},
                {-4/16, -8/16, -8/16, 4/16, 8/16, -4/16},
                {-4/16, -8/16, 8/16, 4/16, 8/16, 4/16},
            },
        },

        groups = {cracky = 2, not_in_creative_inventory = d.groups and d.groups.not_in_creative_inventory},
        sounds = default.node_sound_stone_defaults(),
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
            local top = vector.add(pos, vector.new(0, 1, 0))

            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local fuel_list = inv:get_list("fuel")

            local remaining = meta:get_float("remaining")
            local total = meta:get_int("total")
            local percent = meta:get_int("progress")

            if remaining <= 0 then
                local f, a = minetest.get_craft_result({method = "fuel", width = 1, items = fuel_list})
                if f.time ~= 0 then
                    inv:set_stack("fuel", 1, a.items[1])
                    remaining = f.time
                    total = f.time
                end
            end

            local clear = ((minetest.get_node(top).name == "air") or
                (minetest.get_node(top).name == "fire:permanent_flame"))

            local function update()
                meta:set_int("total", total)
                meta:set_float("remaining", remaining)
                meta:set_int("progress", percent)
                fs:attach_to_node(pos)
            end

            if remaining > 0 then
                if not clear then
                    update()
                    meta:set_string("infotext", "Fire blocked!")
                    return true
                end

                remaining = remaining - (dtime / factor)
            else
                update()
                return false
            end

            percent = math.floor(math.max(0, remaining) / math.max(1, total) * 100)

            if remaining > 0 then
                swap_node(top, "fire:permanent_flame")
                swap_node(pos, "tigris_thermal:fire_active")
                meta:set_string("infotext", "Active fire\n(Fuel: " .. percent .. "%)")
            else
                if minetest.get_node(top).name == "fire:permanent_flame" then
                    minetest.remove_node(top)
                end
                swap_node(pos, "tigris_thermal:fire")
                meta:set_string("infotext", "Inactive fire")
            end

            update()
            return true
        end,

        on_receive_fields = smartfs.nodemeta_on_receive_fields,

        on_destruct = function(pos)
            local top = vector.add(pos, vector.new(0, 1, 0))
            if minetest.get_node(top).name == "fire:permanent_flame" then
                minetest.remove_node(top)
            end
        end,
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
    groups = {not_in_creative_inventory = 1},
})

minetest.register_craft{
    output = "tigris_thermal:fire",
    recipe = {
        {"group:stone", "group:stick", "group:stone"},
        {"group:stone", "group:stick", "group:stone"},
        {"group:stone", "group:stone", "group:stone"},
    },
}
