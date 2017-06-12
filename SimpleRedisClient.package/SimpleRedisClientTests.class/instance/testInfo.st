testing
testInfo
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