"
I am SimpleRedisClient, a minimal client to Redis, a networked, in-memory key-value store with optional durability supporting different kinds of abstract data structures.

Example

  SimpleRedisClient new in: [ :client |
    [ client open; execute: { #ECHO. 'This is Pharo' } ] ensure: [ client close ] ].

About Redis

 https://redis.io
 https://en.wikipedia.org/wiki/Redis
 https://redis.io/topics/protocol

Source code repository

 https://github.com/svenvc/SimpleRedisClient

Article

 https://medium.com/concerning-pharo/quick-write-me-a-redis-client-5fbe4ddfb13d

"
Class {
	#name : #SimpleRedisClient,
	#superclass : #Object,
	#traits : 'TRedisClient + TRedisKeys',
	#classTraits : 'TRedisClient classTrait + TRedisKeys classTrait',
	#instVars : [
		'host',
		'port',
		'connection',
		'in',
		'out',
		'handlers',
		'attributes'
	],
	#category : #SimpleRedisClient
}

{ #category : #accessing }
SimpleRedisClient >> attributes [
]

{ #category : #'initialize-release' }
SimpleRedisClient >> close [
	connection
		ifNotNil: [ 
			[ connection close ] on: Error do: [ #ignore ].
			in := out := connection := nil ]
]

{ #category : #keys }
SimpleRedisClient >> dictionaryAt: aKey [ 
	^RedisDictionary new client: self; name: aKey.
]

{ #category : #convenience }
SimpleRedisClient >> execute: commandArgs [
	attributes := nil.
	self writeCommand: commandArgs.
	^ self readReply 
]

{ #category : #convenience }
SimpleRedisClient >> executeInline: command [
	self writeInlineCommand: command.
	^ self readReply 
]

{ #category : #accessing }
SimpleRedisClient >> host [
	^ host ifNil: [ host := 'localhost' ]
]

{ #category : #accessing }
SimpleRedisClient >> host: string [
	host := string
]

{ #category : #'initialize-release' }
SimpleRedisClient >> initialize [ 
	super initialize.
	handlers := { 
	"RESP2"
		$+ -> [ in nextLine ].
		$: -> [ in nextLine asInteger ].
		$- -> [ self error: in nextLine ].
		$* -> [ self readArray ].
		$$ -> [ self readBulkString ].
	"RESP3"
		$_ -> [ in nextLine. nil ].
		$, -> [ self readFloat ].
		$# -> [ in nextLine = 't' ].
		$! -> [ self error: self readBulkString ].
		$= -> [ self readVerbatimString ].
		$( -> [ in nextLine asNumber ].
		$~ -> [ self readSet ].
		$% -> [ self readDictionary ].
		$| -> [ self readAttribute ].
		$> -> [ self readPushNotification ].
	 } asDictionary
]

{ #category : #keys }
SimpleRedisClient >> listAt: aKey [ 
	^RedisList new client: self; name: aKey.
]

{ #category : #'initialize-release' }
SimpleRedisClient >> open [
	self close.
	connection := ZdcSocketStream openConnectionToHostNamed: self host port: self port.
	in := ZnCharacterReadStream on: connection.
	out := ZnCharacterWriteStream on: connection
]

{ #category : #accessing }
SimpleRedisClient >> port [
	^ port ifNil: [ port := 6379 ]
]

{ #category : #accessing }
SimpleRedisClient >> port: integer [
	port := integer
]

{ #category : #accessing }
SimpleRedisClient >> postPushNotification: notification [ 
	Transcript show: notification printString; cr.
]

{ #category : #reading }
SimpleRedisClient >> readArray [
	| length array |
	length := in nextLine.
	length = '?' ifTrue: [ ^self readStreamedArray ] ifFalse: [ length := length asInteger ].
	length = -1 ifTrue: [ ^ nil ].
	array := Array new: length streamContents: [ :elements |
		length timesRepeat: [ elements nextPut: self readReply ] ].
	^ array
]

{ #category : #reading }
SimpleRedisClient >> readAttribute [
	| attr |
	attr := self readDictionary.
	self reportAttribute: attr.
	^self readReply
]

{ #category : #reading }
SimpleRedisClient >> readBulkString [
	| byteCount bytes |
	byteCount := in nextLine asInteger.
	byteCount = -1 ifTrue: [ ^ nil ].
	bytes := in wrappedStream next: byteCount.
	in nextLine.
	^ in encoder decodeBytes: bytes
]

{ #category : #reading }
SimpleRedisClient >> readDictionary [
	| length array |
	length := in nextLine.
	length = '?' ifTrue: [ self readStreamedDictionary ] ifFalse: [ length := length asInteger ].
	length = -1 ifTrue: [ ^ nil ].
	array := Array streamContents: [ :elements |
		length timesRepeat: [ | key value | 
			key := self readReply.
			value := self readReply.
			elements nextPut: (key -> value) ] ].
	^ array asDictionary
]

{ #category : #reading }
SimpleRedisClient >> readFloat [
	| value |
	value := in nextLine.
	value = 'inf' ifTrue: [ ^Float infinity ].
	value = '-inf' ifTrue: [ ^Float negativeInfinity ].
	^value asNumber.
]

{ #category : #reading }
SimpleRedisClient >> readPushNotification [
	| notification |
	notification := self readArray.
	self postPushNotification: notification.
	^self readReply
]

{ #category : #reading }
SimpleRedisClient >> readReply [
	| first |
	first := in next.
	^(handlers at: first ifAbsent: [ self error: 'Unknown reply type' ]) value.
]

{ #category : #reading }
SimpleRedisClient >> readSet [
	^ self readArray asSet
]

{ #category : #reading }
SimpleRedisClient >> readStreamedArray [
	^Array streamContents: [ :s |
		[in peek = $.] whileFalse: [ s nextPut: self readReply ].
		in nextLine ]
]

{ #category : #reading }
SimpleRedisClient >> readStreamedDictionary [
	^Array streamContents: [ :s || key value |
		[ in peek = $. ] whileFalse: [ 
		key := self readReply.
		value := self readReply.
		s nextPut: (key -> value).
		 ].
		in nextLine.
		 ] asDictionary
]

{ #category : #reading }
SimpleRedisClient >> readStreamedString [
	
	^String streamContents: [ :s || length |
		in next = $; ifFalse: [ self error: 'Error reading streamed string.  Expected semicolon.' ].
		[(length := in nextLine asInteger) > 0] whileTrue: [
			(in next: length into: s).
			in nextLine
		]
	]
]

{ #category : #reading }
SimpleRedisClient >> readVerbatimString [
	| byteCount prefix bytes |
	byteCount := in nextLine asInteger.
	prefix := in upTo: $:.
	bytes := in wrappedStream next: byteCount.
	in nextLine.
	"Valid prefixes are txt and mkd - we will assume just text for now"
	"but mkd should perhaps make use of Pillar"
	^ in encoder decodeBytes: bytes
]

{ #category : #accessing }
SimpleRedisClient >> reportAttribute: anObject [
	attributes := Array streamContents: [ :s | 
		attributes ifNotNil: [ s nextPutAll: attributes ]. 
		s nextPut: anObject
		]
]

{ #category : #writing }
SimpleRedisClient >> writeCommand: args [
	out nextPut: $*; print: args size; crlf.
	args do: [ :each |
		| string byteCount |
		string := each asString.
		byteCount := out encoder encodedByteCountForString: string.
		out 
			nextPut: $$; print: byteCount; crlf; 
			nextPutAll: string; crlf ].
	out flush
]

{ #category : #writing }
SimpleRedisClient >> writeInlineCommand: string [
	out nextPutAll: string; crlf; flush
]
