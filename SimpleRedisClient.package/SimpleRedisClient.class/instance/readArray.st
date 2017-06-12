reading
readArray
	| length array |
	length := in nextLine asInteger.
	length = -1 ifTrue: [ ^ nil ].
	array := Array new: length streamContents: [ :elements |
		length timesRepeat: [ elements nextPut: self readReply ] ].
	^ array