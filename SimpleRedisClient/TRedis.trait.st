Trait {
	#name : #TRedis,
	#category : #SimpleRedisClient
}

{ #category : #running }
TRedis >> execute: commandArgs [
	^ self explicitRequirement
]

{ #category : #parsing }
TRedis >> parseClientList: aString [
	^(self parseList: aString) collect: [ :ea | self parseDictionary: ea ]
]

{ #category : #parsing }
TRedis >> parseDictionary: aString [
	^(aString substrings collect: [ :ea || pair key value |
		pair := ea substrings: '='. 
		key := pair first.
		value := pair last.
		(value allSatisfy: [ :ch | ch isDigit or: [ ch = $- or: [ ch = $. ] ] ])
			ifTrue: [ value := value asNumber ].
		key -> value ]) asDictionary
]

{ #category : #parsing }
TRedis >> parseList: aString [
	^aString lines
]
