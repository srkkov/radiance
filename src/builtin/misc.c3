module std::core::radiance;
import std::io;

macro void dump(...) @builtin
{
	$for sz $i; $i < $vaarg.len; $i++:
		io::printf("%s: ", $stringify($vaarg[$i]));

		var result = $vaarg[$i];
		$if $Typeof(result)::kind == OPTIONAL:
			if (catch err = result)
			{
				io::printn(err);
			}
			else
			{
				io::printn(result);
			}
		$else
			io::printn(result);
		$endif
	$endfor
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

macro @unpredictable(bool #expr) @builtin
{
	return @likely(#expr, 0.5);
}

macro @reverse_array($array) @builtin
{
	$for sz $i; $i < $array.len / 2; $i++:
		var $tmp = $array[$i];
		$array[$i] = $array[$array.len - $i - 1];
		$array[$array.len - $i - 1] = $tmp;
	$endfor
	return $array;
}









