"
I am BaselineOfSimpleRedisClient, I am used to load the code of SimpleRedisClient.
I am a BaselineOf.
"
Class {
	#name : #BaselineOfSimpleRedisClient,
	#superclass : #BaselineOf,
	#category : #BaselineOfSimpleRedisClient
}

{ #category : #baselines }
BaselineOfSimpleRedisClient >> baseline: spec [
	<baseline>
	spec for: #common do: [ spec package: 'SimpleRedisClient' ]
]
