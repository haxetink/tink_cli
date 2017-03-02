# tink_cli
Stealing the tink name again, for a cli framework

## Usage

```haxe
Cli.process(Sys.args(), new MyCommand()).handle(function(o) {});
```

### Flags
Every `public var` in the class will be treated as a cli flag.

For example `public var flag:String` will be set to value `<x>` by the cli swtich `--flag <x>`.
Also, the framework will also recognize the first letter of the flag name as alias. So in this case
`-f <x>` will do the same.

You can use metadata data to govern the flag name (`@:flag('my-custom-flag-name')`) and alias (`@:alias('a')`).
Note that you can only use a single charater for alias.

The reason for a single-char restriction for alias is that you can use a condensed alias format, for example:

`-abcdefg` is actually equivalent to `-a -b -c -d -e -f -g`.

### Commands
Public methods tagged with `@:command` will be treated as a runnable command.

For example `@:command public function run() {}` can be triggered by `./yourscript run`. In case you want to
run a function under your binary name, you can tag a function with `@:defaultCommand`, then you will be able
to run the function with `./yourscript`.

By default the framework infer the command name from the method name,
you can provide a parameter to the metadata like `@:command('my-cmd')` to change that.

#### Function signature:

TODO...

### Data Types

By default, Bool, Int, Float and String are supported. Furthermore, you can use any abstract that is castable from String
(i.e. `from String` or `@:from public static function ofString(v:String)`) as the data type.

For example, to use a Map:

```haxe

@:forward
abstract CustomMap(StringMap<Int>) from StringMap<Int> to StringMap<Int> {
	@:from
	public static function fromString(v:String):CustomMap {
		var map = new StringMap<Int>();
		for(i in v.split(',')) switch i.split('=') {
			case [key, value]: map.set(key, (value:tink.Stringly));
			default: throw 'Invalid format';
		}
		return map;
	}
} 
```

Also, note that if a flag is of type Bool, the flag will be set to true without considering the "switch argument",
For example, `--force` is used instead of `--force true` to set `force = true`. In fact in the latter case, the `true`
string is considered as a Rest argument.

Rest argument is a list of strings which are not consumed by the flag parser. You can capture it in a command with
an `Array<String>`. For example:

```haxe
@:defaultCommand
public function run(rest:Array<String>) {}
```

### Examples

Check out the examples folder.