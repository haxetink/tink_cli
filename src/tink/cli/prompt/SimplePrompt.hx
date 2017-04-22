package tink.cli.prompt;

import tink.io.Sink;
import tink.io.Source;
import tink.cli.Prompt;

using tink.CoreApi;

class SimplePrompt extends IoPrompt<Error, Error> {
	public function new() {
		super(Source.ofNodeStream('stdin', js.Node.process.stdin), Sink.ofNodeStream('stdout', js.Node.process.stdout));
	}
}