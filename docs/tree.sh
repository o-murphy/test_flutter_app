Routes

. Profile # Paging, opens on current selected profile, other pages is other user's profiles, each card has buttons - [select cartridge, select sight]
├── Profile add (on Expanded FAB Add) # displays list of user's rifles (added or created), allows select one or use buttons [create, select from collection] 
│   ├── Create rifle wizard (on create) # step by step wizard, in the end adds to user's collection
│   └── Select rifle from builtin collection (on select from collection) # allows select from collection? on select - adds it to user's library as editable 
├── Cartridge select (on select cartridge in profile card) # displays list of user's cartridges (added or created), allows select one or use buttons [create, select from collection] 
│   ├── Create cartridge wizard (on create) # step by step wizard, in the end adds to user's collection
│   ├── Select cartridge from builtin collection (on select from collection) # allows select from collection? on select - adds it to user's library as editable 
│   └── [This section for the future, for now all this data will be a part of cartridge] Projectile select (on select bullet in profile card) # displays list of user's bullets (added or created), allows select one or use buttons [create, select from collection] 
│       ├── Create projectile wizard (on create) # step by step wizard, in the end adds to user's collection
│       └── Select projectile from builtin collection (on select from collection) # allows select from collection? on select - adds it to user's library as editable 
├── Sight select (on select sight in profile card) # displays list of user's sights (added or created), allows select one or use buttons [create, select from collection] 
│   ├── Create sight wizard (on create) # step by step wizard, in the end adds to user's collection
│   └── Select sight from builtin collection (on select from collection) # allows select from collection? on select - adds it to user's library as editable 
├── Profile edit rifle (on edit rifle in the card)
├── Profile edit cartridge (on edit cartridge in the card)
└── Profile edit sight (on edit sight in the card)

Profile can be selected only if rifle and cartridge bound (if cart was deleted - the profile is can't be used till bullet will be replaced) 
Each screen like Cartridge select or Sight select should allow edit it's user's collection