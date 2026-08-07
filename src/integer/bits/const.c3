module radiance::integer::bit <Unsigned>;

<*
 @ensure return >= 0, return <= K
*>
macro int _const_popcnt(Unsigned $x)
{
	// recursive SWAR horizontal addition
	// each step:
	//  1. extract even elements
	//  2. extract odd elements
	//  3. align and add, this halves the number of SWAR lanes
	//     yet lanes become larger to hold the sum without spilling carrying over.
	// end when we have 1 lane left.

	int $lane_width = 1;
	$foreach $even_mask : H:
		$x = $x & $even_mask + ($x >> $lane_width) & $even_mask;
		$lane_width <<= 1;
	$endforeach
	return x;
}

// macro repeat_pattern(Unsigned pattern, int width)
// {
// 	Unsigned $r;
// 	$for int $i; $i < K / $width; $i++:
//
// 	$endfor	
// }

<*
 @require $width >= 0, $shift >= 0, $width + $shift < K
*>
macro Unsigned @mask(int $width, int $shift = 0) @const
{
	$if $width == 0: return 0; $endif
	return (Unsigned::max >> (K - $width)) << $shift;
}

<*
 @require $index >= 0, $index < K
*>
macro Unsigned @bit(int $index) @const
{
	return (Unsigned)1 << $index;
}

const Unsigned EVEN_MASK = Unsigned::max / 3;
const Unsigned ODD_MASK = EVEN_MASK << 1;

const Unsigned MSB_MASK = @bit(K - 1);

const Unsigned[*] H = @reverse_array(_make_H());
const Unsigned[*] T = @reverse_array(_make_T());

// With K = 32:
//
// H = { 01010101010101010101010101010101,
//       00110011001100110011001100110011, 
//       00001111000011110000111100001111, 
//       00000000111111110000000011111111, 
//       00000000000000001111111111111111 }
// 
// T = { 01010101010101010101010101010101, 
// 	     00100010001000100010001000100010, 
// 	     00001000000010000000100000001000, 
// 	     00000000100000000000000010000000, 
// 	     00000000000000001000000000000000 }
//
// the length of H and T equal log2(K).

macro Unsigned[*] _make_H() @const @private
{
	untypedlist $elements;
	$for int $n = 1, int $l = K, int $w = K; ($w >>= 1); $n <<= 1, $l >>= 1:
		Unsigned $element;
		$for int $i; $i < $n; $i++:
			$element |= @mask($w, $l * $i);
		$endfor
		$elements +++= $element;
	$endfor
	return (Unsigned[*])$elements;
}

macro Unsigned[*] _make_T() @const @private 
{
	untypedlist $elements;
	$for int $n = 1, int $w = K/2; $w > 0; $n <<= 1, $w >>= 1:
		Unsigned $element;
		$for int $i; $i < $n; $i++:
			$element |= @bit($w * (2*$i + 1) - 1);
		$endfor
		$elements +++= $element;
	$endfor
	return (Unsigned[*])$elements;
}

macro Unsigned _make_even_mask() @const @private
{
	Unsigned $r;
	$for int $i; $i < K; $i++, $r <<= 2:
		$r |= 1;
	$endfor
	return $r | 1;
}

module radiance::integer;

macro int @popcnt(x) => _const_popcnt{$Typeof(x)}(x);




<*
 @require 0 < $bits, $bits <= 128
*>
macro max_unsigned_bits(int $bits) @const
{
	return $bits == 128 ???
		uint128::max : ($Typefrom(unsigned_from_bitsize($bits)))(1ull << $bits - 1ull);
}

<*
 @require 0 < $bits, $bits <= 128
*>
macro max_signed_bits(int $bits) @const
{
	return $bits == 128 ???
		int128::max : ( $Typefrom(signed_from_bitsize($bits)) )(1ull << $bits - 1ull);
}

<*
 @require 0 < $bits, $bits <= 128
*>
macro min_signed_bits(int $bits) @const
{
	return $bits == 128 ???
		int128::min : ( $Typefrom(signed_from_bitsize($bits)) )(-(1ull << ($bits - 1)));
}
