Class {
	#name : #RedisList,
	#superclass : #SequenceableCollection,
	#traits : 'TRedisList',
	#classTraits : 'TRedisList classTrait',
	#instVars : [
		'client',
		'name'
	],
	#category : #SimpleRedisClient
}

{ #category : #private }
RedisList class >> arrayType [
	^ Array
]

{ #category : #cleanup }
RedisList class >> cleanUp: aggressive [
	"Rehash all instances when cleaning aggressively"

	aggressive ifTrue: [self compactAll].
]

{ #category : #cleanup }
RedisList class >> compactAll [
	"OrderedCollection compactAll"	
		
	self allSubclassesDo: #compactAllInstances
]

{ #category : #cleanup }
RedisList class >> compactAllInstances [
	self allInstances do: #compact
]

{ #category : #'instance creation' }
RedisList class >> new [
	^ self new: 10
]

{ #category : #'instance creation' }
RedisList class >> new: anInteger [ 
	^ self basicNew setCollection: (self arrayType new: anInteger)
]

{ #category : #'stream creation' }
RedisList class >> new: size streamContents: aBlock [
	^ self withAll: (super new: size streamContents: aBlock)
]

{ #category : #'instance creation' }
RedisList class >> new: anInteger withAll: anObject [
	^ self basicNew setContents: (self arrayType new: anInteger withAll: anObject)
]

{ #category : #'instance creation' }
RedisList class >> newFrom: aCollection [ 
	"Answer an instance of me containing the same elements as aCollection."

	| newCollection |
	newCollection := self new: aCollection size.
	newCollection addAll: aCollection.
	^newCollection

"	OrderedCollection newFrom: {1. 2. 3}
	{1. 2. 3} as: OrderedCollection
	{4. 2. 7} as: SortedCollection
"
]

{ #category : #'instance creation' }
RedisList class >> ofSize: n [
	"Create a new collection of size n with nil as its elements.
	This method exists because OrderedCollection new: n creates an
	empty collection,  not one of size n."
	| collection |
	collection := self new: n.
	collection setContents: (collection collector).
	^ collection

]

{ #category : #accessing }
RedisList class >> streamSpecies [
	^ Array
]

{ #category : #adding }
RedisList >> add: newObject afterIndex: index [ 
	"Add the argument, newObject, as an element of the receiver. Put it in 
	the sequence just after index. Answer newObject."
	(index between: 0 and: self size) ifFalse:[^self errorSubscriptBounds: index].
	self insert: newObject before: firstIndex + index.
	^ newObject
]

{ #category : #adding }
RedisList >> add: newObject beforeIndex: index [ 
	"Add the argument, newObject, as an element of the receiver. Put it in 
	the sequence just before index. Answer newObject."
	(index between: 1 and: self size+1) ifFalse:[^self errorSubscriptBounds: index].
	self insert: newObject before: firstIndex + index - 1.
	^ newObject
]

{ #category : #adding }
RedisList >> addAllFirstUnlessAlreadyPresent: anOrderedCollection [ 
	"Add each element of anOrderedCollection at the beginning of the receiver, preserving the order, but do not add any items that are already in the receiver.  Answer anOrderedCollection."

	anOrderedCollection reverseDo:
		[:each | (self includes: each) ifFalse: [self addFirst: each]].
	^ anOrderedCollection
]

{ #category : #adding }
RedisList >> addAllLast: aCollection [ 
	"Add each element of aCollection at the end of the receiver. 
	Answer aCollection."

	aCollection do: [:each | self addLast: each].
	^aCollection
]

{ #category : #adding }
RedisList >> addFirst: newObject [ 
	"Add newObject to the beginning of the receiver. Answer newObject."

	^self execute: ({ #LPUSH. self name. }, (newObject isSequenceable 
		ifTrue: [newObject] ifFalse: [ { newObject } ]))
	
]

{ #category : #adding }
RedisList >> addLast: newObject [ 
	"Add newObject to the beginning of the receiver. Answer newObject."

	^self execute: ({ #RPUSH. self name. }, (newObject isSequenceable 
		ifTrue: [newObject] ifFalse: [ { newObject } ]))
	
]

{ #category : #converting }
RedisList >> asArray [
	^ (Array new: self size) replaceFrom: 1 to: self size with: array startingAt: firstIndex.
]

{ #category : #converting }
RedisList >> asOrderedCollection [ 

	self species == OrderedCollection ifTrue: [ ^self ].
	^super asOrderedCollection 
]

{ #category : #adding }
RedisList >> at: index ifAbsentPut: block [
	"Return value at index, however, if value does not exist (nil or out of bounds) then add block's value at index (growing self if necessary)"

	| v |
	index <= self size ifTrue: [
		^ (v := self at: index)
			ifNotNil: [v]
			ifNil: [self at: index put: block value]
	].
	[self size < index] whileTrue: [self add: nil].
	^ self at: index put: block value
]

{ #category : #accessing }
RedisList >> at: anInteger put: anObject [
	"Put anObject at element index anInteger. at:put: cannot be used to
	append, front or back, to an ordered collection; it is used by a
	knowledgeable client to replace an element."

	| index |
	anInteger < 1
		ifTrue: [ self errorSubscriptBounds: anInteger ].
	(index := anInteger + firstIndex - 1) > lastIndex
		ifTrue: [ self errorSubscriptBounds: anInteger ].
	^ array at: index put: anObject
]

{ #category : #accessing }
RedisList >> capacity [
	"Answer the current capacity of the receiver."

	^ array size
]

{ #category : #accessing }
RedisList >> client [
	^ client
]

{ #category : #accessing }
RedisList >> client: anObject [
	client := anObject
]

{ #category : #enumerating }
RedisList >> collect: aBlock [ 
	"Evaluate aBlock with each of my elements as the argument. Collect the 
	resulting values into a collection that is like me. Answer the new 
	collection. Override superclass in order to use addLast:, not at:put:."

	| newCollection |
	newCollection := self species new: self size.
	firstIndex to: lastIndex do:
		[:index |
		newCollection addLast: (aBlock value: (array at: index))].
	^ newCollection
]

{ #category : #enumerating }
RedisList >> collect: aBlock from: fromIndex to: toIndex [
	"Override superclass in order to use addLast:, not at:put:."
	| result |
	self ensureBoundsFrom: fromIndex to: toIndex.
	result := self species new: toIndex - fromIndex + 1.
	firstIndex + fromIndex - 1 to: firstIndex + toIndex - 1 do:
		[:index | result addLast: (aBlock value: (array at: index))].
	^ result

]

{ #category : #enumerating }
RedisList >> collect: collectBlock thenSelect: selectBlock [
    "Optimized version Collection>>#collect:thenSelect:"

    | newCollection newElement |

    newCollection := self copyEmpty.
    firstIndex to: lastIndex do: [ :index | 
		newElement := collectBlock value: (array at: index).
		(selectBlock value: newElement) 
			ifTrue: [ newCollection addLast: newElement ]].
    ^ newCollection
]

{ #category : #private }
RedisList >> collector [  "Private"
	^ array
]

{ #category : #private }
RedisList >> compact [
	"remove all empty slots to the end of array, while keeping the empty slots at the front."

    | newArray |
    newArray := self class arrayType new: lastIndex.
    newArray 
        replaceFrom: firstIndex
        to: lastIndex
        with: array
        startingAt: firstIndex.
    array := newArray
]

{ #category : #copying }
RedisList >> copyEmpty [
	"Answer a copy of the receiver that contains no elements."

	^self species new
]

{ #category : #copying }
RedisList >> copyFrom: startIndex to: endIndex [ 
	"Answer a copy of the receiver that contains elements from position
	startIndex to endIndex."

	^self shallowCopy postCopyFrom: startIndex to: endIndex
]

{ #category : #copying }
RedisList >> copyReplaceFrom: start to: stop with: replacementCollection [ 
	"Answer a copy of the receiver with replacementCollection's elements in
	place of the receiver's start'th to stop'th elements. This does not expect
	a 1-1 map from replacementCollection to the start to stop elements, so it
	will do an insert or append."

	| newOrderedCollection delta startIndex stopIndex |
	"if start is less than 1, ignore stop and assume this is inserting at the front. 
	if start greater than self size, ignore stop and assume this is appending. 
	otherwise, it is replacing part of me and start and stop have to be within my 
	bounds. "
	delta := 0.
	startIndex := start.
	stopIndex := stop.
	start < 1
		ifTrue: [startIndex := stopIndex := 0]
		ifFalse: [startIndex > self size
				ifTrue: [startIndex := stopIndex := self size + 1]
				ifFalse: 
					[(stopIndex < (startIndex - 1) or: [stopIndex > self size])
						ifTrue: [self errorOutOfBounds].
					delta := stopIndex - startIndex + 1]].
	newOrderedCollection := 
		self species new: self size + replacementCollection size - delta.
	1 to: startIndex - 1 do: [:index | newOrderedCollection add: (self at: index)].
	1 to: replacementCollection size do: 
		[:index | newOrderedCollection add: (replacementCollection at: index)].
	stopIndex + 1 to: self size do: [:index | newOrderedCollection add: (self at: index)].
	^newOrderedCollection
]

{ #category : #copying }
RedisList >> copyWith: newElement [ 
	"Answer a copy of the receiver that is 1 bigger than the receiver and 
	includes the argument, newElement, at the end."

	| newCollection |
	newCollection := self copy.
	newCollection add: newElement.
	^newCollection
]

{ #category : #enumerating }
RedisList >> do: aBlock [
	"Override the superclass for performance reasons."

	firstIndex to: lastIndex do: [ :index | 
		aBlock value: (array at: index) ]
]

{ #category : #private }
RedisList >> ensureBoundsFrom: fromIndex to: toIndex [
	(fromIndex < 1)
		ifTrue: [^self errorSubscriptBounds: fromIndex].
	(toIndex + firstIndex - 1 > lastIndex)
		ifTrue: [^self errorSubscriptBounds: toIndex].
]

{ #category : #private }
RedisList >> errorConditionNotSatisfied [

	self error: 'no element satisfies condition'
]

{ #category : #running }
RedisList >> execute: commandArgs [
	^ client execute: commandArgs
]

{ #category : #private }
RedisList >> find: oldObject [
  "  This method answers an index in the range firstIndex .. lastIndex, which is meant for internal use only.
     Never use this method in your code, the methods for public use are:
        #indexOf:
        #indexOf:ifAbsent: "

	| index |
	index := firstIndex.
	[index <= lastIndex]
		whileTrue:
			[(array at: index) = oldObject ifTrue: [^ index].
			index := index + 1].
	self errorNotFound: oldObject
]

{ #category : #private }
RedisList >> growAtFirst [
	"Add new empty slots to the front of array, while keeping the empty slots at the end."

	| newArray newFirstIndex newLastIndex |
	newArray := self class arrayType new: (array size * 2 max: 1).
	newFirstIndex := newArray size - array size + firstIndex.
	newLastIndex := newFirstIndex + lastIndex - firstIndex.
	newArray 
		replaceFrom: newFirstIndex
		to: newLastIndex
		with: array
		startingAt: firstIndex.
	array := newArray.
	firstIndex := newFirstIndex.
	lastIndex := newLastIndex
]

{ #category : #private }
RedisList >> growAtLast [
	"Add new empty slots to the end of array, while keeping the empty slots at the front."

	| newArray |
	newArray := self class arrayType new: (array size * 2 max: 1).
	newArray 
		replaceFrom: firstIndex
		to: lastIndex
		with: array
		startingAt: firstIndex.
	array := newArray
]

{ #category : #private }
RedisList >> insert: anObject before: spot [

  "  spot is an index in the range firstIndex .. lastIndex, such an index is not known from outside the collection. 
     Never use this method in your code, it is meant for private use by OrderedCollection only.
     The methods for use are:
        #add:before:   to insert an object before another object
        #add:beforeIndex:   to insert an object before a given position. "
	| "index" delta spotIndex|
	spotIndex := spot.
	delta := spotIndex - firstIndex.
	firstIndex = 1
		ifTrue: 
			[self makeRoomAtFirst.
			spotIndex := firstIndex + delta].
	firstIndex := firstIndex - 1.
	array
		replaceFrom: firstIndex
		to: spotIndex - 2
		with: array
		startingAt: firstIndex + 1.
	array at: spotIndex - 1 put: anObject.
"	index := firstIndex := firstIndex - 1.
	[index < (spotIndex - 1)]
		whileTrue: 
			[array at: index put: (array at: index + 1).
			index := index + 1].
	array at: index put: anObject."
	^ anObject
]

{ #category : #splitjoin }
RedisList >> join: aCollection [ 
	"Append the elements of the argument, aSequenceableCollection, separating them by the receiver."
	
	| result |
	result := self class new.
	aCollection
		do: [:each | each appendTo: result]
		separatedBy: [self appendTo: result].
	^ result
]

{ #category : #private }
RedisList >> makeRoomAtFirst [
	"Make some empty slots at the front of the array. If we have more than 50% free space, then just move the elements, so that the first 50% of the slots are free, otherwise add new free slots to the front by growing. Precondition: firstIndex = 1"
	
	| tally newFirstIndex newLastIndex |
	tally := self size.
	tally * 2 >= array size ifTrue: [ ^self growAtFirst ].
	tally = 0 ifTrue: [ ^self resetTo: array size + 1 ].
	newFirstIndex := array size // 2 + 1.
	newLastIndex := newFirstIndex - firstIndex + lastIndex.
	0 to: tally - 1 do: [ :offset |
		array at: newLastIndex - offset put: (array at: lastIndex - offset) ].
	array from: firstIndex to: newFirstIndex - 1 put: nil.
	firstIndex := newFirstIndex.
	lastIndex := newLastIndex
]

{ #category : #private }
RedisList >> makeRoomAtLast [
	"Make some empty slots at the end of the array. If we have more than 50% free space, then just move the elements, so that the last 50% of the slots are free, otherwise add new free slots to the end by growing. Precondition: lastIndex = array size"
	
	| tally newFirstIndex newLastIndex |
	tally := self size.
	tally * 2 >= lastIndex ifTrue: [ ^self growAtLast ].
	tally = 0 ifTrue: [ ^self resetTo: 1 ].
	newLastIndex := lastIndex // 2.
	newFirstIndex := newLastIndex - lastIndex + firstIndex.
	array 
		replaceFrom: newFirstIndex
		to: newLastIndex
		with: array
		startingAt: firstIndex.
	array from: newLastIndex + 1 to: lastIndex put: nil.
	firstIndex := newFirstIndex.
	lastIndex := newLastIndex
]

{ #category : #accessing }
RedisList >> name [
	^name
]

{ #category : #accessing }
RedisList >> name: anObject [
	name := anObject
]

{ #category : #copying }
RedisList >> postCopy [
	array := array copy
]

{ #category : #copying }
RedisList >> postCopyFrom: startIndex to: endIndex [ 
	"finish copying the array in a certain range."

	endIndex < startIndex ifFalse: [
		"Because actual size of the array may be greater than used size,
		postCopyFrom:to: may fail to fail and answer an incorrect result
		if this sanity check were not applied."
		(startIndex between: 1 and: self size) ifFalse: [^SubscriptOutOfBounds signalFor: startIndex lowerBound: (1 min: self size) upperBound: self size in: self].
		(endIndex between: 1 and: self size) ifFalse: [^SubscriptOutOfBounds signalFor: endIndex lowerBound: (1 min: self size) upperBound: self size in: self]].
	
	"Add a protection that lacks in Array>>postcopy"
	array := array copyFrom: startIndex + firstIndex - 1 to: (endIndex max: startIndex - 1) + firstIndex - 1.
	firstIndex := 1.
	lastIndex := array size
]

{ #category : #enumerating }
RedisList >> reject: rejectBlock [ 
	"Optimized version of Collection>>#reject:"

	| newCollection element |
	
	newCollection := self copyEmpty.
	
	firstIndex to: lastIndex do: [ :index |
		(rejectBlock value: (element := array at: index))
			ifFalse: [ newCollection addLast: element ]].
		
	^ newCollection
]

{ #category : #enumerating }
RedisList >> reject: rejectBlock thenCollect: collectBlock [
    " Optimized version of Collection>>#reject:thenCollect: "

	| newCollection |

    newCollection := self copyEmpty.

    firstIndex to: lastIndex do: [ :index |
		| element |
		element := array at: index.
		(rejectBlock value: element) 
			ifFalse: [ newCollection addLast: (collectBlock value: element) ]].

    ^ newCollection
]

{ #category : #removing }
RedisList >> remove: oldObject ifAbsent: absentBlock [

	| index |
	index := firstIndex.
	[index <= lastIndex]
		whileTrue: 
			[oldObject = (array at: index)
				ifTrue: 
					[self removeIndex: index.
					^ oldObject]
				ifFalse: [index := index + 1]].
	^ absentBlock value
]

{ #category : #removing }
RedisList >> removeAll [
	"remove all the elements from this collection.
	Keep same amount of storage"
	
	self setCollection: (self class arrayType new: array size)
]

{ #category : #removing }
RedisList >> removeAllSuchThat: aBlock [ 
	"Remove each element of the receiver for which aBlock evaluates to true.
	The method in Collection is O(N^2), this is O(N)."

	| n |
	n := firstIndex.
	firstIndex to: lastIndex do: [:index |
	    (aBlock value: (array at: index)) ifFalse: [
			array at: n put: (array at: index).
			n := n + 1]].
	array from: n to: lastIndex put: nil.
	lastIndex := n - 1
]

{ #category : #removing }
RedisList >> removeAt: index [
	| removed |
	removed := self at: index.
	self removeIndex: index + firstIndex - 1.
	^removed
]

{ #category : #removing }
RedisList >> removeDuplicates [
	| iterator |
	"Remove the copies of elements, but keep the same order"
	
	self ifEmpty: [ ^ self ].
	iterator := 1.
	[ iterator <= self size ]
		whileTrue: [ | each newIndex |
			each := self at: iterator.
			newIndex := iterator + 1.
			[ newIndex := (self indexOf: each startingAt: newIndex).
			newIndex > 0 ]
				whileTrue: [ self removeAt: newIndex ].
			iterator := iterator + 1.
	 ]
]

{ #category : #removing }
RedisList >> removeFirst [
	"Remove the first element of the receiver and answer it. If the receiver is 
	empty, create an error notification."
	| firstObject |
	self emptyCheck.
	firstObject := array at: firstIndex.
	array at: firstIndex put: nil.
	firstIndex := firstIndex + 1.
	^ firstObject
]

{ #category : #removing }
RedisList >> removeFirst: n [ 
	"Remove first n object into an array"
	| list |
	list := self class arrayType new: n.
	1
		to: n
		do:
			[ : i | list
				at: i
				put: self removeFirst ].
	^ list
]

{ #category : #private }
RedisList >> removeIndex: removedIndex [
  "  removedIndex is an index in the range firstIndex .. lastIndex, such an index is not known from outside the collection.
    Never use this method in your code, it is meant for private use by OrderedCollection only.
     The method for public use is:
        #removeAt: "

	array 
		replaceFrom: removedIndex 
		to: lastIndex - 1 
		with: array 
		startingAt: removedIndex+1.
	array at: lastIndex put: nil.
	lastIndex := lastIndex - 1.
]

{ #category : #removing }
RedisList >> removeLast [
	"Remove the last element of the receiver and answer it. If the receiver is 
	empty, create an error notification."
	| lastObject |
	self emptyCheck.
	lastObject := array at: lastIndex.
	array at: lastIndex put: nil.
	lastIndex := lastIndex - 1.
	^ lastObject
]

{ #category : #removing }
RedisList >> removeLast: n [ 
	"Remove last n object into an array with last in last position"
	| list |
	list := self class arrayType new: n.
	n
		to: 1
		by: -1
		do:
			[ : i | list
				at: i
				put: self removeLast ].
	^ list
]

{ #category : #initialization }
RedisList >> reset [
	"Quickly remove all elements. The objects will be still referenced, but will not be 	accessible."
	
	self resetTo: 1
]

{ #category : #private }
RedisList >> resetTo: index [
	firstIndex := index.
	lastIndex := firstIndex - 1
]

{ #category : #enumerating }
RedisList >> reverseDo: aBlock [
	"Override the superclass for performance reasons."

	lastIndex to: firstIndex by: -1 do: [ :index | 
		aBlock value: (array at: index) ]
]

{ #category : #converting }
RedisList >> reversed [
	"Answer a copy of the receiver with element order reversed.  "
	| newCol |
	newCol := self species new.
	self reverseDo:
		[:elem | newCol addLast: elem].
	^ newCol

"#(2 3 4 'fred') reversed"
]

{ #category : #enumerating }
RedisList >> select: selectBlock [ 
	"Optimized version of Collection>>#select: "

	| newCollection element |
	
	newCollection := self copyEmpty.
	
	firstIndex to: lastIndex do: [ :index |
		(selectBlock value: (element := array at: index))
			ifTrue: [ newCollection addLast: element ]].
		
	^ newCollection
]

{ #category : #enumerating }
RedisList >> select: selectBlock thenCollect: collectBlock [
    " Optimized version Collection>>#select:thenCollect: "

	| newCollection element |

    newCollection := self copyEmpty.

    firstIndex to: lastIndex do: [ :index |
		element := array at: index.
		(selectBlock value: element) 
			ifTrue: [ newCollection addLast: (collectBlock value: element) ]].

    ^ newCollection
]

{ #category : #private }
RedisList >> setCollection: anArray [
	array := anArray.
	self reset
]

{ #category : #private }
RedisList >> setContents: anArray [
	array := anArray.
	firstIndex := 1.
	lastIndex := array size.
]

{ #category : #accessing }
RedisList >> size [
	"Answer how many elements the receiver contains."

	^ lastIndex - firstIndex + 1
]

{ #category : #sorting }
RedisList >> sort: aSortBlock [ 
	"Sort this array using aSortBlock. The block should take two arguments
	and return true if the first element should preceed the second one."

	self size <= 1 ifTrue: [^ self].  "nothing to do"
	array
		mergeSortFrom: firstIndex
		to: lastIndex 
		src: array shallowCopy 
		dst: array 
		by: aSortBlock
]

{ #category : #enumerating }
RedisList >> with: otherCollection collect: twoArgBlock [ 
	"Collect and return the result of evaluating twoArgBlock with 
	corresponding elements from this collection and otherCollection."
	| result |
	otherCollection size = self size ifFalse: [self error: 'otherCollection must be the same size'].
	result := self species new: self size.
	1 to: self size do:
		[:index | result addLast: (twoArgBlock value: (self at: index)
									value: (otherCollection at: index))].
	^ result
]

{ #category : #enumerating }
RedisList >> withIndexCollect: elementAndIndexBlock [ 
	"Just like with:collect: except that the iteration index supplies the second argument to the block. Override superclass in order to use addLast:, not at:put:."

	| newCollection |
	newCollection := self species new: self size.
	firstIndex to: lastIndex do:
		[:index |
		newCollection addLast: (elementAndIndexBlock
			value: (array at: index)
			value: index - firstIndex + 1)].
	^ newCollection
]

{ #category : #enumerating }
RedisList >> withIndexSelect: elementAndIndexBlock select: selectBlock [
	"Optimized version of SequenceableCollection>>#withIndexSelect: "

	"(#('We' 'love' 'pharo!') asOrderedCollection withIndexSelect: [:value :index | value size - 1 <= index]) >>> (OrderedCollection with: 'We')"

	| newCollection element |
	newCollection := self copyEmpty.
	firstIndex to: lastIndex do: [ :index | 
		(selectBlock value: (element := array at: index) value: index)
			ifTrue: [ newCollection addLast: element ] ].
	^ newCollection
]