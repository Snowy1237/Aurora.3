
/datum/polloption
	var/optionid
	var/optiontext

/mob/abstract/new_player/proc/handle_player_polling()
	if(establish_db_connection(GLOB.dbcon))
		var/isadmin = 0
		if(src.client && src.client.holder)
			isadmin = 1

		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT id, question FROM ss13_poll_question WHERE [(isadmin ? "" : "adminonly = false AND")] Now() BETWEEN starttime AND endtime")
		select_query.Execute()

		var/output = "<div align='center'><B>Player polls</B>"
		output +="<hr>"

		var/pollid
		var/pollquestion

		output += "<table>"

		while(select_query.NextRow())
			pollid = select_query.item[1]
			pollquestion = select_query.item[2]
			output += "<tr><td><a href=\"byond://?src=[REF(src)];pollid=[pollid]\"><b>[pollquestion]</b></a></td></tr>"

		output += "</table>"

		src << browse(output,"window=playerpolllist;size=500x300")

/mob/abstract/new_player/proc/show_poll_link(var/pollid = -1)
	if(pollid == -1) return
	if(establish_db_connection(GLOB.dbcon))
		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT link FROM ss13_poll_question WHERE id = :pollid:")
		select_query.Execute(list("pollid"=pollid))

		var/link = null
		while(select_query.NextRow())
			link = select_query.item[1]

		if(link && link != "")
			send_link(usr, link)
		else
			LOG_DEBUG("Polling: [usr.ckey] tried to open poll [pollid] with a invalid link: [link]")

