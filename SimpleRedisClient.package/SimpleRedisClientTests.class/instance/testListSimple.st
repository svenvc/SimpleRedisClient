testing
testListSimple
	client execute: #(DEL mylist).
	self assert: (client execute: #(LPUSH mylist one)) equals: 1.
	self assert: (client execute: #(LPUSH mylist two three)) equals: 3.
	self assert: (client execute: #(LPOP mylist)) equals: #three.
	self assert: (client execute: #(LINDEX mylist 0)) equals: #two.
	self assert: (client execute: #(LLEN mylist)) equals: 2.
	client execute: #(DEL mylist).
	