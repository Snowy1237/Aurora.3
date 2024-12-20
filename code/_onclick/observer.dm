/client/var/inquisitive_ghost = 1
/mob/abstract/observer/verb/toggle_inquisition() // warning: unexpected inquisition
	set name = "Toggle Inquisitiveness"
	set desc = "Sets whether your ghost examines everything on click by default"
	set category = "Ghost"
	if(!client) return
	client.inquisitive_ghost = !client.inquisitive_ghost
	if(client.inquisitive_ghost)
		to_chat(src, SPAN_NOTICE("You will now examine everything you click on."))
	else
		to_chat(src, SPAN_NOTICE("You will no longer examine things you click on."))

/mob/abstract/observer/DblClickOn(var/atom/A, var/params)
	if(can_reenter_corpse && mind && mind.current)
		if(A == mind.current || (mind.current in A)) // double click your corpse or whatever holds it
			reenter_corpse()						// (cloning scanner, body bag, closet, mech, etc)
			return									// seems legit.

	orbiting?.end_orbit(src) // stop orbiting

	// Things you might plausibly want to follow
	if((ismob(A) && A != src) || istype(A,/obj/machinery/bot) || istype(A,/obj/singularity))
		ManualFollow(A)

	// Otherwise jump
	else
		forceMove(get_turf(A))

/mob/abstract/observer/ClickOn(var/atom/A, var/params)
	if(!canClick()) return
	setClickCooldown(4)
	// You are responsible for checking config.ghost_interaction when you override this function
	// Not all of them require checking, see below
	A.attack_ghost(src)

// Oh by the way this didn't work with old click code which is why clicking shit didn't spam you
/atom/proc/attack_ghost(mob/abstract/observer/user as mob)
	if(user.client && user.client.inquisitive_ghost)
		examinate(user, src)
	return

// ---------------------------------------
// And here are some good things for free:
// Now you can click through portals, wormholes, gateways, and teleporters while observing. -Sayu

/obj/machinery/teleport/pad/attack_ghost(mob/user as mob)
	if(locked_obj)
		var/obj/teleport_obj = locked_obj.resolve()
		if(teleport_obj)
			user.forceMove(get_turf(teleport_obj))

/obj/effect/portal/attack_ghost(mob/user as mob)
	if(target)
		user.forceMove(get_turf(target))

/obj/machinery/gateway/centerstation/attack_ghost(mob/user as mob)
	if(awaygate)
		user.forceMove(awaygate.loc)
	else
		to_chat(user, "[src] has no destination.")

/obj/machinery/gateway/centeraway/attack_ghost(mob/user as mob)
	if(stationgate)
		user.forceMove(stationgate.loc)
	else
		to_chat(user, "[src] has no destination.")

// -------------------------------------------
// This was supposed to be used by adminghosts
// I think it is a *terrible* idea
// but I'm leaving it here anyway
// commented out, of course.
/*
/atom/proc/attack_admin(mob/user as mob)
	if(!user || !user.client || !user.client.holder)
		return
	attack_hand(user)

*/
