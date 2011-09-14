module.exports =
	db:
		host: 'localhost'
		db: 'bongo'
	site:
		name: "Bongo Podcast Publisher"
		url: "http://localhost:3000"
		copyright: ''
		owner: 
			name: "Ryan Faerman"
			email: "ryan@faerman.net"
		about: require('markdown').parse '''
			## Hello & Welcome
			
			How do you know she is a witch? And this isn't my nose. This is a false one. 
			...Are you suggesting that coconuts migrate? Listen.
			
			Strange women lying in ponds distributing swords is no basis for a system of 
			government. Supreme executive power derives from a mandate from the masses, 
			not from some farcical aquatic ceremony. Well, what do you want? Camelot!"
			
			'''
		cover_art: "http://localhost:3000/images/technics.jpg"
		analytics:
			google: 'U-2344-3'	
	feed:
		explicit: no
		keywords: ['hello', 'bar']
		category: "Technology"
		subcategory: "Stuff"
	options:
		queue: yes
		future_pubdate: yes
		