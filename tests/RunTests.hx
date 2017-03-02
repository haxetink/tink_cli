package ;


class RunTests {

	static function main() {
		
		tink.unit.TestRunner.run([
			new TestCommand(),
			new TestFlag(),
			new TestAliasDisabled(),
			// new TestPrompt(),
		]).handle(function(result) travix.Logger.exit(result.errors));
		
	}
}
