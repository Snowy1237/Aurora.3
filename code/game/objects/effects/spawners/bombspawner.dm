/client/proc/spawn_tanktransferbomb()
	set category = "Debug"
	set desc = "Spawn a tank transfer valve bomb"
	set name = "Instant TTV"

	if(!check_rights(R_FUN)) return

	var/obj/effect/spawner/newbomb/proto = /obj/effect/spawner/newbomb/radio/custom

	var/p = input("Enter phoron amount (mol):","Phoron", initial(proto.phoron_amt)) as num|null
	if(p == null) return

	var/o = input("Enter oxygen amount (mol):","Oxygen", initial(proto.oxygen_amt)) as num|null
	if(o == null) return

	var/c = input("Enter carbon dioxide amount (mol):","Carbon Dioxide", initial(proto.carbon_amt)) as num|null
	if(c == null) return

	new /obj/effect/spawner/newbomb/radio/custom(get_turf(mob), p, o, c)

/obj/effect/spawner/newbomb
	name = "TTV bomb"
	icon = 'icons/mob/screen/generic.dmi'
	icon_state = "x"

	var/assembly_type = /obj/item/device/assembly/signaler

	//Note that the maximum amount of gas you can put in a 70L air tank at 1013.25 kPa and 519K is 16.44 mol.
	var/phoron_amt = 10.96
	var/oxygen_amt = 16.44
	var/carbon_amt = 0.0

/obj/effect/spawner/newbomb/timer
	name = "TTV bomb - timer"
	assembly_type = /obj/item/device/assembly/timer

/obj/effect/spawner/newbomb/timer/syndicate
	name = "TTV bomb - merc"
	//High yield bombs. Yes, it is possible to make these with toxins
	phoron_amt = 15.66
	oxygen_amt = 24.66

/obj/effect/spawner/newbomb/proximity
	name = "TTV bomb - proximity"
	assembly_type = /obj/item/device/assembly/prox_sensor

/obj/effect/spawner/newbomb/radio/custom/Initialize(mapload, ph, ox, co)
	if(ph != null) phoron_amt = ph
	if(ox != null) oxygen_amt = ox
	if(co != null) carbon_amt = co
	. = ..()

/obj/effect/spawner/newbomb/Initialize()
	. = ..()

	var/obj/item/device/transfer_valve/V = new(src.loc)
	var/obj/item/tank/phoron/PT = new(V)
	var/obj/item/tank/oxygen/OT = new(V)

	V.tank_one = PT
	V.tank_two = OT

	PT.master = V
	OT.master = V

	PT.air_contents.temperature = PHORON_FLASHPOINT
	PT.air_contents.gas[GAS_PHORON] = phoron_amt
	PT.air_contents.gas[GAS_CO2] = carbon_amt
	PT.air_contents.update_values()

	OT.air_contents.temperature = PHORON_FLASHPOINT
	OT.air_contents.gas[GAS_OXYGEN] = oxygen_amt
	OT.air_contents.update_values()

	var/obj/item/device/assembly/S = new assembly_type(V)


	V.attached_device = S

	S.holder = V
	S.toggle_secure()

	V.update_icon()

	qdel(src)
