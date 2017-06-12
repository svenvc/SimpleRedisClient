reading
readReply
	| first |
	first := in next.
	first = $+ ifTrue: [ ^ in nextLine ].
	first = $: ifTrue: [ ^ in nextLine asInteger ].
	first = $- ifTrue: [ ^ self error: in nextLine ].
	first = $* ifTrue: [ ^ self readArray ].
	first = $$ ifTrue: [ ^ self readBulkString ].
	self error: 'Unknown reply type'