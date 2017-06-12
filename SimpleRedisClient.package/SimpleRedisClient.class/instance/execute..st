convenience
execute: commandArgs
	self writeCommand: commandArgs.
	^ self readReply 