"
Redis key operations implemented as a trait.
"
Trait {
	#name : #TRedisKeys,
	#traits : 'TRedis',
	#classTraits : 'TRedis classTrait',
	#category : #SimpleRedisClient
}

{ #category : #keys }
TRedisKeys >> anyKey [
	^self execute: { #RANDOMKEY }
]

{ #category : #keys }
TRedisKeys >> at: key [ 
	^self execute: { #GET. key }
]

{ #category : #keys }
TRedisKeys >> at: key append: aValue [
	^self execute: { #APPEND. key. aValue }
]

{ #category : #keys }
TRedisKeys >> at: key bit: pos [ 
	^self execute: { #GETBIT. key. pos }
]

{ #category : #keys }
TRedisKeys >> at: key bit: pos put: bit [
	^self execute: { #SETBIT. key. pos. bit }
]

{ #category : #keys }
TRedisKeys >> at: key bitAndAll: keyOrKeys [
	^self execute: { #BITOP. #AND. key }, (keyOrKeys isArray ifTrue: [keyOrKeys] ifFalse: {keyOrKeys})
]

{ #category : #keys }
TRedisKeys >> at: key bitNot: otherKey [
	^self execute: { #BITOP. #NOT. key. otherKey }
]

{ #category : #keys }
TRedisKeys >> at: key bitOrAll: keyOrKeys [
	^self execute: { #BITOP. #OR. key }, (keyOrKeys isArray ifTrue: [keyOrKeys] ifFalse: {keyOrKeys})
]

{ #category : #keys }
TRedisKeys >> at: key bitXorAll: keyOrKeys [
	^self execute: { #BITOP. #XOR. key }, (keyOrKeys isArray ifTrue: [keyOrKeys] ifFalse: {keyOrKeys})
]

{ #category : #keys }
TRedisKeys >> at: key expireAt: aDateAndTime [
	^(self execute: { #EXPIRE. key. aDateAndTime asUnixTime }) = 1
]

{ #category : #keys }
TRedisKeys >> at: key expireIn: aDuration [
	(aDuration class includesBehavior: Duration) 
		ifTrue: [ 
			aDuration milliseconds > 0 
			ifTrue: [ ^self at: key expireInMilliseconds: aDuration asMilliseconds ]
			ifFalse: [ ^self at: key expireInSeconds: aDuration asSeconds ] ]
		ifFalse: [ self error: 'Expected duration.  Please use pass a Duration or use at:expireInMilliseconds: or at:expireInSeconds:' ]
]

{ #category : #keys }
TRedisKeys >> at: key expireInMilliseconds: millisecs [
	^(self execute: { #PEXPIRE. key. millisecs }) = 1
]

{ #category : #keys }
TRedisKeys >> at: key expireInSeconds: seconds [
	^(self execute: { #EXPIRE. key. seconds }) = 1
]

{ #category : #keys }
TRedisKeys >> at: key from: start put: value [
	^self execute: { #SETRANGE. key. (start > -1 ifTrue: [start-1] ifFalse: [start]). value }
]

{ #category : #keys }
TRedisKeys >> at: key from: start to: end [
	^self execute: { #GETRANGE. key. (start > -1 ifTrue: [start-1] ifFalse: [start]). (end > -1 ifTrue: [end-1] ifFalse: [end]) }
]

{ #category : #keys }
TRedisKeys >> at: key pexpireAt: aDateAndTime [
	| millis |
	millis := ((aDateAndTime offset: Duration zero) - aDateAndTime class unixEpoch) asMilliSeconds.
	^(self execute: { #PEXPIRE. key. millis }) = 1
]

{ #category : #keys }
TRedisKeys >> at: key put: aValue [
	^self execute: { #SET. key. aValue }
]

{ #category : #keys }
TRedisKeys >> at: key put: aValue expireIn: aDuration [
	(aDuration class includesBehavior: Duration) 
		ifTrue: [ 
			aDuration milliseconds > 0 
			ifTrue: [ ^self at: key put: aValue expireInMilliseconds: aDuration asMilliseconds ]
			ifFalse: [ ^self at: key put: aValue expireInSeconds: aDuration asSeconds ] ]
		ifFalse: [ self error: 'Expected duration.  Please use pass a Duration or use at:put:expireInMilliseconds: or at:put:expireInSeconds:' ]
]

{ #category : #keys }
TRedisKeys >> at: key put: aValue expireInMilliseconds: anInteger [
	^self execute: { #PSETEX. key. anInteger. aValue }
]

{ #category : #keys }
TRedisKeys >> at: key put: aValue expireInSeconds: anInteger [
	^self execute: { #SETEX. key. anInteger. aValue }
]

{ #category : #keys }
TRedisKeys >> at: key putIfAbsent: aValue [
	^self execute: { #SETNX. key. aValue }
]

{ #category : #keys }
TRedisKeys >> at: key restore: data [ 
	^self execute: { #RESTORE. key. 0. data. #REPLACE }
]

{ #category : #keys }
TRedisKeys >> at: key restore: data expireAt: aDateAndTime [
	| millis |
	millis := ((aDateAndTime offset: Duration zero) - aDateAndTime class unixEpoch) asMilliSeconds.
	^self execute: { #RESTORE. key. millis. data. #REPLACE. #ABSTTL }
]

{ #category : #keys }
TRedisKeys >> at: key restore: data expireIn: aDuration [
	^self execute: { #RESTORE. key. (aDuration asMilliseconds). data. #REPLACE }
]

{ #category : #keys }
TRedisKeys >> at: key restore: data expireInMilliseconds: milliseconds [
	^self execute: { #RESTORE. key. milliseconds. data. #REPLACE }
]

{ #category : #keys }
TRedisKeys >> at: key restore: data expireInSeconds: seconds [
	^self execute: { #RESTORE. key. (seconds*1000). data. #REPLACE }
]

{ #category : #keys }
TRedisKeys >> at: key swap: aValue [
	^self execute: { #GETSET. key. aValue }
]

{ #category : #keys }
TRedisKeys >> atAll: keys [ 
	^self execute: { #MGET }, keys
]

{ #category : #keys }
TRedisKeys >> atAll: keys putAll: values [
	^self execute: { #MSET }, ((keys with: values collect: [:k :v | {k. v}]) flatCollect: [ :ea | ea ])
]

{ #category : #keys }
TRedisKeys >> atAll: keys putAllIfAbsent: values [
	^self execute: { #MSETNX }, ((keys with: values collect: [:k :v | {k. v}]) flatCollect: [ :ea | ea ])
]

{ #category : #keys }
TRedisKeys >> bitCountAt: key [ 
	^self execute: { #BITCOUNT. key }
]

{ #category : #keys }
TRedisKeys >> decrementAt: key [ 
	^self execute: { #DECR. key }
]

{ #category : #keys }
TRedisKeys >> decrementAt: key by: value [ 
	^self execute: { #DECRBY. key. value }
]

{ #category : #keys }
TRedisKeys >> dumpAt: key [ 
	^self execute: { #DUMP. key }
]

{ #category : #keys }
TRedisKeys >> includesKey: key [ 
	^(self execute: { #EXISTS. key }) = 1
]

{ #category : #keys }
TRedisKeys >> incrementAt: key [ 
	^self execute: { #INCR. key }
]

{ #category : #keys }
TRedisKeys >> incrementAt: key by: value [
	^value isInteger
		ifTrue: [ self execute: { #INCRBY. key. value } ]
		ifFalse: [ self execute: { #INCRBYFLOAT. key. value } ]
]

{ #category : #keys }
TRedisKeys >> keysDo: aOneArgumentBlock [
	^self keysMatching: nil ofType: nil do: aOneArgumentBlock
]

{ #category : #keys }
TRedisKeys >> keysMatching: aPattern do: aOneArgumentBlock [
	^self keysMatching: aPattern ofType: nil do: aOneArgumentBlock
]

{ #category : #keys }
TRedisKeys >> keysMatching: aPattern ofType: aType do: aOneArgumentBlock [
	| command result |
	command := { #SCAN. 0 }, 
	(aPattern 
		ifNotNil: [
			aPattern = '*' 
				ifFalse: [ { #MATCH. aPattern } ] 
				ifTrue: [ { } ] ] 
		ifNil: [ {  } ] ),
	(aType ifNotNil: [ { #TYPE. aType } ] ifNil: [ {  } ] ).
	[	| cursor found |
		result := self execute: command.
		cursor := result first asInteger.
		found := result last.
		command at: 2 put: cursor.
		found do: aOneArgumentBlock.
		cursor = 0 ] whileFalse: [  ]
		
		
	
]

{ #category : #keys }
TRedisKeys >> keysOfType: aType do: aOneArgumentBlock [
	^self keysMatching: nil ofType: aType do: aOneArgumentBlock
]

{ #category : #keys }
TRedisKeys >> lengthAt: key [
	^self execute: { #STRLEN. key }
]

{ #category : #keys }
TRedisKeys >> milliSecondsToLive: key [ 
	^self execute: { #PTTL. key }
]

{ #category : #keys }
TRedisKeys >> moveKey: aKey ifEmptyKey: anotherKey [
	^self execute: { #RENAMENX. aKey. anotherKey }
]

{ #category : #keys }
TRedisKeys >> moveKey: aKey toDB: aDBIndex [
	^self execute: { #MOVE. aKey. aDBIndex }
]

{ #category : #keys }
TRedisKeys >> moveKey: aKey toKey: anotherKey [
	^self execute: { #RENAME. aKey. anotherKey }
]

{ #category : #keys }
TRedisKeys >> persist: key [ 
	^(self execute: { #PERSIST. key }) = 1
]

{ #category : #keys }
TRedisKeys >> removeAt: key [ 
	^self execute: ({ #UNLINK. }, (key isSequenceable ifTrue: [ key ] ifFalse: [ { key } ]))
]

{ #category : #keys }
TRedisKeys >> removeKey: key [ 
	^self execute: ({ #UNLINK. }, (key isSequenceable ifTrue: [ key ] ifFalse: [ { key } ]))
]

{ #category : #keys }
TRedisKeys >> removeNowAt: key [ 
	^self execute: ({ #DEL. }, (key isSequenceable ifTrue: [ key ] ifFalse: [ { key } ]))
]

{ #category : #keys }
TRedisKeys >> secondsToLive: key [ 
	^self execute: { #TTL. key }
]

{ #category : #keys }
TRedisKeys >> touch: aKeyOrCollection [
	^self execute: ({ #TOUCH }, (aKeyOrCollection isSequenceable 
		ifTrue: [ aKeyOrCollection ] 
		ifFalse: [ { aKeyOrCollection } ]))
]

{ #category : #keys }
TRedisKeys >> typeAt: key [ 
	^self execute: { #TYPE. key }
]