/mob/abstract/new_player/proc/poll_player(var/pollid = -1)
	if(pollid == -1) return

	if(establish_db_connection(GLOB.dbcon))
		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT starttime, endtime, question, polltype, multiplechoiceoptions, link FROM ss13_poll_question WHERE id = :pollid:")
		select_query.Execute(list("pollid"=pollid))

		var/pollstarttime = ""
		var/pollendtime = ""
		var/pollquestion = ""
		var/polltype = ""
		var/haslink = 0
		var/found = 0
		var/multiplechoiceoptions = 0

		while(select_query.NextRow())
			pollstarttime = select_query.item[1]
			pollendtime = select_query.item[2]
			pollquestion = select_query.item[3]
			polltype = select_query.item[4]
			if(select_query.item[6] && select_query.item[6] != "")
				haslink = 1
			found = 1
			break

		if(!found)
			to_chat(usr, SPAN_WARNING("Poll question details not found."))
			return

		switch(polltype)
			//Polls that have enumerated options
			if("OPTION")
				var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT optionid FROM ss13_poll_vote WHERE pollid = [pollid] AND ckey = '[usr.ckey]'")
				voted_query.Execute()

				var/voted = 0
				var/votedoptionid = 0
				while(voted_query.NextRow())
					votedoptionid = text2num(voted_query.item[1])
					voted = 1
					break

				var/list/datum/polloption/options = list()

				var/DBQuery/options_query = GLOB.dbcon.NewQuery("SELECT id, text FROM ss13_poll_option WHERE pollid = [pollid]")
				options_query.Execute()
				while(options_query.NextRow())
					var/datum/polloption/PO = new()
					PO.optionid = text2num(options_query.item[1])
					PO.optiontext = options_query.item[2]
					options += PO

				var/output = "<div align='center'><B>Player poll</B>"
				output +="<hr>"
				output += "<b>Question: [pollquestion]</b><br>"
				output += "<font size='2'>Poll runs from <b>[pollstarttime]</b> until <b>[pollendtime]</b></font>"
				if(haslink)
					output += "<br><font size='2'>Additional information <a href='byond://?src=[REF(src)];showpolllink=[pollid]'>is available here</a></font>"
				output += "<p>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<form name='cardcomp' action='?src=[REF(src)]' method='get'>"
					output += "<input type='hidden' name='src' value='[REF(src)]'>"
					output += "<input type='hidden' name='votepollid' value='[pollid]'>"
					output += "<input type='hidden' name='votetype' value='OPTION'>"

				output += "<table><tr><td>"
				for(var/datum/polloption/O in options)
					if(O.optionid && O.optiontext)
						if(voted)
							if(votedoptionid == O.optionid)
								output += "<b>[O.optiontext]</b><br>"
							else
								output += "[O.optiontext]<br>"
						else
							output += "<input type='radio' name='voteoptionid' value='[O.optionid]'> [O.optiontext]<br>"
				output += "</td></tr></table>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<p><input type='submit' value='Vote'>"
					output += "</form>"

				output += "</div>"


				src << browse(output,"window=playerpoll;size=500x250")

			//Polls with a text input
			if("TEXT")
				var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT replytext FROM ss13_poll_textreply WHERE pollid = [pollid] AND ckey = '[usr.ckey]'")
				voted_query.Execute()

				var/voted = 0
				var/vote_text = ""
				while(voted_query.NextRow())
					vote_text = voted_query.item[1]
					voted = 1
					break


				var/output = "<div align='center'><B>Player poll</B>"
				output +="<hr>"
				output += "<b>Question: [pollquestion]</b><br>"
				output += "<font size='2'>Feedback gathering runs from <b>[pollstarttime]</b> until <b>[pollendtime]</b></font>"
				if(haslink)
					output += "<br><font size='2'>Additional information <a href='byond://?src=[REF(src)];showpolllink=[pollid]'>is available here</a></font>"
				output += "<p>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<form name='cardcomp' action='?src=[REF(src)]' method='get'>"
					output += "<input type='hidden' name='src' value='[REF(src)]'>"
					output += "<input type='hidden' name='votepollid' value='[pollid]'>"
					output += "<input type='hidden' name='votetype' value='TEXT'>"

					output += "<font size='2'>Please provide feedback below. You can use any letters of the English alphabet, numbers and the symbols: . , ! ? : ; -</font><br>"
					output += "<textarea name='replytext' cols='50' rows='14'></textarea>"

					output += "<p><input type='submit' value='Submit'>"
					output += "</form>"

					output += "<form name='cardcomp' action='?src=[REF(src)]' method='get'>"
					output += "<input type='hidden' name='src' value='[REF(src)]'>"
					output += "<input type='hidden' name='votepollid' value='[pollid]'>"
					output += "<input type='hidden' name='votetype' value='TEXT'>"
					output += "<input type='hidden' name='replytext' value='ABSTAIN'>"
					output += "<input type='submit' value='Abstain'>"
					output += "</form>"
				else
					output += "[vote_text]"


				src << browse(output,"window=playerpoll;size=500x500")

			//Polls with a text input
			if("NUMVAL")
				var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT o.text, v.rating FROM ss13_poll_option o, ss13_poll_vote v WHERE o.pollid = [pollid] AND v.ckey = '[usr.ckey]' AND o.id = v.optionid")
				voted_query.Execute()

				var/output = "<div align='center'><B>Player poll</B>"
				output +="<hr>"
				output += "<b>Question: [pollquestion]</b><br>"
				output += "<font size='2'>Poll runs from <b>[pollstarttime]</b> until <b>[pollendtime]</b></font>"
				if(haslink)
					output += "<br><font size='2'>Additional information <a href='byond://?src=[REF(src)];showpolllink=[pollid]'>is available here</a></font>"
				output += "<p>"

				var/voted = 0
				while(voted_query.NextRow())
					voted = 1

					var/optiontext = voted_query.item[1]
					var/rating = voted_query.item[2]

					output += "<br><b>[optiontext] - [rating]</b>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<form name='cardcomp' action='?src=[REF(src)]' method='get'>"
					output += "<input type='hidden' name='src' value='[REF(src)]'>"
					output += "<input type='hidden' name='votepollid' value='[pollid]'>"
					output += "<input type='hidden' name='votetype' value='NUMVAL'>"

					var/minid = 999999
					var/maxid = 0

					var/DBQuery/option_query = GLOB.dbcon.NewQuery("SELECT id, text, minval, maxval, descmin, descmid, descmax FROM ss13_poll_option WHERE pollid = [pollid]")
					option_query.Execute()
					while(option_query.NextRow())
						var/optionid = text2num(option_query.item[1])
						var/optiontext = option_query.item[2]
						var/minvalue = text2num(option_query.item[3])
						var/maxvalue = text2num(option_query.item[4])
						var/descmin = option_query.item[5]
						var/descmid = option_query.item[6]
						var/descmax = option_query.item[7]

						if(optionid < minid)
							minid = optionid
						if(optionid > maxid)
							maxid = optionid

						var/midvalue = round( (maxvalue + minvalue) / 2)

						if(isnull(minvalue) || isnull(maxvalue) || (minvalue == maxvalue))
							continue

						output += "<br>[optiontext]: <select name='o[optionid]'>"
						output += "<option value='abstain'>abstain</option>"
						for (var/j = minvalue; j <= maxvalue; j++)
							if(j == minvalue && descmin)
								output += "<option value='[j]'>[j] ([descmin])</option>"
							else if (j == midvalue && descmid)
								output += "<option value='[j]'>[j] ([descmid])</option>"
							else if (j == maxvalue && descmax)
								output += "<option value='[j]'>[j] ([descmax])</option>"
							else
								output += "<option value='[j]'>[j]</option>"

						output += "</select>"

					output += "<input type='hidden' name='minid' value='[minid]'>"
					output += "<input type='hidden' name='maxid' value='[maxid]'>"

					output += "<p><input type='submit' value='Submit'>"
					output += "</form>"


				src << browse(output,"window=playerpoll;size=500x500")

			if("MULTICHOICE")
				var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT optionid FROM ss13_poll_vote WHERE pollid = [pollid] AND ckey = '[usr.ckey]'")
				voted_query.Execute()

				var/list/votedfor = list()
				var/voted = 0
				while(voted_query.NextRow())
					votedfor.Add(text2num(voted_query.item[1]))
					voted = 1

				var/list/datum/polloption/options = list()
				var/maxoptionid = 0
				var/minoptionid = 0

				var/DBQuery/options_query = GLOB.dbcon.NewQuery("SELECT id, text FROM ss13_poll_option WHERE pollid = [pollid]")
				options_query.Execute()
				while(options_query.NextRow())
					var/datum/polloption/PO = new()
					PO.optionid = text2num(options_query.item[1])
					PO.optiontext = options_query.item[2]
					if(PO.optionid > maxoptionid)
						maxoptionid = PO.optionid
					if(PO.optionid < minoptionid || !minoptionid)
						minoptionid = PO.optionid
					options += PO


				if(select_query.item[5])
					multiplechoiceoptions = text2num(select_query.item[5])

				var/output = "<div align='center'><B>Player poll</B>"
				output +="<hr>"
				output += "<b>Question: [pollquestion]</b><br>You can select up to [multiplechoiceoptions] options. If you select more, the first [multiplechoiceoptions] will be saved.<br>"
				output += "<font size='2'>Poll runs from <b>[pollstarttime]</b> until <b>[pollendtime]</b></font>"
				if(haslink)
					output += "<br><font size='2'>Additional information <a href='byond://?src=[REF(src)];showpolllink=[pollid]'>is available here</a></font>"
				output += "<p>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<form name='cardcomp' action='?src=[REF(src)]' method='get'>"
					output += "<input type='hidden' name='src' value='[REF(src)]'>"
					output += "<input type='hidden' name='votepollid' value='[pollid]'>"
					output += "<input type='hidden' name='votetype' value='MULTICHOICE'>"
					output += "<input type='hidden' name='maxoptionid' value='[maxoptionid]'>"
					output += "<input type='hidden' name='minoptionid' value='[minoptionid]'>"

				output += "<table><tr><td>"
				for(var/datum/polloption/O in options)
					if(O.optionid && O.optiontext)
						if(voted)
							if(O.optionid in votedfor)
								output += "<b>[O.optiontext]</b><br>"
							else
								output += "[O.optiontext]<br>"
						else
							output += "<input type='checkbox' name='option_[O.optionid]' value='[O.optionid]'> [O.optiontext]<br>"
				output += "</td></tr></table>"

				if(!voted)	//Only make this a form if we have not voted yet
					output += "<p><input type='submit' value='Vote'>"
					output += "</form>"

				output += "</div>"


				src << browse(output,"window=playerpoll;size=500x250")
		return

