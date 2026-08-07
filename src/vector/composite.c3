module radiance::vector;

macro add(x, y) @local => x + y;
macro sub(x, y) @local => x - y;
macro mul(x, y) @local => x * y;
macro div(x, y) @local => x / y;
macro rem(x, y) @local => x % y;

<*
 @require is_composite_vector(CompositeVector)
*>
macro CompositeVector @_composite_parallel_2op(CompositeVector x, CompositeVector y, #op) <CompositeVector> @private
{
	CompositeVector r;

	$if CompositeVector::kind == ARRAY:
		$for sz $i; $i < CompositeVector::len; $i++:
			r[$i] = #op(x[$i], y[$i]);
		$endfor
	$else
		$foreach $member : CompositeVector::members:
			r.$member = #op(x.$member, y.$member);
		$endforeach
	$endif

	return r;
}

macro composite_parallel_add(x, y) => @_composite_parallel_2op{$Typeof(x)}(x, y, add);
macro composite_parallel_sub(x, y) => @_composite_parallel_2op{$Typeof(x)}(x, y, sub);
macro composite_parallel_mul(x, y) => @_composite_parallel_2op{$Typeof(x)}(x, y, mul);
macro composite_parallel_div(x, y) => @_composite_parallel_2op{$Typeof(x)}(x, y, div);
macro composite_parallel_rem(x, y) => @_composite_parallel_2op{$Typeof(x)}(x, y, rem);






