# Data Types

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
`Rest<String>`. For example:

```haxe
@:defaultCommand
public function run(rest:Rest<String>) {}
```

Note that at most one Rest argument may appear in the list.