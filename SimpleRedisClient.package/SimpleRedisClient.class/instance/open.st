initialize-release
open
	self close.
	connection := ZdcSocketStream openConnectionToHostNamed: self host port: self port.
	in := ZnCharacterReadStream on: connection.
	out := ZnCharacterWriteStream on: connection