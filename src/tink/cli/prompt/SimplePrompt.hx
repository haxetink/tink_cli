package tink.cli.prompt;

import tink.io.Sink;
import tink.io.Source;
import tink.io.Duplex;
import tink.cli.Prompt;

using tink.CoreApi;

class SimplePrompt extends DuplexPrompt {
	public function new() {
		super(new StdDuplex());
	}
}

class StdDuplex implements Duplex {
	public var source(get, never):Source;
	public var sink(get, never):Sink;
	
	public function new() {}
	
	public function close() {
		// do nothing, you cannot close stdin/stdout
	}
	
	inline function get_source() return Source.stdin;
	inline function get_sink() return Sink.stdout;
}