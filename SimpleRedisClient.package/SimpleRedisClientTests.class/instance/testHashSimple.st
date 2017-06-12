testing
testHashSimple
	client execute: #(DEL myhash).
	self assert: (client execute: #(HGET myhash foo)) isNil.
	self assert: (client execute: #(HSET myhash foo one)) equals: 1.
	self assert: (client execute: #(HGET myhash foo)) equals: #one.
	self assert: (client execute: #(HSET myhash bar two)) equals: 1.
	self assert: (client execute: #(HGET myhash bar)) equals: #two.
	(Dictionary newFromPairs: (client execute: #(HGETALL myhash))) in: [ :dictionary |
		self assert: (dictionary at: #foo) equals: #one.
		self assert: (dictionary at: #bar) equals: #two ].
	client execute: #(DEL myhash).	