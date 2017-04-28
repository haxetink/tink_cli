# Flags and Aliases

Every `public var` in the class will be treated as a cli flag.

For example `public var flag:String` will be set to value `<x>` by the cli swtich `--flag <x>`.
Also, the framework will also recognize the first letter of the flag name as alias. So in this case
`-f <x>` will do the same.

You can use metadata data to govern the flag name (`@:flag('my-custom-flag-name')`) and alias (`@:alias('a')`).
Note that you can only use a single charater for alias.

The reason for a single-char restriction for alias is that you can use a condensed alias format, for example:
`-abcdefg` is actually equivalent to `-a -b -c -d -e -f -g`.

If you specify a flag name starting with a single dash (e.g. `@:flag('-flag')`), it will be respected but then
alias support will be automatically disabled. You can also use `@:alias(false)` to manually disable alias,
which works on both field level and class level.