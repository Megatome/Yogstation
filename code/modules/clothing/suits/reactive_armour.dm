/obj/item/reactive_armor_shell
	name = "reactive armor shell"
	desc = "An experimental suit of armor, awaiting installation of an anomaly core."
	icon_state = "reactiveoff"
	icon = 'icons/obj/clothing/suits.dmi'
	w_class = WEIGHT_CLASS_BULKY

/obj/item/reactive_armor_shell/attackby(obj/item/I, mob/user, params)
	..()
	var/static/list/anomaly_armor_types = list(
		/obj/effect/anomaly/grav	                = /obj/item/clothing/suit/armor/reactive/repulse,
		/obj/effect/anomaly/flux 	           		= /obj/item/clothing/suit/armor/reactive/tesla,
		/obj/effect/anomaly/pyro	  			    = /obj/item/clothing/suit/armor/reactive/fire,
		/obj/effect/anomaly/bluespace 	            = /obj/item/clothing/suit/armor/reactive/teleport
		)

	if(istype(I, /obj/item/assembly/signaler/anomaly))
		var/obj/item/assembly/signaler/anomaly/A = I
		var/armor_path = anomaly_armor_types[A.anomaly_type]
		if(!armor_path)
			armor_path = /obj/item/clothing/suit/armor/reactive/stealth //Lets not cheat the player if an anomaly type doesnt have its own armor coded
		to_chat(user, "You insert [A] into the chest plate, and the armor gently hums to life.")
		new armor_path(get_turf(src))
		qdel(src)
		qdel(A)

//Reactive armor
/obj/item/clothing/suit/armor/reactive
	name = "reactive armor"
	desc = "Doesn't seem to do much for some reason."
	var/active = 0
	var/reactivearmor_cooldown_duration = 0 //cooldown specific to reactive armor
	var/reactivearmor_cooldown = 0
	icon_state = "reactiveoff"
	item_state = "reactiveoff"
	blood_overlay_type = "armor"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	actions_types = list(/datum/action/item_action/toggle)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	hit_reaction_chance = 50

/obj/item/clothing/suit/armor/reactive/attack_self(mob/user)
	active = !(active)
	if(active)
		to_chat(user, span_notice("[src] is now active."))
		icon_state = "reactive"
		item_state = "reactive"
	else
		to_chat(user, span_notice("[src] is now inactive."))
		icon_state = "reactiveoff"
		item_state = "reactiveoff"
	add_fingerprint(user)
	return

/obj/item/clothing/suit/armor/reactive/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	active = 0
	icon_state = "reactiveoff"
	item_state = "reactiveoff"
	reactivearmor_cooldown = world.time + 200

//When the wearer gets hit, this armor will teleport the user a short distance away (to safety or to more danger, no one knows. That's the fun of it!)
/obj/item/clothing/suit/armor/reactive/teleport
	name = "reactive teleport armor"
	desc = "Someone separated our Research Director from his own head!"
	var/tele_range = 6
	var/rad_amount= 15
	reactivearmor_cooldown_duration = 100

/obj/item/clothing/suit/armor/reactive/teleport/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return 0
	if(!damage)
		return 0
	if(prob(hit_reaction_chance))
		var/mob/living/carbon/human/H = owner
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("The reactive teleport system is still recharging! It fails to teleport [H]!"))
			return
		owner.visible_message(span_danger("The reactive teleport system flings [H] clear of [attack_text], shutting itself off in the process!"))
		do_teleport(H, get_turf(H), tele_range, asoundin = 'sound/magic/blink.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
		H.rad_act(rad_amount)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return 1
	return 0

//Fire

/obj/item/clothing/suit/armor/reactive/fire
	name = "reactive incendiary armor"
	desc = "An experimental suit of armor with a reactive sensor array rigged to a flame emitter. For the stylish pyromaniac."

/obj/item/clothing/suit/armor/reactive/fire/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return 0
	if(!damage)
		return 0
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("The reactive incendiary armor on [owner] activates, but fails to send out flames as it is still recharging its flame jets!"))
			return
		owner.visible_message(span_danger("[src] blocks [attack_text], sending out jets of flame!"))
		playsound(get_turf(owner),'sound/magic/fireball.ogg', 100, 1)
		for(var/mob/living/carbon/C in range(6, owner))
			if(C != owner)
				C.fire_stacks += 8
				C.IgniteMob()
		owner.fire_stacks = -20
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return 1
	return 0

//Stealth

/obj/item/clothing/suit/armor/reactive/stealth
	name = "reactive stealth armor"
	desc = "An experimental suit of armor that renders the wearer invisible on detection of imminent harm, and creates a decoy that runs away from the owner. You can't fight what you can't see."
	reactivearmor_cooldown_duration = 80

