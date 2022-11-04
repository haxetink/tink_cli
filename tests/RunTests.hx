package ;

import tink.testrunner.*;
import tink.unit.*;

class RunTests {

	static function main() {
		
		Runner.run(TestBatch.make([
			new TestCommand(),
			new TestFlag(),
			new TestAliasDisabled(),
			new TestPrompt(),
			new TestPromptAndRest(),
			new TestOptional(),
			new TestDoc(),
		])).handle(Runner.exit);
		
	}
}
