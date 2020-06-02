Trait {
	#name : #TRedisHash,
	#traits : 'TRedis',
	#classTraits : 'TRedis classTrait',
	#category : #SimpleRedisClient
}

{ #category : #adding }
TRedisHash >> add: anAssociation [
	self at: anAssociation key put: anAssociation value
]

{ #category : #adding }
TRedisHash >> addAll: aKeyedCollection [
	aKeyedCollection == self ifFalse: [
		^self execute: (Array streamContents: [ :s |
		s nextPutAll: { #HMSET. self name }. 
		aKeyedCollection keysAndValuesDo: [ :key :value |
		s nextPut: key; nextPut: value ] ] ) ].

]

{ #category : #accessing }
TRedisHash >> asDictionary [
	^self execute: { #HGETALL. self name }
]

{ #category : #accessing }
TRedisHash >> associationAt: key [ 
	"Returns the association for the given key."

	^ self associationAt: key ifAbsent: [self errorKeyNotFound: key]
]

{ #category : #accessing }
TRedisHash >> associationAt: key ifAbsent: anAbsentBlock [
	"Lookup the given key in the receiver. If it is present, answer the
	value of evaluating the first block optionally with the association for the key.
	Otherwise answer the value of the second block."

	^self associationAt: key ifPresent: [ :v | key -> v ] ifAbsent: anAbsentBlock
]

{ #category : #accessing }
TRedisHash >> associationAt: key ifPresent: aPresentBlock [ 
	"Lookup the given key in the receiver. If it is present, answer the
	value of evaluating the first block optionally with the association for the key.
	Otherwise answer nil"

	self at: key ifPresent: [:v | ^ aPresentBlock cull: key -> v ].
	^ nil
]

{ #category : #accessing }
TRedisHash >> associationAt: key ifPresent: aPresentBlock ifAbsent: anAbsentBlock [
	"Lookup the given key in the receiver. If it is present, answer the
	value of evaluating the first block optionally with the association for the key.
	Otherwise answer the value of the second block."

	self at: key ifPresent: [:v | ^ aPresentBlock cull: key -> v ].
	^ anAbsentBlock value
]

{ #category : #accessing }
TRedisHash >> associations [
	"Answer a collection containing the receiver's associations."
	"Suggested by l. Uzonyi"
	
	^(self execute: { #HGETALL. self name }) associations
]

{ #category : #accessing }
TRedisHash >> associationsDo: aBlock [
	^self associations do: aBlock
]

{ #category : #accessing }
TRedisHash >> associationsSelect: aBlock [ 
	"Evaluate aBlock with each of my associations as the argument. Collect
	into a new dictionary, only those associations for which aBlock evaluates
	to true."

	| newCollection |
	newCollection := Dictionary new.
	self associationsDo: 
		[:each | 
		(aBlock value: each) ifTrue: [newCollection add: each]].
	^newCollection
]

{ #category : #accessing }
TRedisHash >> at: key [ 
	"Answer the value associated with the key."

	^ self at: key ifAbsent: [self errorKeyNotFound: key]
]

{ #category : #accessing }
TRedisHash >> at: key ifAbsent: aBlock [
	"Answer the value associated with the key."

	^ (self execute: { #HGET. self name. key }) 
		ifNil: aBlock 
		ifNotNil: [ :v | v ]
]

{ #category : #accessing }
TRedisHash >> at: key ifAbsentPut: aBlock [
	"Return the value at the given key.
	If the key is not included in the receiver store and return the result 
	of evaluating aBlock as the new value."

	^ self at: key ifAbsent: [self at: key put: aBlock value]
]

{ #category : #accessing }
TRedisHash >> at: key ifPresent: aBlock [
	"Answer the value associated with the key."

	^ (self execute: { #HGET. self name. key }) 
		ifNil: [ nil ] 
		ifNotNil: [ :v | aBlock cull: v ]
]

{ #category : #accessing }
TRedisHash >> at: key ifPresent: presentBlock ifAbsent: absentBlock [
	"Answer the value associated with the key."

	^ (self execute: { #HGET. self name. key }) 
		ifNil: absentBlock
		ifNotNil: [ :v | presentBlock cull: v ]
]

{ #category : #accessing }
TRedisHash >> at: key ifPresent: presentBlock ifAbsentPut: aBlock [
	"Return the value at the given key.
	If the key is not included in the receiver store and return the result 
	of evaluating aBlock as the new value."

	^ (self execute: { #HGET. key }) 
		ifNotNil: [:v | presentBlock cull: v ] 
		ifNil: [self at: key put: aBlock value]
]

{ #category : #accessing }
TRedisHash >> at: aKey put: aValue [
	^self execute: { #HSET. self name. aKey. aValue }
]

{ #category : #accessing }
TRedisHash >> at: key putIfAbsent: aValue [
	^self execute: { #HSETNX. self name. key. aValue }
]

{ #category : #accessing }
TRedisHash >> collect: aBlock [ 
	"Evaluate aBlock with each of my values as the argument.  Collect the
	resulting values into a collection that is like me. Answer with the new
	collection."
	| newCollection |
	newCollection := Dictionary new.
	self associationsDo:[:each |
		newCollection at: each key put: (aBlock value: each value).
	].
	^newCollection
]

{ #category : #accessing }
TRedisHash >> decrementAt: key [ 
	^self decrementAt: key by: 1
]

{ #category : #accessing }
TRedisHash >> decrementAt: key by: value [
	^value isInteger
		ifTrue: [ self execute: { #HINCRBY. self name. key. (-1 * value) } ]
		ifFalse: [ self execute: { #HINCRBYFLOAT. self name. key. (-1.0 * value) } ]
]

{ #category : #accessing }
TRedisHash >> difference: aCollection [
	"Answer the set theoretic difference of two collections. This is a specialized version for Dictionaries keeping the keys of the objects. At a slightly higher price of an additional Set to track duplicates."

	| other result duplicates |
	
	other := aCollection asSet.
	duplicates := Set new.
	result := Dictionary new: self size.
	
	self keysAndValuesDo: [ :key :value |
		((other includes: value) not and: [ (duplicates includes: value) not ])
			ifTrue: [ 
				duplicates add: value.
				result at: key put: value]].
	
	^ result
]

{ #category : #accessing }
TRedisHash >> do: aBlock [

	^self valuesDo: aBlock
]

{ #category : #accessing }
TRedisHash >> doWithIndex: aBlock2 [
	"Support Set enumeration with a counter, even though not ordered"
	| index |
	index := 0.
	self do: [:item | aBlock2 value: item value: (index := index+1)]
]

{ #category : #private }
TRedisHash >> errorKeyNotFound: aKey [

	KeyNotFound signalFor: aKey
]

{ #category : #private }
TRedisHash >> errorValueNotFound: value [

	ValueNotFound signalFor: value
]

{ #category : #accessing }
TRedisHash >> expireAt: aDateAndTime [
	^(self execute: { #EXPIRE. self name. aDateAndTime asUnixTime }) = 1
]

{ #category : #accessing }
TRedisHash >> expireIn: aDuration [
	self client at: self name expireIn: aDuration
]

{ #category : #accessing }
TRedisHash >> fillFrom: aCollection with: aBlock [
	"Evaluate aBlock with each of aCollections's elements as the argument.  
	Collect the resulting values into self. Answer self."
	
	^self execute: (Array streamContents: [ :s |
		s nextPutAll: { #HMSET. self name }. 
		aCollection keysAndValuesDo: [ :key :value |
		s nextPut: key; nextPut: (aBlock value: value) ] ] )
]

{ #category : #accessing }
TRedisHash >> includes: anObject [ 
	self do: [:each | anObject = each ifTrue: [^true]].
	^false
]

{ #category : #accessing }
TRedisHash >> includesAssociation: anAssociation [
  ^ (self   
      associationAt: anAssociation key
      ifAbsent: [ ^ false ]) value = anAssociation value
]

{ #category : #accessing }
TRedisHash >> includesKey: aKey [ 
	^self execute: { #HEXISTS. self name. aKey }
]

{ #category : #accessing }
TRedisHash >> incrementAt: key [ 
	^self incrementAt: key by: 1
]

{ #category : #accessing }
TRedisHash >> incrementAt: key by: value [
	^value isInteger
		ifTrue: [ self execute: { #HINCRBY. self name. key. value } ]
		ifFalse: [ self execute: { #HINCRBYFLOAT. self name. key. value } ]
]

{ #category : #accessing }
TRedisHash >> inspectorFields [
	^ self associations
]

{ #category : #accessing }
TRedisHash >> isDictionary [
	^true
]

{ #category : #accessing }
TRedisHash >> keyAtValue: value [ 
	"Answer the key that is the external name for the argument, value. If 
	there is none, signal an error."

	^self keyAtValue: value ifAbsent: [self errorValueNotFound: value]
]

{ #category : #accessing }
TRedisHash >> keyAtValue: value ifAbsent: exceptionBlock [
	"Answer the key that is the external name for the argument, value. If 
	there is none, answer the result of evaluating exceptionBlock.
	: Use =, not ==, so stings like 'this' can be found.  Note that MethodDictionary continues to use == so it will be fast."
 
	self associationsDo: 
		[:association | value = association value ifTrue: [^association key]].
	^exceptionBlock value
]

{ #category : #accessing }
TRedisHash >> keys [
	^self execute: { #HKEYS. self name }
]

{ #category : #accessing }
TRedisHash >> keysAndValuesDo: aBlock [
	^self associationsDo:[:assoc|
		aBlock value: assoc key value: assoc value].
]

{ #category : #accessing }
TRedisHash >> keysDo: aOneArgumentBlock [
	^self keys do: aOneArgumentBlock 
]

{ #category : #accessing }
TRedisHash >> keysSortedSafely [
	"Answer an Array containing the receiver's keys."
 	"Suggested by l. Uzonyi"
	
 	| sortedKeys |
 	sortedKeys := self keys.
 	sortedKeys sort: [ :x :y |
 		"Should really be use <obj, string, num> compareSafely..."
 		((x isString and: [ y isString ])
 			or: [ x isNumber and: [ y isNumber ] ])
 			ifTrue: [ x < y ]
 			ifFalse: [ x class == y class
 				ifTrue: [ x printString < y printString ]
 				ifFalse: [ x class name < y class name ] ] ].
 	^sortedKeys
]

{ #category : #accessing }
TRedisHash >> lengthAt: key [
	^self execute: { #HSTRLEN. self name. key }
]

{ #category : #accessing }
TRedisHash >> name [
	^ self explicitRequirement
]

{ #category : #accessing }
TRedisHash >> persist [
	^self client persist: self name
]

{ #category : #accessing }
TRedisHash >> reject: aBlock [ 
	"Evaluate aBlock with each of the receiver's elements as the argument. Collect into a new collection like the receiver only those elements for which aBlock evaluates to false. Answer the new collection."
	"#(1 2 3 4 5) reject: #even >>>  #(1 3 5)"

	^ self select: [ :element | (aBlock value: element) == false ]
]

{ #category : #accessing }
TRedisHash >> remove [ 
	^self client removeAt: self name
]

{ #category : #accessing }
TRedisHash >> removeAll [ 
	^self execute: { #DEL. self name }
]

{ #category : #accessing }
TRedisHash >> removeAll: anArray [ 
	"Remove key from the receiver.
	If key is not in the receiver, notify an error."

	^ self execute: ({ #HDEL. self name }, anArray)
]

{ #category : #accessing }
TRedisHash >> removeAt: key [ 
	"Remove key from the receiver.
	If key is not in the receiver, notify an error."

	^ self removeKey: key ifAbsent: [self errorKeyNotFound: key]
]

{ #category : #accessing }
TRedisHash >> removeKey: key [ 
	"Remove key from the receiver.
	If key is not in the receiver, notify an error."

	^ self removeKey: key ifAbsent: [self errorKeyNotFound: key]
]

{ #category : #accessing }
TRedisHash >> removeKey: key ifAbsent: aBlock [
	"Remove key from the receiver.
	If key is not in the receiver, notify an error."

	^ (self execute: { #HDEL. self name. key }) = 0 ifTrue: [self errorKeyNotFound: key]
]

{ #category : #accessing }
TRedisHash >> removeKeys: anArray [ 
	"Remove key from the receiver.
	If key is not in the receiver, notify an error."

	^ self execute: ({ #HDEL. self name }, anArray)
]

{ #category : #accessing }
TRedisHash >> secondsToLive [
	^self client secondsToLive: self name
]

{ #category : #accessing }
TRedisHash >> select: aBlock [ 
	"Evaluate aBlock with each of my values as the argument. Collect into a new dictionary, only those associations for which aBlock evaluates to true."

	| newCollection |
	newCollection := Dictionary new.
	self associationsDo: [ :each |
		(aBlock value: each value) ifTrue: [
			newCollection add: each copy ] ].
	^newCollection
]

{ #category : #accessing }
TRedisHash >> size [ 
	^self execute: { #HLEN. self name. }
]

{ #category : #accessing }
TRedisHash >> storeOn: aStream [
	| noneYet |
	aStream nextPutAll: '(('.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' new)'.
	noneYet := true.
	self associationsDo: 
			[:each | 
			noneYet
				ifTrue: [noneYet := false]
				ifFalse: [aStream nextPut: $;].
			aStream nextPutAll: ' add: '.
			aStream store: each].
	noneYet ifFalse: [aStream nextPutAll: '; yourself'].
	aStream nextPut: $)
]

{ #category : #accessing }
TRedisHash >> touch [
	^self client touch: self name
]

{ #category : #accessing }
TRedisHash >> type [ 
	^self client typeAt: self name
]

{ #category : #accessing }
TRedisHash >> values [
	^self execute: { #HVALS. self name }
]

{ #category : #accessing }
TRedisHash >> valuesDo: aOneArgumentBlock [
	^self values do: aOneArgumentBlock
]
