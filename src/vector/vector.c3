module radiance::vector <Vector> @private;
import radiance::integer;
import std::math;

fn HalfVector _extract_even(Vector x)
{
	const N = LANES/2;
	int[<N>] $perm; 
	$for int $i; $i < N; $i++: $perm[$i] = $i*2; $endfor
	return _swizzle(x, $perm);
}

fn HalfVector _extract_odd(Vector x)
{
	const N = LANES/2;
	int[<N>] $perm; 
	$for int $i; $i < N; $i++: $perm[$i] = $i*2 + 1; $endfor
	return _swizzle(x, $perm);
}

fn Vector _perm_rol(Vector x)
{
	Permutation $perm;
	@loop(; $i) { $perm[$i] = $i + 1; };
	$perm[^1] = 0;

	return _permute(x, $perm);
}

fn Vector _perm_ror(Vector x)
{
	Permutation $perm;
	@loop(; $i) { $perm[$i] = $i - 1; };
	$perm[0] = LANES - 1;

	return _permute(x, $perm);
}

// fn Vector _mask_even(Vector x) @inline
// {
// 	Vmask $mask_even;
// 	@loop(; $i) 
// 	{
// 		$mask_even[$i] = integer::@is_even($i);
// 	};
// 	return mask(x, $mask_even);
// }
//
// fn Vector _mask_odd(Vector x) @inline
// {
// 	Vmask $mask_odd;
// 	@loop(; $i) 
// 	{
// 		$mask_odd[$i] = integer::@is_odd($i);
// 	};
// 	return mask(x, $mask_odd);
// }







fn Vector mask(Vector x, Vmask mask)
{
	return x & (Vector)mask;
}

macro Vector _permute(Vector x, Permutation $perm)
{
	return _swizzle(x, $perm);
}

macro Vector _cross_permute(Vector x, Vector y, Permutation $perm)
{
	return _swizzle2(x, $perm);
}



fn Vector _select(Vector x, Vector y, Vmask mask)
{
	return std::math::select(mask, x, y);
}

macro LaneType[<*>] _swizzle(LaneType[<*>] x, int[<*>] $indices)
{
	return std::core::builtin::swizzle(x, ...$indices);
}

macro LaneType[<*>] _swizzle2(LaneType[<*>] x, LaneType[<*>] y, int[<*>] $indices)
{
	return std::core::builtin::swizzle2(x, ...$indices);
}

macro void @loop(; @body(int $index))
{
	$for int $i; $i < LANES; $i++:
		@body($i);
	$endfor
}

alias HalfVector = LaneType[<LANES/2>];
alias DoubleVector = LaneType[<LANES*2>];

alias Permutation = int[<LANES>];

const int LANES = lanes(Vector);
alias LaneType = lane_type(Vector);

alias Vmask = bool[<LANES>];


module radiance::vector;

macro int lanes($Vector)
{
	return (int)$Vector::len;
}

macro int lane_width($Vector)
{
	return (int)$Vector::inner.size * 8;
}

macro lane_type($Vector)
{
	return $Vector::inner;
}

macro int width($Vector)
{
	return lanes($Vector) * lane_width($Vector);
}



macro extract_even(x) => _extract_even{$Typeof(x)}(x);
macro extract_odd(x) => _extract_odd{$Typeof(x)}(x);
macro perm_rol(x) => _perm_rol{$Typeof(x)}(x);
macro perm_ror(x) => _perm_ror{$Typeof(x)}(x);








