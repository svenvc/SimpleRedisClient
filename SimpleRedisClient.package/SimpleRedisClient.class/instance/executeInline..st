convenience
executeInline: command
	self writeInlineCommand: command.
	^ self readReply 