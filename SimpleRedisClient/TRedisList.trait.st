Trait {
	#name : #TRedisList,
	#traits : 'TRedis',
	#classTraits : 'TRedis classTrait',
	#category : #SimpleRedisClient
}

{ #category : #adding }
TRedisList >> add: newObject [

	^self addLast: newObject
]

{ #category : #adding }
TRedisList >> add: newObject after: oldObject [ 
	"Add the argument, newObject, as an element of the receiver. Put it in 
	the sequence just succeeding oldObject. Answer newObject."
	^self execute: { #LINSERT. self name. #AFTER. oldObject. newObject }
]

{ #category : #adding }
TRedisList >> add: newObject before: oldObject [ 
	"Add the argument, newObject, as an element of the receiver. Put it in 
	the sequence just succeeding oldObject. Answer newObject."
	^self execute: { #LINSERT. self name. #BEFORE. oldObject. newObject }
]

{ #category : #adding }
TRedisList >> addAll: aCollection [ 
	"Add each element of aCollection at my end. Answer	aCollection."

	^ self addAllLast: aCollection
]

{ #category : #adding }
TRedisList >> addAllFirst: anOrderedCollection [ 
	"Add each element of anOrderedCollection at the beginning of the 
	receiver. Answer anOrderedCollection."

	^self execute: ({ #LPUSH. self name. }, anOrderedCollection)
]

{ #category : #adding }
TRedisList >> addAllLast: newObject [ 
	"Add newObject to the end of the receiver. Answer newObject."

	^self addLast: newObject
	
]

{ #category : #adding }
TRedisList >> addFirst: newObject [ 
	"Add newObject to the beginning of the receiver. Answer newObject."

	^self execute: ({ #LPUSH. self name. }, (newObject isSequenceable 
		ifTrue: [newObject] ifFalse: [ { newObject } ]))
	
]

{ #category : #adding }
TRedisList >> addLast: newObject [ 
	"Add newObject to the beginning of the receiver. Answer newObject."

	^self execute: ({ #RPUSH. self name. }, (newObject isSequenceable 
		ifTrue: [newObject] ifFalse: [ { newObject } ]))
	
]

{ #category : #accessing }
TRedisList >> at: anInteger [
	"Answer my element at index anInteger. at: is used by a knowledgeable
	client to access an existing element"

	^(self execute: { #LINDEX. self name. anInteger-1 }) 
]

{ #category : #accessing }
TRedisList >> name [
	^ self explicitRequirement
]
