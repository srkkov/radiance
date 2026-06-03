module radiance::util;

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

macro @sqfor (sz lower, sz upper; @body(i, j))
{
	for (sz i = lower; i <= upper; i++)
	{
		for (sz j = lower; j <= upper; j++)
		{
			@body(i, j);
		}
	}
}
