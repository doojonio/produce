ardour {
	["type"] = "EditorAction",
	name = "Take save",
	author = "doojonio",
	license = "GPL",
	description = [[Saves the current playlist on a new track from vox template and creates new playlist for the current one]],
}

function factory () return function ()
	-- TODO: prompt
	template_name = os.getenv("HOME") .."/.config/ardour8/route_templates/vox.template"
	new_route = Session:new_route_from_template(
		1,
		ArdourUI.translate_order(ArdourUI.InsertAt.AfterSelection),
		template_name,
		"vox take",
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

end end
