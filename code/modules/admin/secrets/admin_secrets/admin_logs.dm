/datum/admin_secret_item/admin_secret/admin_logs
	name = "Admin Logs"

/datum/admin_secret_item/admin_secret/admin_logs/execute(mob/user)
	. = ..()
	if(!.)
		return
	var/dat = "<B>Admin Log<HR></B>"
	for( var/l in GLOB.admin_log)
		dat += "<li>[l]</li>"
	if(!GLOB.admin_log.len)
		dat += "No-one has done anything this round!"
	user << browse(dat, "window=admin_log")
