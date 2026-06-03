module radiance::integer;
import std::core::types;

macro bool @all(#check, ...)
{
	bool $b;
	$for sz $i; $i < $vaarg.len; $i++:
		$b &= #check($Typeof($vaarg[$i]));
	$endfor
	return $b;
}

macro unsigned_from_bitsize(int $bitsize) @const
{
	$switch:
		$case $bitsize <=   8: return char;
		$case $bitsize <=  16: return ushort;
		$case $bitsize <=  32: return uint;
		$case $bitsize <=  64: return ulong;
		$case $bitsize <= 128: return uint128;
		$default: $error("The max integer bitsize is 128");
	$endswitch
}

macro signed_from_bitsize(int $bitsize) @const
{
	$switch:
		$case $bitsize <=   8: return ichar;
		$case $bitsize <=  16: return short;
		$case $bitsize <=  32: return int;
		$case $bitsize <=  64: return long;
		$case $bitsize <= 128: return int128;
		$default: $error("The max integer bitsize is 128");
	$endswitch
}

macro int_from_bitsize(int $bitsize, bool $signed)
{
	$if $signed:
		return signed_from_bitsize($bitsize);
	$else
		return unsigned_from_bitsize($bitsize);
	$endif
}

<*
	@ensure return <= 128
*>
macro int bitsize($Type) @const
{
	return (int)$Type::size * 8;
}

macro @bitsize(#x) @const => bitsize($Typeof(#x));

macro bool is_int($Type) @const
{
	$switch $Type::kind:
		$case UNSIGNED_INT:
		$case SIGNED_INT:
			return true;
		$case VECTOR:
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_unsigned($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool is_unsigned($Type) @const
{
	$switch $Type::kind:
		$case UNSIGNED_INT:
			return true;
		$case VECTOR:
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_unsigned($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool is_signed($Type) @const
{
	$switch $Type::kind:
		$case SIGNED_INT:
			return true;
		$case VECTOR:
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_signed($Type::inner);
		$default:
			return false;
	$endswitch
}

macro flat_kind($Type)
{
	$switch $Type::kind:
		$case SIGNED_INT:
			return $Type;
		$case VECTOR:
		$case BITSTRUCT:
		$case TYPEDEF:
			return core_kind($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool has_doublewidth_type($Type) @const
{
	return bitsize($Type) <= 64;
}

macro doublewidth_type($Type) @const
{
	return int_from_bitsize(bitsize($Type) * 2, is_signed($Type));
}

macro halfwidth_type($Type) @const
{
	return int_from_bitsize(bitsize($Type) / 2, is_signed($Type));
}

macro const_max($x, $y) @const
{
	return $x > $y ? $x : $y;
}

macro const_min($x, $y) @const
{
	return $x < $y ? $x : $y;
}

<*
	@require is_signed($Type) == is_signed($Least) : "Types must have the same signedness"
*>
macro type_atleast($Type, $Least) @const
{
	return int_from_bitsize(const_max(bitsize($Type), bitsize($Least)), is_signed($Type));
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
	"char", "ichar",
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
























