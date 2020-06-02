Class {
	#name : #RedisDictionary,
	#superclass : #Object,
	#traits : 'TRedisHash',
	#classTraits : 'TRedisHash classTrait',
	#instVars : [
		'client',
		'name'
	],
	#category : #SimpleRedisClient
}

{ #category : #accessing }
RedisDictionary >> client [
	^ client
]

{ #category : #accessing }
RedisDictionary >> client: anObject [
	client := anObject
]

{ #category : #running }
RedisDictionary >> execute: commandArgs [
	^ client execute: commandArgs
]

{ #category : #accessing }
RedisDictionary >> name [ 
	^name
]

{ #category : #accessing }
RedisDictionary >> name: anObject [
	name := anObject
]