/mob/abstract/new_player/proc/vote_on_poll(var/pollid = -1, var/optionid = -1, var/multichoice = 0)
	if(pollid == -1 || optionid == -1)
		return

	if(!isnum(pollid) || !isnum(optionid))
		return
	if(establish_db_connection(GLOB.dbcon))

		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT starttime, endtime, question, polltype, multiplechoiceoptions FROM ss13_poll_question WHERE id = [pollid] AND Now() BETWEEN starttime AND endtime")
		select_query.Execute()

		var/validpoll = 0
		var/multiplechoiceoptions = 0

		while(select_query.NextRow())
			if(select_query.item[4] != "OPTION" && select_query.item[4] != "MULTICHOICE")
				return
			validpoll = 1
			if(select_query.item[5])
				multiplechoiceoptions = text2num(select_query.item[5])
			break

		if(!validpoll)
			to_chat(usr, SPAN_WARNING("Poll is not valid."))
			return

		var/DBQuery/select_query2 = GLOB.dbcon.NewQuery("SELECT id FROM ss13_poll_option WHERE id = [optionid] AND pollid = [pollid]")
		select_query2.Execute()

		var/validoption = 0

		while(select_query2.NextRow())
			validoption = 1
			break

		if(!validoption)
			to_chat(usr, SPAN_WARNING("Poll option is not valid."))
			return

		var/alreadyvoted = 0

		var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT id FROM ss13_poll_vote WHERE pollid = [pollid] AND ckey = '[usr.ckey]'")
		voted_query.Execute()

		while(voted_query.NextRow())
			alreadyvoted += 1
			if(!multichoice)
				break

		if(!multichoice && alreadyvoted)
			to_chat(usr, SPAN_WARNING("You already voted in this poll."))
			return

		if(multichoice && (alreadyvoted >= multiplechoiceoptions))
			to_chat(usr, SPAN_WARNING("You already have more than [multiplechoiceoptions] logged votes on this poll. Enough is enough. Contact the database admin if this is an error."))
			return

		var/adminrank = "Player"
		if(usr && usr.client && usr.client.holder)
			adminrank = usr.client.holder.rank


		var/DBQuery/insert_query = GLOB.dbcon.NewQuery("INSERT INTO ss13_poll_vote (id ,datetime ,pollid ,optionid ,ckey ,ip ,adminrank) VALUES (null, Now(), [pollid], [optionid], '[usr.ckey]', '[usr.client.address]', '[adminrank]')")
		insert_query.Execute()

		to_chat(usr, SPAN_NOTICE("Vote successful."))
		usr << browse(null,"window=playerpoll")


