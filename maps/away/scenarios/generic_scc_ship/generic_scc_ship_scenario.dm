/singleton/scenario/cryo_outpost
	name = "Large SCC Scout Vessel" // ask hazel to help with a better name or smth
	desc = "A large SCC scouting and transport vessel has arrived in this sector." // incomplete, need to think more about this
	scenario_site_id = "generic_scc_ship"
	// make something reasonable, have to think about the map first
	horizon_announcement_title = "SCC Central Command Outpost"
	horizon_announcement_message = "Greetings, SCCV Horizon. There's been some proprietary Zeng-Hu tech reported missing from nearby corporate facilities, \
	recently tracked down to a planet, Juliett-Enderly, located in your current sector. You are the closest to this planet, and should investigate and \
	recover any stolen tech, if any is found. Approach with caution, but heavy resistance is not expected, as monitored ship traffic is light around here."

	min_player_amount = 0
	min_actor_amount = 0 //should be 4 todomatt
	// map first
	roles = list(
		/singleton/role/cryo_outpost,
		/singleton/role/cryo_outpost/mercenary,
		/singleton/role/cryo_outpost/mercenary/medic,
		/singleton/role/cryo_outpost/mercenary/engineer,
		/singleton/role/cryo_outpost/director,
		/singleton/role/cryo_outpost/scientist,
		/singleton/role/cryo_outpost/engineer,
	)
	default_outfit = /obj/outfit/admin/generic/cryo_outpost_crew

	base_area = /area/cryo_outpost

//	radio_frequency_name = "#187-D Outpost"
