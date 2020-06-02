"
Redis client operations implemented as a trait.
"
Trait {
	#name : #TRedisClient,
	#traits : 'TRedis',
	#classTraits : 'TRedis classTrait',
	#category : #SimpleRedisClient
}

{ #category : #client }
TRedisClient >> authenticate: aPassword [
	^ self execute: { #AUTH. aPassword }
]

{ #category : #client }
TRedisClient >> authenticatePassword: aPassword [
	^(self execute: { #AUTH. aPassword })
]

{ #category : #client }
TRedisClient >> authenticateUser: aUsername password: aPassword [
	^(self execute: { #AUTH. aUsername. aPassword })
]

{ #category : #client }
TRedisClient >> caching: aBoolean [
	^(self execute: { #CLIENT. #CACHING. (aBoolean ifTrue: ['YES'] ifFalse: ['NO']) })
]

{ #category : #client }
TRedisClient >> clientCaching: aBoolean [
	^(self execute: { #CLIENT. #CACHING. (aBoolean ifTrue: ['YES'] ifFalse: ['NO']) })
]

{ #category : #client }
TRedisClient >> clientID [
	^(self execute: { #CLIENT. #ID })
]

{ #category : #client }
TRedisClient >> clientKillAddress: ipPort [
	^(self execute: { #CLIENT. #KILL. #ADDR. ipPort })
]

{ #category : #client }
TRedisClient >> clientKillType: aType [
	^(self execute: { #CLIENT. #KILL. #TYPE. aType })
]

{ #category : #client }
TRedisClient >> clientKillType: aType skipMe: aBoolean [
	^(self execute: { #CLIENT. #KILL. #TYPE. aType. #SKIPME. (aBoolean ifTrue: [#YES] ifFalse: [#NO]) })
]

{ #category : #client }
TRedisClient >> clientKillUser: aUser [
	^(self execute: { #CLIENT. #KILL. #USER. aUser })
]

{ #category : #client }
TRedisClient >> clientKillUser: aUser skipMe: aBoolean [
	^(self execute: { #CLIENT. #KILL. #USER. aUser. #SKIPME. (aBoolean ifTrue: [#YES] ifFalse: [#NO]) })
]

{ #category : #client }
TRedisClient >> clientKillUser: aUser type: aType [
	^(self execute: { #CLIENT. #KILL. #USER. aUser. #TYPE aType })
]

{ #category : #client }
TRedisClient >> clientKillUser: aUser type: aType skipMe: aBoolean [
	^(self execute: { #CLIENT. #KILL. #USER. aUser. #TYPE. aType. #SKIPME. (aBoolean ifTrue: [#YES] ifFalse: [#NO]) })
]

{ #category : #client }
TRedisClient >> clientListAll [
	^(self parseClientList: (self execute: { #CLIENT. #LIST }))
]

{ #category : #client }
TRedisClient >> clientListMaster [
	^self parseClientList: (self execute: { #CLIENT. #LIST. #TYPE. #master })
]

{ #category : #client }
TRedisClient >> clientListNormal [
	^self parseClientList: (self execute: { #CLIENT. #LIST. #TYPE. #normal })
]

{ #category : #client }
TRedisClient >> clientListPubSub [
	^self parseClientList: (self execute: { #CLIENT. #LIST. #TYPE. #pubsub })
]

{ #category : #client }
TRedisClient >> clientListReplica [
	^self parseClientList: (self execute: { #CLIENT. #LIST. #TYPE. #replica })
]

{ #category : #client }
TRedisClient >> clientName [
	^(self execute: { #CLIENT. #GETNAME })
]

{ #category : #client }
TRedisClient >> clientName: aName [
	^(self execute: { #CLIENT. #SETNAME. aName })
]

{ #category : #client }
TRedisClient >> clientPauseFor: aDuration [
	^(self execute: { #CLIENT. #PAUSE. aDuration asMilliSeconds })
]

{ #category : #client }
TRedisClient >> clientPauseForMilliSeconds: anInteger [
	^(self execute: { #CLIENT. #PAUSE. anInteger })
]

{ #category : #client }
TRedisClient >> clientRedirectID [
	^(self execute: { #CLIENT. #GETREDIR })
]

{ #category : #client }
TRedisClient >> clientReply: onOffOrSkip [
	^(self execute: { #CLIENT. #REPLY. onOffOrSkip })
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean [ 
	^self clientTracking: aBoolean prefix: nil redirectClientID: nil options: nil.
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean options: anArray [
	^self clientTracking: aBoolean prefix: nil redirectClientID: nil options: anArray.
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean prefix: aPrefix [
	^self clientTracking: aBoolean prefix: aPrefix redirectClientID: nil options: nil.
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean prefix: aPrefix redirectClientID: clientID [
	^self clientTracking: aBoolean prefix: aPrefix redirectClientID: clientID options: nil.
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean prefix: aPrefix redirectClientID: clientID options: anArray [
	| switches command |
	"Options is any combination of #BCAST #OPTIN #OPTOUT #NOLOOP"
	switches := { 
		true -> #ON. 
		#ON -> #ON. 
		false -> #OFF. 
		#OFF -> #OFF. 
		#YES -> #ON. 
		#NO -> #OFF } asDictionary.
	command := { #CLIENT. #TRACKING. (switches at: aBoolean) }.
	clientID ifNotNil: [ command := command, { #REDIRECT. clientID } ].
	aPrefix ifNotNil: [ command := command, { #PREFIX. aPrefix } ].
	anArray isSequenceable ifTrue: [ command := command, anArray ].
	^(self execute: command)
]

{ #category : #client }
TRedisClient >> clientTracking: aBoolean redirectClientID: clientID [
	^self clientTracking: aBoolean prefix: nil redirectClientID: clientID options: nil.
]

{ #category : #client }
TRedisClient >> echo: aMessage [
	^self execute: { #ECHO. aMessage }
]

{ #category : #client }
TRedisClient >> hello: protocol [
	^self hello: protocol username: nil password: nil name: nil
]

{ #category : #client }
TRedisClient >> hello: protocol name: aName [
	^self hello: protocol username: nil password: nil name: aName
]

{ #category : #client }
TRedisClient >> hello: protocol username: aUser password: aPassword [
	^self hello: protocol username: aUser password: aPassword name: nil
]

{ #category : #client }
TRedisClient >> hello: protocol username: aUsername password: aPassword name: aName [
	| message |
	message := { #HELLO. protocol }.
	(aUsername notNil and: [ aPassword notNil ])
		ifTrue: [ message := message, { #AUTH. aUsername. aPassword } ].
	aName ifNotNil: [ message := message, { #SETNAME. aName } ].
	^self execute: message
]

{ #category : #client }
TRedisClient >> ping [
	^self execute: { #PING }
]

{ #category : #client }
TRedisClient >> ping: aMessage [
	^self execute: {#PING. aMessage}
]

{ #category : #client }
TRedisClient >> quit [ 
	^self execute: { #QUIT }
]

{ #category : #client }
TRedisClient >> selectDatabase: aDatabaseIndex [
	^self execute: { #SELECT. aDatabaseIndex }
]

{ #category : #client }
TRedisClient >> unblockClient: clientID [
	^(self execute: { #CLIENT. #UNBLOCK. clientID. #TIMEOUT })
]

{ #category : #client }
TRedisClient >> unblockClientWithError: clientID [
	^(self execute: { #CLIENT. #UNBLOCK. clientID. #ERROR })
]
