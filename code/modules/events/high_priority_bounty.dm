/datum/round_event_control/high_priority_bounty
	name = "High Priority Bounty"
	typepath = /datum/round_event/high_priority_bounty
	max_occurrences = 3
	weight = 20
	earliest_start = 10

/datum/round_event
	var/datum/bank_account/account

/datum/round_event/high_priority_bounty/setup()
	for(var/datum/bank_account/B as anything in SSeconomy.bank_accounts)
		if(B.bounties.len > 0)
			account = B
			return

/datum/round_event/high_priority_bounty/announce(fake)
	priority_announce("Central Command has issued a high-priority cargo bounty to [account.account_holder]. Details have been sent to all bounty consoles.", "Nanotrasen Bounty Program")

/datum/round_event/high_priority_bounty/start()
	var/datum/bounty/B = random_bounty()
	if(!B)
		return
	B.mark_high_priority(3)
	account.bounties += B


