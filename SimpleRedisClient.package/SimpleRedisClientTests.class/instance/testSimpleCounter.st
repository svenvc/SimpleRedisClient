testing
testSimpleCounter
	client execute: #(DEL mycounter).
	self assert: (client execute: #(INCR mycounter)) equals: 1.
	self assert: (client execute: #(INCR mycounter)) equals: 2.
	self assert: (client execute: #(GET mycounter)) equals: '2'.
	self assert: (client execute: #(DECR mycounter)) equals: 1.
	self assert: (client execute: #(INCRBY mycounter 10)) equals: 11.
	client execute: #(DEL mycounter).