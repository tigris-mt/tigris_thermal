local update_time = 3

local function update(player)
    local t = tigris.thermal.at(player:getpos())
    if not t then
        return
    end

    local v = tigris.thermal.status(t)
    if v.cold > 0 or v.hot > 0 then
        tigris.player.effect(player, "tigris_thermal:temperature", {s = v.cold + v.hot, t = t})

        if v.hot > 0.5 then
            tigris.player.effect(player, "tigris_thermal:very_hot", true)
        end

        tigris.damage.apply(player, {cold = v.cold})
        tigris.damage.apply(player, {heat = v.hot})
    else
        tigris.player.effect(player, "tigris_thermal:temperature", {s = false, t = t})
        tigris.player.effect(player, "tigris_thermal:very_hot", false)
    end
end

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > update_time then
        for _,player in pairs(minetest.get_connected_players()) do
            update(player)
        end
        timer = 0
    end
end)

minetest.register_on_joinplayer(function(player)
    timer = update_time
end)

tigris.player.register_effect("tigris_thermal:temperature", {
    description = "Extreme Temperature",
    status = true,
    set = function(player, old, new)
        local t = new.t
        local new = new.s

        local tex = "tigris_player_effect_x.png^[colorize:#FF0:200"
        if new and new > 0.5 then
            tex = tex .. "^(tigris_player_effect_enhance.png^[colorize:#F00:200)"
        end

        return {
            status = tex,
            on = not not new,
            remaining = -1,
            text = ("%d"):format(t),
        }
    end,
})

tigris.player.register_effect("tigris_thermal:very_hot", {
    description = "Very Hot",
    set = function(player, old, new)
        return {
            on = not not new,
            remaining = -1,
        }
    end,
})
