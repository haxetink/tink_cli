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
		])).handle(Runner.exit);
		
	}
}
