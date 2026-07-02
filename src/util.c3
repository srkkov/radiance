module std::core::radiance;
import std::io;

macro void dump(...) @builtin
{
	$for sz $i; $i < $vaarg.len; $i++:
		io::printfn($stringify($vaarg[$i]) +++ ": %s", $vaarg[$i]);
	$endfor
}

macro @unpredictable(bool #expr) @builtin
{
	return @likely(#expr, 0.5);
}

macro @repeat(sz count; @body()) @builtin
{
	do
	{
		@body();
	}
	while (--count);
}

macro @const_for(sz $count; @body(sz $i)) @builtin
{
	$for sz $i; $i < $count; $i++:
		@body($i);
	$endfor
}

