reading
readBulkString
	| byteCount bytes |
	byteCount := in nextLine asInteger.
	byteCount = -1 ifTrue: [ ^ nil ].
	bytes := in wrappedStream next: byteCount.
	in nextLine.
	^ in encoder decodeBytes: bytes