/obj/item/clothing/suit/armor/reactive/stealth/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return 0
	if(!damage)
		return 0
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("The reactive stealth system on [owner] activates, but is still recharging its holographic emitters!"))
			return
		var/mob/living/simple_animal/hostile/illusion/escape/E = new(owner.loc)
		E.Copy_Parent(owner, 50)
		E.GiveTarget(owner) //so it starts running right away
		E.Goto(owner, E.move_to_delay, E.minimum_distance)
		owner.alpha = 0
		owner.visible_message(span_danger("[owner] is hit by [attack_text] in the chest!")) //We pretend to be hit, since blocking it would stop the message otherwise
		spawn(40)
			owner.alpha = initial(owner.alpha)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return 1

//Tesla

/obj/item/clothing/suit/armor/reactive/tesla
	name = "reactive tesla armor"
	desc = "An experimental suit of armor with sensitive detectors hooked up to a huge capacitor grid, with emitters strutting out of it. Zap."
	siemens_coefficient = -1
	reactivearmor_cooldown_duration = 3 SECONDS
	var/tesla_power = 25000
	var/tesla_range = 20
	var/tesla_flags = TESLA_MOB_DAMAGE | TESLA_OBJ_DAMAGE

/obj/item/clothing/suit/armor/reactive/tesla/dropped(mob/user)
	..()
	if(istype(user))
		user.flags_1 &= ~TESLA_IGNORE_1

/obj/item/clothing/suit/armor/reactive/tesla/equipped(mob/user, slot)
	..()
	if(slot_flags & slotdefine2slotbit(slot)) //Was equipped to a valid slot for this item?
		user.flags_1 |= TESLA_IGNORE_1

/obj/item/clothing/suit/armor/reactive/tesla/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return FALSE
	if(!damage)
		return FALSE
	if(owner.stat == DEAD)
		return FALSE
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
			sparks.set_up(1, 1, src)
			sparks.start()
			owner.visible_message(span_danger("The tesla capacitors on [owner]'s reactive tesla armor are still recharging! The armor merely emits some sparks."))
			return
		owner.visible_message(span_danger("[src] blocks [attack_text], sending out arcs of lightning!"))
		tesla_zap(owner, tesla_range, tesla_power, tesla_flags)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return TRUE

//Repulse

/obj/item/clothing/suit/armor/reactive/repulse
	name = "reactive repulse armor"
	desc = "An experimental suit of armor that violently throws back attackers."
	reactivearmor_cooldown_duration = 5 SECONDS
	var/repulse_force = MOVE_FORCE_EXTREMELY_STRONG

/obj/item/clothing/suit/armor/reactive/repulse/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return 0
	if(!damage)
		return 0
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("The repulse generator is still recharging!"))
			return 0
		playsound(get_turf(owner),'sound/magic/repulse.ogg', 100, 1)
		owner.visible_message(span_danger("[src] blocks [attack_text], converting the attack into a wave of force!"))
		var/turf/T = get_turf(owner)
		var/list/thrown_items = list()
		for(var/atom/movable/A in range(T, 7))
			if(A == owner || A.anchored || thrown_items[A])
				continue
			var/throwtarget = get_edge_target_turf(T, get_dir(T, get_step_away(A, T)))
			A.safe_throw_at(throwtarget, 10, 1, force = repulse_force)
			thrown_items[A] = A

		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return 1

/obj/item/clothing/suit/armor/reactive/table
	name = "reactive table armor"
	desc = "If you can't beat the memes, embrace them."
	var/tele_range = 10

/obj/item/clothing/suit/armor/reactive/table/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!active)
		return 0
	if(!damage)
		return 0
	if(prob(hit_reaction_chance))
		var/mob/living/carbon/human/H = owner
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("The reactive table armor's fabricators are still on cooldown!"))
			return
		owner.visible_message(span_danger("The reactive teleport system flings [H] clear of [attack_text] and slams [H.p_them()] into a fabricated table!"))
		owner.visible_message("<font color='red' size='3'>[H] GOES ON THE TABLE!!!</font>")
		owner.Paralyze(40)
		var/list/turfs = new/list()
		for(var/turf/T in orange(tele_range, H))
			if(T.density)
				continue
			if(T.x>world.maxx-tele_range || T.x<tele_range)
				continue
			if(T.y>world.maxy-tele_range || T.y<tele_range)
				continue
			turfs += T
		if(!turfs.len)
			turfs += pick(/turf in orange(tele_range, H))
		var/turf/picked = pick(turfs)
		if(!isturf(picked))
			return
		H.forceMove(picked)
		new /obj/structure/table(get_turf(owner))
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return 1
	return 0

/obj/item/clothing/suit/armor/reactive/table/emp_act()
	return
