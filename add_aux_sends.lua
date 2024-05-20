ardour {
    ["type"] = "EditorAction",
    name = "Add AUX Sends",
    author = "doojonio",
    license = "GPL",
    description = [[Add aux sends to last selected route for all selected routes except the last one]],
}

function factory()
    local function get_gain_value()
        local dialog_options = {
            { type = "fader", key = "gain", title = "Level", default = 0 }, -- unit = 'dB"
        }

        local od = LuaDialog.Dialog("Send gain", dialog_options)
        local rv = od:run()
        if (rv) then
            return ARDOUR.DSP.dB_to_coefficient(rv["gain"])
        else
            return nil
        end
    end

    local function get_last_send(route)
        i = 0
        last_send = nil
        while true do
            send = route:nth_send(i)
            i = i + 1
            if (send:isnil()) then
                return last_send
            end

            last_send = send
        end
    end

    return function()
        local sel = Editor:get_selection()

        routes = sel.tracks:routelist()
        if (routes:size() < 2) then
            return
        end

        send_to = routes:back()
        -- not bus protection
        if (not send_to:to_track():isnil()) then
            return
        end

        gain_value = get_gain_value()
        if (gain_value == nil) then
            return
        end


        for r in routes:iter() do
            if (r == send_to) then
                break
            end

            result = r:add_aux_send(send_to, r:nth_plugin(-1))
            if (result == -1) then
                print("failed to add send")
                goto continue
            end
            last_send = get_last_send(r)

            if (last_send) then
                last_send:to_send():gain_control():set_value(gain_value, PBD.GroupControlDisposition.NoGroup)
            else
                print("failed to get last send")
            end

            ::continue::
        end
    end
end
