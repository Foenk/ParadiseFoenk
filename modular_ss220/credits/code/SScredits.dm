#define CREDITS_PLANE 26

SUBSYSTEM_DEF(credits)
	name = "Credits"
	runlevels = RUNLEVEL_POSTGAME
	flags = SS_NO_FIRE
	var/list/end_titles = list()
	var/title_music = ""

	var/credit_roll_speed = 185
	var/credit_spawn_speed = 20
	var/credit_animate_height
	var/credit_ease_duration = 22

/datum/controller/subsystem/credits/Initialize()
	credit_animate_height = 14 * world.icon_size
	title_music = pick(file2list("config/credits/sounds/title_music.txt"))

/datum/controller/subsystem/credits/proc/roll_credits_for_clients(list/clients)
	if(!length(end_titles))
		end_titles = generate_titles()

	for(var/client/client in clients)
		SScredits.roll_credits_for_client(client)

/datum/controller/subsystem/credits/proc/roll_credits_for_client(client/client)
	LAZYINITLIST(client.credits)

	var/list/_credits = client.credits

	var/obj/screen/credit/logo = new /obj/screen/credit/logo(null, "", client)

	addtimer(CALLBACK(src, PROC_REF(roll_credits), _credits, logo, client), 5 SECONDS, TIMER_CLIENT_TIME)

/datum/controller/subsystem/credits/proc/roll_credits(list/credits, obj/screen/credit/logo/logo, client/client)
	credits += logo
	logo.rollem()

	for(var/item in end_titles)
		if(!client?.credits)
			return
		var/obj/screen/credit/title = new(null, item, client)
		credits += title
		title.rollem()
		sleep(credit_spawn_speed)

	addtimer(CALLBACK(src, PROC_REF(clear_credits), client), (credit_roll_speed), TIMER_CLIENT_TIME)
/datum/controller/subsystem/credits/proc/clear_credits(client/client)
	if(!client)
		return
	QDEL_NULL(client.credits)

/datum/controller/subsystem/credits/proc/generate_titles()
	RETURN_TYPE(/list)
	var/list/titles = list()
	var/list/cast = list()
	var/list/chunk = list()
	var/list/streamers = list()
	var/chunksize = 0

	var/episode_title = ""

	switch(rand(1,100))

		if(1 to 10)
			episode_title += pick(file2list("config/credits/titles/finished_titles.txt"))
		if(11 to 30)
			episode_title += "ЭКИПАЖ УЗНАЕТ О " + pick(file2list("config/credits/titles/random_titles_crews_learns.txt"))
		if(31 to 60)
			episode_title += pick(file2list("config/credits/titles/random_titles_neuter_2_1.txt")) + " "
			episode_title += pick(file2list("config/credits/titles/random_titles_neuter_2_2.txt"))
		if(61 to 100)
			episode_title += pick(file2list("config/credits/titles/random_titles_plural_2_1.txt")) + " "
			episode_title += pick(file2list("config/credits/titles/random_titles_plural_2_2.txt"))

	titles += "<center><h1>EPISODE [GLOB.round_id]<br>[episode_title]<h1></h1></h1></center>"

	for(var/mob/living/carbon/human/human in GLOB.alive_mob_list | GLOB.dead_mob_list)
		if(findtext(human.real_name,"(mannequin)"))
			continue
		if(ismonkeybasic(human))
			continue
		if(!human.last_known_ckey)
			continue
		if(human.client?.holder?.rank == "Банда")
			streamers += "<center>[human.real_name]([human.ckey]) в роли [human.job]<br><center>"
			continue
		if(!length(cast) && !chunksize)
			chunk += "В съемках участвовали:"
		chunk += "[human.real_name] в роли [uppertext(human.job)]"
		chunksize++
		if(chunksize > 2)
			cast += "<center>[jointext(chunk,"<br>")]</center>"
			chunk.Cut()
			chunksize = 0
	if(length(chunk))
		cast += "<center>[jointext(chunk,"<br>")]</center>"

	if(length(streamers))
		titles += "<center>Приглашенные звезды:</center><br>"
		titles += streamers

	titles += cast

	var/list/corpses = list()

	for(var/mob/living/carbon/human/human in GLOB.dead_mob_list)
		if(!human.last_known_ckey)
			continue
		else if(human.real_name)
			corpses += human.real_name

	if(length(corpses))
		titles += "<center>Основано на реальных событиях:<br>В память о [english_list(corpses)].</center><br>"

	var/list/staff = list("Съемочная группа:")
	var/list/staffjobs = file2list("config/credits/jobs/staffjobs.txt")
	var/list/goodboys = list()
	for(var/client/client in GLOB.clients)
		if(!client.holder)
			continue

		if(check_rights_client(R_DEBUG|R_ADMIN|R_MOD, FALSE, client))
			staff += "[uppertext(pick(staffjobs))] - '[client.key]'"
		else if(check_rights_client(R_MENTOR, FALSE, client))
			goodboys += "[client.key]"

	titles += "<center>[jointext(staff,"<br>")]</center>"
	if(length(goodboys))
		titles += "<center>Мальчики на побегушках:<br>[english_list(goodboys)]</center><br>"

	var/disclaimer = "<br>Sponsored by WYCCSTATION.<br>All rights reserved.<br>\
					This motion picture is protected under the copyright laws of the Sol Central Government<br> and other nations throughout the galaxy.<br>\
					Colony of First Publication: [pick("Mars", "Luna", "Earth", "Venus", "Phobos", "Ceres", "Tiamat", "Ceti Epsilon", "Eos", "Pluto", "Ouere",\
					"Tadmor", "Brahe", "Pirx", "Iolaus", "Saffar", "Gaia")].<br>"
	disclaimer += pick("Use for parody prohibited. PROHIBITED.",
						"All stunts were performed by underpaid interns. Do NOT try at home.",
						"WYCCSTATION does not endorse behaviour depicted. Attempt at your own risk.",
						"Any unauthorized exhibition, distribution, or copying of this film or any part thereof (including soundtrack)<br>\
						may result in an ERT being called to storm your home and take it back by force.",
						"The story, all names, characters, and incidents portrayed in this production are fictitious. No identification with actual<br>\
						persons (living or deceased), places, buildings, and products is intended or should be inferred.<br>\
						This film is based on a true story and all individuals depicted are based on real people, despite what we just said.",
						"No person or entity associated	with this film received payment or anything of value, or entered into any agreement, in connection<br>\
						with the depiction of tobacco products, despite the copious amounts	of smoking depicted within.<br>\
						(This disclaimer sponsored by Carcinoma - Carcinogens are our Business!(TM)).",
						"No animals were harmed in the making of this motion picture except for those listed previously as dead. Do not try this at home.")
	titles += "<hr>"
	titles += "<center><span style='font-size:6pt;'>[jointext(disclaimer, null)]</span></center>"

	return titles

