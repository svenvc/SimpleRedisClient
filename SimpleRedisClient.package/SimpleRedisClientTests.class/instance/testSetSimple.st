testing
testSetSimple
	client execute: #(DEL myset).
	self assert: (client execute: #(SADD myset one)) equals: 1.
	self assert: (client execute: #(SISMEMBER myset one)) equals: 1.
	self assert: (client execute: #(SADD myset one)) equals: 0.
	self assert: (client execute: #(SADD myset two)) equals: 1.
	self assert: (client execute: #(SADD myset three)) equals: 1.
	self assert: (client execute: #(SCARD myset)) equals: 3.
	self assert: (client execute: #(SMEMBERS myset)) asSet equals: #(one two three) asSet.
	client execute: #(DEL myset).	