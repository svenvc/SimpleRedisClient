testing
testQueueSimple
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