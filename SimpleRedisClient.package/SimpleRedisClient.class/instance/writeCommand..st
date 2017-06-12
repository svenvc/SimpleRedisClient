writing
writeCommand: args
	out nextPut: $*; print: args size; crlf.
	args do: [ :each |
		| string byteCount |
		string := each asString.
		byteCount := out encoder encodedByteCountForString: string.
		out 
			nextPut: $$; print: byteCount; crlf; 
			nextPutAll: string; crlf ].
	out flush