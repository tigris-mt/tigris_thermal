tigris.hud.register("tigris_thermal:info", {type = "text"})
tigris.hud.register("tigris_thermal:status", {type = "text"})

local update_time = 5

local function update(player)
    local t = tigris.thermal.at(player:getpos())
    local v = tigris.thermal.status(t)
    tigris.hud.update(player, "tigris_thermal:info", ("%.1f °C %.1f °F"):format(t, t * 1.8 + 32))
    local s = ""
    if v.cold ~= 0 then
        s = "cold"
    elseif v.hot ~= 0 then
        s = "hot"
    end
    tigris.hud.update(player, "tigris_thermal:status",
        ((v.cold > 0.5 or v.hot > 0.5) and "very " or "") .. s)
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
