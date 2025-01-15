ardour {
    ["type"] = "EditorAction",
    name = "PRDC Set output",
    author = "doojonio",
    license = "GPL",
    description = [[Set output of selected routes to last selected route]],
}

function factory()
    local function connect_sides(output, input)
        local i = 0
        while true do
            local out = output:audio(i)
            local inp = input:audio(i)
            i = i + 1

            if (out:isnil() or inp:isnil()) then
                break
            end

            out:connect(inp:name())
        end

        i = 0
        while true do
            local out = output:midi(i)
            local inp = input:midi(i)
            i = i + 1

            if (out:isnil() or inp:isnil()) then
                break
            end

            out:connect(inp:name())
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

        input = send_to:input()
        for r in routes:iter() do
            if (r == send_to) then
                break
            end

            output = r:output()
            output:disconnect_all(nil)

            connect_sides(output, input)
        end
    end
end
