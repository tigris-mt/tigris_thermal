local m = {}
tigris.thermal = m

-- Limits.
m.cold = {
    strong = tonumber(minetest.settings:get("tigris.thermal.cold.strong")) or 0,
    weak = tonumber(minetest.settings:get("tigris.thermal.cold.weak")) or 4,
}

m.hot = {
    weak = tonumber(minetest.settings:get("tigris.thermal.hot.weak")) or 29,
    strong = tonumber(minetest.settings:get("tigris.thermal.hot.strong")) or 33,
}

m.search = vector.new(8, 8, 8)

m.nodes = {}
m.nodenames = {}

local seed = 0
minetest.register_on_mapgen_init(function(params)
    seed = PseudoRandom(params.seed):next(0, 72)
end)

-- Get temperature information from pos.
-- Combine nearby nodes with biome data (sun & rainfall).
function m.at(pos)
    local underground = pos.y < -24

    -- Base temperature.
    local t = 6
    -- Add 10 at peak, scaled other times.
    t = t + (10 * (0.5 - math.abs(minetest.get_timeofday() - 0.5)) * 2)
    -- Add 4 for light level.
    t = t + 4 * ((minetest.get_node_light(pos) or 0) / 15)
    -- Subtract 4 for underground.
    if underground then
        t = t - 4
    end
    -- 18 game days (6 hours IRL, with time_speed 72) compose a complete season cycle.
    -- Add 5 degrees at peak heat.
    t = t + (5 * math.abs(((minetest.get_day_count() + seed) % 18) - 9) * 2 / 18)

    local env = 0
    local env_max = 500
    -- '1' nodes per degree.
    local env_f = 25

    local _, c = minetest.find_nodes_in_area(vector.subtract(pos, m.search), vector.add(pos, m.search),
        m.nodenames)

    for k,v in pairs(c) do
        local anum = m.nodes[k] * v
        env = env + anum
    end

    local env1 = math.max(-env_max, math.min(env, env_max)) / env_f
    local env2 = env1

    if not underground then
        local b = minetest.get_biome_data(pos)
        if b then
            env2 = (b.heat - 50) / 2
            if env2 < 15 then
                env2 = env2 * 2
            end
        end
    end

    t = t + (env1 + env2 * 2) / 3

    return t
end

-- Get thermal status from pos.
function m.status(pos)
    local t = m.at(pos)
    return {
        cold = (t < m.cold.strong and 0.5 or 0) + (t < m.cold.weak and 0.5 or 0),
        hot = (t > m.hot.weak and 0.5 or 0) + (t > m.hot.strong and 0.5 or 0),
    }
end

-- Register node with temperature level.
-- Ranges from -2 to +2, inclusive. 0 is no effect.
-- ±1 is nodes like sand or snowy dirt, ±2 is nodes like lava or deep snow.
function m.register(node, effect)
    assert(minetest.registered_nodes[node], node .. " is not registered.")
    m.nodes[node] = effect

    -- Remove from checklist if 0.
    if effect == 0 then
        m.nodes[node] = nil
    end

    m.nodenames = {}
    for k in pairs(m.nodes) do
        table.insert(m.nodenames, k)
    end
end

tigris.include("player.lua")

-- Register default nodes.

-- Very hot.
m.register("default:lava_source", 2)
m.register("default:lava_flowing", 2)

-- Hot.
m.register("default:desert_sand", 1)
m.register("default:desert_stone", 1)
m.register("default:sandstone", 1)
m.register("default:obsidian", 1)
m.register("default:dirt_with_dry_grass", 1)

-- Cold.
m.register("default:dirt_with_coniferous_litter", -1)
m.register("default:dirt_with_snow", -1)
m.register("default:silver_sand", -1)
m.register("default:snow", -1)
m.register("default:water_source", -1)
m.register("default:water_flowing", -1)
m.register("default:river_water_source", -1)
m.register("default:river_water_flowing", -1)

-- Very cold.
m.register("default:snowblock", -2)
m.register("default:ice", -2)
