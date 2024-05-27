ardour {
  ["type"] = "EditorAction",
  name = "PRDC:Group Create",
  author = "doojonio",
  license = "GPL",
  description = [[Create group of selected tracks, create bus from template, set tracks outputs to bus]],
}

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
    local available_templates = {}
    for i, f in pairs(scandir(ARDOUR.user_config_directory(-1) .. "/route_templates/")) do
      if (string.sub(f, 0, 1) == "." and string.sub(f, -9) == ".template") then
        available_templates[string.sub(f, 0, -10)] = f
      end
    end

    local dialog_options = {
      {
        type = "dropdown",
        key = "template",
        title = "Template",
        values = available_templates,
        default = ".channel strip"
      },
    }

    local od = LuaDialog.Dialog("Choose template", dialog_options)
    local rv = od:run()

    if (not rv) then
      return nil
    end

    return rv["template"]
  end

  local function connect_sides(output, input)
    i = 0
    while true do
      out = output:audio(i)
      inp = input:audio(i)
      i = i + 1

      if (out:isnil() or inp:isnil()) then
        break
      end

      out:connect(inp:name())
    end

    i = 0
    while true do
      out = output:midi(i)
      inp = input:midi(i)
      i = i + 1

      if (out:isnil() or inp:isnil()) then
        break
      end

      out:connect(inp:name())
    end
  end

  local function extract_group_name(routes)
    group_name = routes:front():name()

    for r in routes:iter() do
      r_name = r:name()
      j = math.min(string.len(r_name), string.len(group_name))

      while (j > 0) do
        group_part = string.sub(group_name, 0, j)
        if (string.sub(r_name, 0, j) == group_part) then
          group_name = group_part
          break
        end
        j = j - 1
      end
    end

    return group_name
  end


  return function()
    local sel = Editor:get_selection()

    routes = sel.tracks:routelist()
    if (routes:size() < 2) then
      return
    end

    template_name = get_template()
    if (not template_name) then
      return
    end

    group_name = extract_group_name(routes)
    template_path = ARDOUR.user_config_directory(-1) .. "/route_templates/" .. template_name
    bus_rl = Session:new_route_from_template(
      1,
      ArdourUI.translate_order(ArdourUI.InsertAt.AfterSelection),
      template_path,
      "." .. group_name,
      ARDOUR.PlaylistDisposition.NewPlaylist
    )

    if (bus_rl:size() == 0) then
        print("failed to create " .. TRACK_NAME .. " route")
        return
    end

    bus = bus_rl:front()
    -- not bus protection
    if (bus:isnil() or not bus:to_track():isnil()) then
      return
    end

    input = bus:input()
    group = Session:new_route_group(group_name)
    for r in routes:iter() do
      group:add(r)

      output = r:output()
      output:disconnect_all(nil)

      connect_sides(output, input)
    end
  end
end
