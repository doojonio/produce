ardour {
    ["type"] = "EditorAction",
    name = "PRDC:Take save",
    author = "doojonio",
    license = "GPL",
    description = [[
        Moves the rec-armed track's playlist to a new track, created with initially selected template and name
    ]],
}

DEFAULT_TEMPLATE = "vox take.template"
TRACK_NAME = "vox take"
TEMPLATE = nil

function factory()
    function scandir(directory)
        local i, t, popen = 0, {}, io.popen
        local pfile = popen('ls -a "' .. directory .. '"')
        for filename in pfile:lines() do
            i = i + 1
            t[i] = filename
        end
        pfile:close()
        return t
    end

    function get_template()
        if (TEMPLATE) then
            return TEMPLATE
        end

        local available_templates = {}
        for i, f in pairs(scandir(ARDOUR.user_config_directory(-1) .. "/route_templates/")) do
            if (string.sub(f, -9) == ".template") then
                available_templates[string.sub(f, 0, -10)] = f
            end
        end

        local dialog_options = {
            {
                type = "dropdown",
                key = "template",
                title = "Template",
                values = available_templates,
                default = "vox take"
            },
            {
                type = "entry",
                key = "track_name",
                default = "vox take",
                title = "Take track name"
            },
        }

        local od = LuaDialog.Dialog("Choose template", dialog_options)
        local rv = od:run()

        if (not rv) then
            TEMPLATE = nil
            return nil
        end

        TRACK_NAME = rv["track_name"] or TRACK_NAME
        TEMPLATE = rv["template"]

        return TEMPLATE
    end

    function get_rec_armed_track()
        for route in Session:get_tracks():iter() do
            if (route:rec_enable_control():get_value() == 1) then
                return route:to_track()
            end
        end

        return nil
    end

    return function()
        rec_armed = get_rec_armed_track()
        if (not rec_armed) then
            TEMPLATE = nil
            return
        end

        template_name = get_template()
        if (not template_name) then
            return
        end

        template_path = ARDOUR.user_config_directory(-1) .. "/route_templates/" .. template_name
        new_route = Session:new_route_from_template(
            1,
            ArdourUI.translate_order(ArdourUI.InsertAt.AfterSelection),
            template_path,
            TRACK_NAME,
            ARDOUR.PlaylistDisposition.NewPlaylist
        )
        if (new_route:size() == 0) then
            print("failed to create " .. TRACK_NAME .. " route")
            return
        end

        new_route:front():to_track():use_playlist(ARDOUR.DataType:audio(), rec_armed:playlist(), 1)
        rec_armed:to_track():use_new_playlist(ARDOUR.DataType:audio())
    end
end
