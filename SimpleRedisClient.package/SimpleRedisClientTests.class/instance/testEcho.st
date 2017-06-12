testing
testEcho
	| string |
	string := 'STR-' , 99 atRandom asString.
	self assert: (client execute: { #ECHO. string }) equals: string