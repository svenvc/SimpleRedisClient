testing
testStringGetSetSimple
	| string |
	string := 'STR-' , 99 atRandom asString.
	self assert: (client execute: #(DEL foo)) >= 0.
	self assert: (client execute: #(EXISTS foo)) equals: 0.
	self assert: (client execute: #(GET foo)) isNil.
	self assert: (client execute: { #SET. #foo. string }) equals: #OK.
	self assert: (client execute: #(GET foo)) equals: string.
	self assert: (client execute: #(EXISTS foo)) equals: 1.
	self assert: (client execute: #(DEL foo)) > 0.
