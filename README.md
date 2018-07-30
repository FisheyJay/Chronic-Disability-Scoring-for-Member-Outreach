# Chronic-Disability-Scoring-for-Member-Outreach
Chronic Disability Scoring System for Member Outreach (ICD9 Codes, Age, Time Since Last Visit) - Oracle PL-SQL, Claims Data
  
CDPS:   The Chronic Disability Scoring / Processing System 

	... for Identifying members in need of Member Outreach due to some combination 
	of: age (very old, very young), severity of diagnosis code and length 
	of time since last provider visit / medical care event.

	PK_CDPS_SCORING (Oracle PL-SQL Package Specification, Package Body, Insert Data, 
	Create Tables Synonyms, Grants, etc.)

WHY:	I feel that this is a technical process that positively and meaningfully helps 
	those persons most in need of outreach / medical care. 
			   
	I get no greater sense of accomplishment, pride or satisfaction as a developer 
	than when my code helps people in a real and meaningful way. That said ...

	If another technologist such as myself anywhere in the world can take this code 
	and emulate it and similarly have a positive effect on sick persons not reciving 
	the care they desperately require,... if it helps just one person, 
	then it is wonderful! ... and the time I spent posting this was time very well 
	spent.

PURPOSE:

	This is a Chronic Disability Scoring System that is designed to 
	identify the sickest or most ill members of the health plan for 
	Proactive Outreach purposes. A Senior Business Analyst in an 
	Actuarial Department, business-side (i.e., outside I.T.) had created a 
	process to achieve same results in MS Access which was terribly inefficient, 
	& painfully slow, taking two days to produce the information he required.

	I created this process in it's entirety in the Oracle Data Warehouse 
	for him, having gathered his requirements over many sessions and 
	weeks. I eliminated the onerous ODBC connection he had been connecting 
	to Oracle with and eliminated that network traffic as well.

	To say that his MS Access process was slow does a disservice to slow 
	running processes eveywhere. I mean, this thing was a--w--f--u--l.

	This process combines age, certain ICD9 Illness codes, and the 
	length of time it has been since the member was last seen by a 
	provider.

	Sick & older health plan members having gone 2-3 months, for 
	example, without being seen by the provider type required, would 
	be placed in an Outreach Program.

	The Outreach program began with mailings, and if that failed, a nurse 
	making a phone call and if that failed as well, then a nurse would pay 
	the member a visit at their home to get them the medical attention they 
	desperately need.

ENVIRONMENT & ASSUMPTIONS:

	The Oracle Data Warehouse contains claims data that is automatically 
	and regularly pushed to it from the online claims processing system. This 
	is an ongoing process that runs at least nightly, actually many times per 
	day via automated ETL jobs, etc.

	Obviously there is absolutely no HIPPA related data anwhere in this 
	solution that I am posting. This solution is in the form of an Oracle PL-SQL 
	Package Specification and Package Body which I wrote in it's entirety for a 
	large Health Insurance Provider. I have removed / replaced all names, variable 
	names, server names, user names, table names, etc so as to ensure the data 
	privacy of my former client.
