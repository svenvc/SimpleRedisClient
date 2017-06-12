testing
testPubSubSimple
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
	self assert: client readReply equals: { #message. #mychannel. string }.
	self assert: (client execute: #(UNSUBSCRIBE mychannel)) equals: #(unsubscribe mychannel 0).
	client execute: #(DEL mychannel).	