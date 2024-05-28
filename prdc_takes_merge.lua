ardour {
  ["type"] = "EditorAction",
  name = "PRDC Takes merge",
  author = "doojonio",
  license = "GPL",
  description = [[Merges playlists on different tracks to one on the first selected track]],
}

function factory()
  local function is_it_ok()
    local md = LuaDialog.Message(
      "Confirm", "Are you sure?",
      LuaDialog.MessageType.Question,
      LuaDialog.ButtonType.Yes_No
    )
    local answer = md:run()

    md = nil
    collectgarbage()

    return answer == 3
  end

  return function()
    if (not is_it_ok()) then
      return
    end

    local sel = Editor:get_selection()

    local main_playlist = nil
    for r in sel.tracks:routelist():iter() do
      if (not main_playlist) then
        main_playlist = r:to_track():playlist()
        goto continue
      end

      local pl = r:to_track():playlist()

      for reg in pl:region_list():iter() do
        local clone = ARDOUR.RegionFactory.clone_region(reg, false, false)
        main_playlist:add_region(clone, reg:position(), 1, false)
      end

      ::continue::
    end
  end
end
