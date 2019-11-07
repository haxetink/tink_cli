package tink.cli;

interface DocFormatter<T> {
	function format(spec:DocSpec):T;
}

typedef DocSpec = {
	doc:String, // class-level doc
	commands:Array<DocCommand>,
	flags:Array<DocFlag>,
}

typedef DocCommand = {
	isDefault:Bool,
	isSub:Bool,
	names:Array<String>,
	doc:String,
}

typedef DocFlag = {
	aliases:Array<String>,
	names:Array<String>,
	doc:String,
	paramDescription:String
}