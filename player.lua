tigris.hud.register("tigris_thermal_info", {type = "text"})

local update_time = 1

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > update_time then
        for _,player in pairs(minetest.get_connected_players()) do
            local t = tigris.thermal.at(player:getpos())
            tigris.hud.update("tigris_thermal_info", player, ("%.1f °C %.1f °F"):format(t, t * 1.8 + 32))
        end
        timer = 0
    end
end)