/mob/abstract/new_player/proc/log_text_poll_reply(var/pollid = -1, var/replytext = "")
	if(pollid == -1 || replytext == "")
		return

	if(!isnum(pollid) || !istext(replytext))
		return
	if(establish_db_connection(GLOB.dbcon))

		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT starttime, endtime, question, polltype FROM ss13_poll_question WHERE id = [pollid] AND Now() BETWEEN starttime AND endtime")
		select_query.Execute()

		var/validpoll = 0

		while(select_query.NextRow())
			if(select_query.item[4] != "TEXT")
				return
			validpoll = 1
			break

		if(!validpoll)
			to_chat(usr, SPAN_WARNING("Poll is not valid."))
			return

		var/alreadyvoted = 0

		var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT id FROM ss13_poll_textreply WHERE pollid = [pollid] AND ckey = '[usr.ckey]'")
		voted_query.Execute()

		while(voted_query.NextRow())
			alreadyvoted = 1
			break

		if(alreadyvoted)
			to_chat(usr, SPAN_WARNING("You already sent your feedback for this poll."))
			return

		var/adminrank = "Player"
		if(usr && usr.client && usr.client.holder)
			adminrank = usr.client.holder.rank


		replytext = replacetext(replytext, "%BR%", "")
		replytext = replacetext(replytext, "\n", "%BR%")
		var/text_pass = reject_bad_text(replytext,8000)
		replytext = replacetext(replytext, "%BR%", "<BR>")

		if(!text_pass)
			to_chat(usr, "The text you entered was blank, contained illegal characters or was too long. Please correct the text and submit again.")
			return

		var/DBQuery/insert_query = GLOB.dbcon.NewQuery("INSERT INTO ss13_poll_textreply (id ,datetime ,pollid ,ckey ,ip ,replytext ,adminrank) VALUES (null, Now(), [pollid], '[usr.ckey]', '[usr.client.address]', '[replytext]', '[adminrank]')")
		insert_query.Execute()

		to_chat(usr, SPAN_NOTICE("Feedback logging successful."))
		usr << browse(null,"window=playerpoll")


