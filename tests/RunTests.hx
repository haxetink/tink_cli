package ;


class RunTests {

	static function main() {
		
		tink.unit.TestRunner.run([
			new TestCommand()
		]).handle(function(result) travix.Logger.exit(result.errors));
		
	}
}
