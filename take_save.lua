ardour {
    ["type"] = "EditorAction",
    name = "Take save",
    author = "doojonio",
    license = "GPL",
    description = [[Saves the current playlist on a new track from vox template and creates new playlist for the current one]],
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
            TEMPLATE = DEFAULT_TEMPLATE
            return DEFAULT_TEMPLATE
        end

        TRACK_NAME = rv["track_name"] or TRACK_NAME
        TEMPLATE = rv["template"]

        return TEMPLATE or DEFAULT_TEMPLATE
    end

    return function()
        template_name = ARDOUR.user_config_directory(-1) .. "/route_templates/" .. get_template()
        new_route = Session:new_route_from_template(
            1,
            ArdourUI.translate_order(ArdourUI.InsertAt.AfterSelection),
            template_name,
            TRACK_NAME,
            ARDOUR.PlaylistDisposition.NewPlaylist
        )
        if (new_route:size() == 0) then
            print("failed to create vox take route")
            return
        end

        for route in Session:get_tracks():iter() do
            if (route:rec_enable_control():get_value() == 0) then
                goto continue
            end

            new_route:front():to_track():use_playlist(ARDOUR.DataType:audio(), route:to_track():playlist(), 1)
            route:to_track():use_new_playlist(ARDOUR.DataType:audio())

            ::continue::
        end
    end
end
