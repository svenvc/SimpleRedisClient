"
I am SimpleRedisClient, a minimal client to Redis, a networked, in-memory key-value store with optional durability supporting different kinds of abstract data structures.

https://redis.io
https://en.wikipedia.org/wiki/Redis
https://redis.io/topics/protocol
"
Class {
	#name : #SimpleRedisClient,
	#superclass : #Object,
	#instVars : [
		'host',
		'port',
		'connection',
		'in',
		'out'
	],
	#category : 'SimpleRedisClient'
}

{ #category : #'initialize-release' }
SimpleRedisClient >> close [
	connection
		ifNotNil: [ 
			[ connection close ] on: Error do: [  ].
			in := out := connection := nil ]
]

{ #category : #convenience }
SimpleRedisClient >> execute: commandArgs [
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

{ #category : #reading }
SimpleRedisClient >> readArray [
	| length array |
	length := in nextLine asInteger.
	length = -1 ifTrue: [ ^ nil ].
	array := Array new: length streamContents: [ :elements |
		length timesRepeat: [ elements nextPut: self readReply ] ].
	^ array
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
SimpleRedisClient >> readReply [
	| first |
	first := in next.
	first = $+ ifTrue: [ ^ in nextLine ].
	first = $: ifTrue: [ ^ in nextLine asInteger ].
	first = $- ifTrue: [ ^ self error: in nextLine ].
	first = $* ifTrue: [ ^ self readArray ].
	first = $$ ifTrue: [ ^ self readBulkString ].
	self error: 'Unknown reply type'
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
