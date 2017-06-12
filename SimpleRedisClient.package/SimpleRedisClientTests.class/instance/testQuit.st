testing
testQuit
	self assert: (client executeInline: #QUIT) equals: #OK