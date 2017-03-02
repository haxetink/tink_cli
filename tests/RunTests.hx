package ;


class RunTests {

	static function main() {
		
		tink.unit.TestRunner.run([
			new TestCommand(),
			new TestFlag(),
		]).handle(function(result) travix.Logger.exit(result.errors));
		
	}
}
