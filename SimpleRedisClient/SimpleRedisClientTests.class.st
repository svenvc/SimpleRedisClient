"
I am SimpleRedisClientTests, holding unit tests as well as executeable examples and documentation for SimpleRedisClient.
"
Class {
	#name : #SimpleRedisClientTests,
	#superclass : #TestCase,
	#instVars : [
		'client'
	],
	#category : #SimpleRedisClient
}

{ #category : #running }
SimpleRedisClientTests >> setUp [
	super setUp.
	client := SimpleRedisClient new.
	client open
]

{ #category : #running }
SimpleRedisClientTests >> tearDown [
	client close.
	super tearDown
]

{ #category : #testing }
SimpleRedisClientTests >> testEcho [
	| string |
	string := 'STR-' , 99 atRandom asString.
	self assert: (client echo: string) equals: string
]

{ #category : #testing }
SimpleRedisClientTests >> testHashSimple [
	client execute: #(DEL myhash).
	self assert: (client execute: #(HGET myhash foo)) isNil.
	self assert: (client execute: #(HSET myhash foo one)) equals: 1.
	self assert: (client execute: #(HGET myhash foo)) equals: #one.
	self assert: (client execute: #(HSET myhash bar two)) equals: 1.
	self assert: (client execute: #(HGET myhash bar)) equals: #two.
	(Dictionary newFromPairs: (client execute: #(HGETALL myhash))) in: [ :dictionary |
		self assert: (dictionary at: #foo) equals: #one.
		self assert: (dictionary at: #bar) equals: #two ].
	client execute: #(DEL myhash).	
]

{ #category : #testing }
SimpleRedisClientTests >> testInfo [
	| redisInfo |
	redisInfo := Dictionary new.
	(client execute: #(INFO)) lines  
		reject: [ :line | 
			line isEmpty or: [ line first = $# ] ] 
		thenCollect: [ :line | 
			| keyValue |
			keyValue := $: split: line.
			redisInfo at: keyValue first put: keyValue second ].
	self assert: (redisInfo at: 'redis_mode') equals: 'standalone'
]

{ #category : #testing }
SimpleRedisClientTests >> testListSimple [
	client execute: #(DEL mylist).
	self assert: (client execute: #(LPUSH mylist one)) equals: 1.
	self assert: (client execute: #(LPUSH mylist two three)) equals: 3.
	self assert: (client execute: #(LPOP mylist)) equals: #three.
	self assert: (client execute: #(LINDEX mylist 0)) equals: #two.
	self assert: (client execute: #(LLEN mylist)) equals: 2.
	client execute: #(DEL mylist).
	
]

{ #category : #testing }
SimpleRedisClientTests >> testPing [
	self assert: client ping equals: #PONG
]

{ #category : #testing }
SimpleRedisClientTests >> testPubSubSimple [
	| semaphore string |
	string := 'STR-' , 99 atRandom asString.
	semaphore := Semaphore new.
	client execute: #(DEL mychannel).
	
	[
		| anotherClient |
		semaphore wait.
		anotherClient := SimpleRedisClient new.
		anotherClient open.
		self assert: (anotherClient execute: { #PUBLISH. #mychannel. string }) > 0.
		anotherClient close
	] forkAt: Processor userBackgroundPriority named: 'testPubSubSimple'.

	self assert: (client execute: #(SUBSCRIBE mychannel)) equals: #(subscribe mychannel 1).
	semaphore signal.
	"Block waiting for data distributed over the channel"
	self assert: client readReply equals: { #message. #mychannel. string }.
	self assert: (client execute: #(UNSUBSCRIBE mychannel)) equals: #(unsubscribe mychannel 0).
	client execute: #(DEL mychannel).	
]

{ #category : #testing }
SimpleRedisClientTests >> testQueueSimple [
	| string semaphore |
	string := 'STR-' , 99 atRandom asString.
	semaphore := Semaphore new.
	client execute: #(DEL myqueue).
	
	[
		| anotherClient |
		anotherClient := SimpleRedisClient new.
		anotherClient open.
		semaphore signal.
		"Block waiting for data entering the queue"
		self assert: (anotherClient execute: #(BRPOP myqueue 0)) equals: { #myqueue. string }.
		semaphore signal.
		anotherClient close
	] forkAt: Processor userSchedulingPriority named: 'testQueueSimple'.
	
	semaphore wait.
	self assert: (client execute: { #LPUSH. #myqueue. string }) > 0.
	semaphore wait.
	client execute: #(DEL myqueue).
]

{ #category : #testing }
SimpleRedisClientTests >> testQuit [
	self assert: (client executeInline: #QUIT) equals: #OK
]

{ #category : #testing }
SimpleRedisClientTests >> testSetSimple [
	client execute: #(DEL myset).
	self assert: (client execute: #(SADD myset one)) equals: 1.
	self assert: (client execute: #(SISMEMBER myset one)) equals: 1.
	self assert: (client execute: #(SADD myset one)) equals: 0.
	self assert: (client execute: #(SADD myset two)) equals: 1.
	self assert: (client execute: #(SADD myset three)) equals: 1.
	self assert: (client execute: #(SCARD myset)) equals: 3.
	self assert: (client execute: #(SMEMBERS myset)) asSet equals: #(one two three) asSet.
	client execute: #(DEL myset).	
]

{ #category : #testing }
SimpleRedisClientTests >> testSimpleCounter [
	client execute: #(DEL mycounter).
	self assert: (client execute: #(INCR mycounter)) equals: 1.
	self assert: (client execute: #(INCR mycounter)) equals: 2.
	self assert: (client execute: #(GET mycounter)) equals: '2'.
	self assert: (client execute: #(DECR mycounter)) equals: 1.
	self assert: (client execute: #(INCRBY mycounter 10)) equals: 11.
	client execute: #(DEL mycounter).
]

{ #category : #testing }
SimpleRedisClientTests >> testStringGetSetSimple [
	| string |
	string := 'STR-' , 99 atRandom asString.
	self assert: (client execute: #(DEL foo)) >= 0.
	self assert: (client execute: #(EXISTS foo)) equals: 0.
	self assert: (client execute: #(GET foo)) isNil.
	self assert: (client execute: { #SET. #foo. string }) equals: #OK.
	self assert: (client execute: #(GET foo)) equals: string.
	self assert: (client execute: #(EXISTS foo)) equals: 1.
	self assert: (client execute: #(DEL foo)) > 0.

]
