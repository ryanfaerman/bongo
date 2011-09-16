(function() {
  module.exports = {
    db: {
      host: 'localhost',
      db: 'bongo'
    },
    site: {
      open_registration: true,
      name: "Bongo Podcast Publisher",
      url: "http://localhost:3000",
      copyright: '',
      owner: {
        name: "Ryan Faerman",
        email: "ryan@faerman.net"
      },
      about: require('markdown').parse('## Hello & Welcome\n\nHow do you know she is a witch? And this isn\'t my nose. This is a false one. \n...Are you suggesting that coconuts migrate? Listen.\n\nStrange women lying in ponds distributing swords is no basis for a system of \ngovernment. Supreme executive power derives from a mandate from the masses, \nnot from some farcical aquatic ceremony. Well, what do you want? Camelot!"\n'),
      cover_art: "http://localhost:3000/images/technics.jpg",
      analytics: {
        google: 'U-2344-3'
      }
    },
    feed: {
      explicit: false,
      keywords: ['hello', 'bar'],
      category: "Technology",
      subcategory: "Stuff"
    },
    options: {
      queue: true,
      future_pubdate: true
    }
  };
}).call(this);
