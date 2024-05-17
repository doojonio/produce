ardour {
  ["type"] = "EditorAction",
  name = "Takes merge",
  author = "doojonio",
  license = "GPL",
  description = [[Merges playlists on different tracks to one on the first track]],
}

function factory()
  return function()
    local sel = Editor:get_selection()

    local main_playlist = nil
    for r in sel.tracks:routelist():iter() do
      if (not main_playlist) then
        main_playlist = r:to_track():playlist()
        goto continue
      end

      pl = r:to_track():playlist()

      for reg in pl:region_list():iter() do
        clone = ARDOUR.RegionFactory.clone_region(reg, false, false)
        main_playlist:add_region(clone, reg:position(), 1, false)
      end

      ::continue::
    end
  end
end
