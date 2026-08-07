module radiance::integer;

const MAX_BITS = 128;
const MIN_BITS = 8;

<*
 @require is_int($Type)
 @ensure return > 0, return <= MAX_BITS
*>
macro int bitsize($Type)
{
	return (int)$Type::size * 8;
}

<*
 @require $bitsize > 0, $bitsize <= MAX_BITS 
*>
macro unsigned_from_bitsize(int $bitsize) @const
{
	$switch:
		$case $bitsize <=   8: return char;
		$case $bitsize <=  16: return ushort;
		$case $bitsize <=  32: return uint;
		$case $bitsize <=  64: return ulong;
		$default:              return uint128;
	$endswitch
}

<*
 @require $bitsize > 0, $bitsize <= MAX_BITS 
*>
macro signed_from_bitsize(int $bitsize) @const
{
	$switch:
		$case $bitsize <=   8: return ichar;
		$case $bitsize <=  16: return short;
		$case $bitsize <=  32: return int;
		$case $bitsize <=  64: return long;
		$default:              return int128;
	$endswitch
}

macro int_from_bitsize(int $bitsize, bool $signed) @const
{
	return $signed ???
		signed_from_bitsize($bitsize) : unsigned_from_bitsize($bitsize);
}

macro bool has_doublewidth_type($Type) @const
{
	return bitsize($Type) <= MAX_BITS / 2;
}

macro bool has_halfwidth_type($Type) @const
{
	return bitsize($Type) > MIN_BITS;
}

macro doublewidth_type($Type) @const
{
	return int_from_bitsize(bitsize($Type) * 2, is_signed($Type));
}

macro halfwidth_type($Type) @const
{
	return int_from_bitsize(bitsize($Type) / 2, is_signed($Type));
}

// macro vector_halfwidth_type($Type) @const
// {
// 	return $Typefrom($Type::inner)[<$Type::len/2>] @simd;
// }
//
// macro vector_doublewidth_type($Type) @const
// {
// 	return $Typefrom($Type::inner)[<$Type::len*2>] @simd;
// }
//
// macro vector_halfwidth_lane_type($Type) @const
// {
// 	return $Typefrom(halfwidth_type($Type::inner))[<$Type::len*2>] @simd;
// }
//
// macro vector_doublewidth_lane_type($Type) @const
// {
// 	return $Typefrom(doublewidth_type($Type::inner))[<$Type::len/2>] @simd;
// }









<*
 @require is_signed($Type) == is_signed($Least) : "Types must have the same signedness"
*>
macro atleast_type($Type, $Least) @const
{
	return int_from_bitsize(@max(bitsize($Type), bitsize($Least)), is_signed($Type));
}

macro unsigned_equivalent($Type)
{
	return unsigned_from_bitsize(bitsize($Type));
}

macro signed_equivalent($Type)
{
	return signed_from_bitsize(bitsize($Type));
}

const String[] INT_TYPES =
{
	"ichar", "char",
	"short", "ushort",
	"int", "uint",
	"long", "ulong",
	"int128", "uint128",
};

const String[] SIGNED_TYPES =
{
	"ichar",
	"short",
	"int",
	"long",
	"int128",
};

const String[] UNSIGNED_TYPES =
{
	"char",
	"ushort",
	"uint",
	"ulong",
	"uint128",
};



















