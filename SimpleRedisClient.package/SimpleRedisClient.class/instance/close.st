initialize-release
close
	connection
		ifNotNil: [ 
			[ connection close ] on: Error do: [  ].
			in := out := connection := nil ]