/mob/abstract/new_player/proc/vote_on_numval_poll(var/pollid = -1, var/optionid = -1, var/rating = null)
	if(pollid == -1 || optionid == -1)
		return

	if(!isnum(pollid) || !isnum(optionid))
		return
	if(establish_db_connection(GLOB.dbcon))

		var/DBQuery/select_query = GLOB.dbcon.NewQuery("SELECT starttime, endtime, question, polltype FROM ss13_poll_question WHERE id = [pollid] AND Now() BETWEEN starttime AND endtime")
		select_query.Execute()

		var/validpoll = 0

		while(select_query.NextRow())
			if(select_query.item[4] != "NUMVAL")
				return
			validpoll = 1
			break

		if(!validpoll)
			to_chat(usr, SPAN_WARNING("Poll is not valid."))
			return

		var/DBQuery/select_query2 = GLOB.dbcon.NewQuery("SELECT id FROM ss13_poll_option WHERE id = [optionid] AND pollid = [pollid]")
		select_query2.Execute()

		var/validoption = 0

		while(select_query2.NextRow())
			validoption = 1
			break

		if(!validoption)
			to_chat(usr, SPAN_WARNING("Poll option is not valid."))
			return

		var/alreadyvoted = 0

		var/DBQuery/voted_query = GLOB.dbcon.NewQuery("SELECT id FROM ss13_poll_vote WHERE optionid = [optionid] AND ckey = '[usr.ckey]'")
		voted_query.Execute()

		while(voted_query.NextRow())
			alreadyvoted = 1
			break

		if(alreadyvoted)
			to_chat(usr, SPAN_WARNING("You already voted in this poll."))
			return

		var/adminrank = "Player"
		if(usr && usr.client && usr.client.holder)
			adminrank = usr.client.holder.rank


		var/DBQuery/insert_query = GLOB.dbcon.NewQuery("INSERT INTO ss13_poll_vote (id ,datetime ,pollid ,optionid ,ckey ,ip ,adminrank, rating) VALUES (null, Now(), [pollid], [optionid], '[usr.ckey]', '[usr.client.address]', '[adminrank]', [(isnull(rating)) ? "null" : rating])")
		insert_query.Execute()

		to_chat(usr, SPAN_NOTICE("Vote successful."))
		usr << browse(null,"window=playerpoll")
