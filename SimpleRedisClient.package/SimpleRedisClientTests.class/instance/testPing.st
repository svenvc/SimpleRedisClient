testing
testPing
	self assert: (client executeInline: #PING) equals: #PONG