/obj/screen/credit
	icon_state = "blank"
	mouse_opacity = 0
	alpha = 0
	screen_loc = "CENTER-7,CENTER-7"
	plane = CREDITS_PLANE

	var/matrix/target
	var/client/parent

/obj/screen/credit/Initialize(mapload, credited, client/client)
	. = ..()

	parent = client
	maptext = {"<div style="font:'Small Fonts'">[credited]</div>"}
	maptext_height = world.icon_size * 2
	maptext_width = world.icon_size * 14

/obj/screen/credit/proc/rollem()
	var/matrix/M = matrix(transform)
	M.Translate(0, SScredits.credit_animate_height)
	animate(src, transform = M, time = SScredits.credit_roll_speed)
	target = M
	animate(src, alpha = 255, time = SScredits.credit_ease_duration, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, PROC_REF(delete_credit)), SScredits.credit_roll_speed - SScredits.credit_ease_duration, TIMER_CLIENT_TIME)
	parent.screen += src

/obj/screen/credit/proc/delete_credit()
	if(!QDELETED(src))
		animate(src, alpha = 0, transform = target, time = SScredits.credit_ease_duration)
		sleep(SScredits.credit_ease_duration)
		qdel(src)

/obj/screen/credit/Destroy()
	if(parent)
		parent.screen -= src
		LAZYREMOVE(parent.credits, src)
		parent = null
	return ..()

/obj/screen/credit/logo
	icon = 'modular_ss220/credits/icons/logo.dmi'
	icon_state = "ss220"
	screen_loc = "CENTER - 2,CENTER - 3"
	alpha = 100


/obj/screen/credit/logo/Initialize(mapload, credited, client/client)
	. = ..()
	animate(src, alpha = 220, time = 3 SECONDS)
	parent.screen += src

/obj/screen/credit/logo/rollem()
	var/matrix/M = matrix(transform)
	M.Translate(0, SScredits.credit_animate_height / 2)
	animate(src, transform = M, time = SScredits.credit_roll_speed / 2)
	target = M
	animate(src, alpha = 255, time = SScredits.credit_ease_duration / 2, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, PROC_REF(delete_credit)),(SScredits.credit_roll_speed - SScredits.credit_ease_duration) / 2, TIMER_CLIENT_TIME)


/obj/screen/credit/logo/delete_credit()
	if(!QDELETED(src))
		animate(src, alpha = 0, transform = target, time = SScredits.credit_ease_duration / 2)
		sleep(SScredits.credit_ease_duration / 2)
		qdel(src)

/client/var/list/credits

#undef CREDITS_PLANE