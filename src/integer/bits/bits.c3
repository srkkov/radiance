module radiance::integer::bit <Unsigned> @private;

const int K = integer::bitsize(Unsigned);

<*
 @require is_span(shift, width)
*>
fn Unsigned _mask(int width, int shift = 0) @inline
{
	return (Unsigned::max >> (K - width)) << shift;
}

<*
 @require is_index(index)
*>
fn Unsigned _bit(int index) @inline
{
	return (Unsigned)1 << index;
}

<*
 @require is_index(index)
*>
fn Unsigned _test(Unsigned x, int index) @inline
{
	return (x >> index) & 1;
}

<*
 @require is_index(index)
*>
fn Unsigned _set(Unsigned x, int index) @inline
{
	return x | _bit(index);
}

<*
 @require is_index(index)
*>
fn Unsigned _clear(Unsigned x, int index) @inline
{
	return x & ~_bit(index);
}

<*
 @require is_index(index)
*>
fn Unsigned _toggle(Unsigned x, int index) @inline
{
	return x ^ _bit(index);
}

<*
 @require is_bit(value)
 @require is_index(index)
*>
fn Unsigned _write(Unsigned x, Unsigned value, int index) @inline
{
	return x | (value << index);
}

// <*
//  @require is_index(ix), is_index(iy)
// *>
// fn Unsigned _copy(Unsigned x, Unsigned y, int ix, int iy) @inline
// {
// 	return _write(_clear(x, ix), _test(y, iy), ix);
// }
//
// <*
//  @require is_span(start_x, width_x), is_span(start_y, width_y)
// *>
// fn Unsigned _copy_spans(Unsigned x, int start_x, int width_x, Unsigned y, int start_y, int width_y) @inline
// {
// 	return (x & ~_mask(width_x, start_x)) | _extract(y, start_x, width_y) << start_x;
// }

<*
 @require is_width(width)
*>
fn Unsigned _truncate(Unsigned x, int width) @inline
{
	return x & _mask(width);
}

<*
 @require is_width(width)
*>
fn Unsigned _extract_high(Unsigned x, int width) @inline
{
	return x >> (K - width);
}

<*
 @require is_span(start, width)
*>
fn Unsigned _extract(Unsigned x, int start, int width) @inline
{
	return (x >> start) & _mask(width);
}

<*
 @require is_nibble_index(index)
*>
fn Unsigned _extract_nibble(Unsigned x, int index) @inline
{
	return (x >> 4*index) & 0x0f;
}

<*
 @require is_byte_index(index)
*>
fn Unsigned _extract_byte(Unsigned x, int index) @inline
{
	return (x >> 8*index) & 0xff;
}

<*
 @require is_span(start, width)
*>
fn Unsigned _deposit(Unsigned x, Unsigned value, int start, int width) @inline
{
	Unsigned mask = _mask(width);
	return (x & ~(mask << start)) | ((value & mask) << start);
}

<*
 @require is_nibble_index(index)
*>
fn Unsigned _deposit_nibble(Unsigned x, Unsigned value, int index) @inline
{
	return _deposit(x, value, index, 4);
}

<*
 @require is_byte_index(index)
*>
fn Unsigned _deposit_byte(Unsigned x, Unsigned value, int index) @inline
{
	return _deposit(x, value, index, 8);
}



<*
 @require delta >= 0, delta < K
*>
fn Unsigned _delta_swap(Unsigned x, int delta, Unsigned mask)
{
    Unsigned y;

	y  = x >> delta ^ x;
	y &= mask;
    return x ^ y ^ (y << delta);
}

<*
 @ensure is_bit(return)
*>
fn Unsigned _reduce_or(Unsigned x) @inline
{
	return (Unsigned)(x != 0);
}

<*
 @require is_width(width)
 @ensure is_bit(return)
*>
fn Unsigned _trunc_reduce_or(Unsigned x, int width) @inline
{
	return (Unsigned)(x << (K - width) != 0);
}

// fn Unsigned _parallel_extract(Unsigned x, Unsigned mask)
// {
// 	Unsigned r;
// 	for (int shift; mask; mask >>= 1, x >>= 1)
// 	{
// 		if (mask & 1)
// 		{
// 			r |= (x & 1) << shift++;
// 		}
// 	}
// 	return r;
// }














fn Unsigned _isolate_lowest_set_bit(Unsigned x) @inline
{
	return x & -x;
}

fn Unsigned _mask_lowest_set_bit(Unsigned x) @inline
{
	return (x - 1) ^ x;
}

<*
 @require x > 0
 @ensure is_index(return)
*>
fn int _lowest_set_bit_index(Unsigned x) @inline
{
	return _count_trailing_zeros(x);
}

<*
 @require x > 0
 @ensure is_index(return)
*>
fn int _last_set_bit(Unsigned x)
{
	return K - 1 - _count_leading_zeros(x);
}

fn bool _one_set_bit(Unsigned x)
{
	return x && x & (x - 1);
}

fn bool _is_pow2(Unsigned x)
{
	return x & (x - 1) == 0;
}

fn bool _is_mersenne(Unsigned x)
{
	return (x + 1) & x == 0;
}

fn bool _is_contiguous_span(Unsigned x)
{
	return x & (x + _isolate_lowest_set_bit(x)) == 0;
}

macro bool is_bit(x) => x >= 0 && x <= 1;
macro bool is_index(x) => x >= 0 && x < K;
macro bool is_width(x) => x >= 0 && x <= K;
macro bool is_count(x) => is_width(x);
macro bool is_span(begin, width) => begin >= 0 && width > 0 && begin + width < K;
macro bool is_bounds(begin, end) => begin >= 0 && begin <= end && end < K;

macro bool is_byte_index(x) => x >= 0 && x < K/8;
macro bool is_nibble_index(x) => x >= 0 && x < K/4;

macro bool is_length_mask(x) => (x + 1) & x == 0;

// While defined here, these functions will be exposed through `integer::`.
// And well, these are useless since they are just call to `std::bits::*`, so... yeah.

<*
 @ensure is_count(return)
*>
fn int _count_ones(Unsigned x)
{
	return x.popcount();
}

<*
 @ensure is_count(return)
*>
fn int _count_zeros(Unsigned x)
{
	return ~x.popcount();
}

<*
 @ensure is_count(return)
*>
fn int _count_leading_zeros(Unsigned x)
{
	return x.clz();
}

<*
 @ensure is_count(return)
*>
fn int _count_leading_ones(Unsigned x)
{
	return ~x.clz();
}

<*
 @ensure is_count(return)
*>
fn int _count_trailing_zeros(Unsigned x)
{
	return x.ctz();
}

<*
 @ensure is_count(return)
*>
fn int _count_trailing_ones(Unsigned x)
{
	return ~x.ctz();
}

<*
 @require is_count(shift) 
*>
fn Unsigned _funnel_shift_left(Unsigned x, Unsigned y, int shift)
{
	return Unsigned.fshl(x, y, (Unsigned)shift);
}

<*
 @require is_count(shift) 
*>
fn Unsigned _funnel_shift_right(Unsigned x, Unsigned y, int shift)
{
	return Unsigned.fshr(x, y, (Unsigned)shift);
}

<*
 @require is_count(amount)
*>
fn Unsigned _rotate_left(Unsigned x, int amount)
{
	return Unsigned.rotl(x, (Unsigned)amount);
}

<*
 @require is_count(amount)
*>
fn Unsigned _rotate_right(Unsigned x, int amount)
{
	return Unsigned.rotr(x, (Unsigned)amount);
}

import std::bits;

fn Unsigned _reverse_bits(Unsigned x) @inline
{
	return std::bits::reverse(x);
}

fn Unsigned _reverse_bytes(Unsigned x) @inline
{
	return std::bits::bswap(x);
}

module radiance::integer::bit;

macro test   (x, int index)         => _test   {$Typeof(x)}(x, index);
macro set    (x, int index)         => _set    {$Typeof(x)}(x, index);
macro clear  (x, int index)         => _clear  {$Typeof(x)}(x, index);
macro toggle (x, int index)         => _toggle {$Typeof(x)}(x, index);
macro write  (x, value, int index)  => _write  {$Typeof(x)}(x, value, index);
macro copy   (x, y, int ix, int iy) => _copy   {$Typeof(x)}(x, y, ix, iy);

macro extract         (x, int start, int width)         => _extract{$Typeof(x)}(x, start, width);
macro extract_nibble  (x, int index)                    => _extract_nibble{$Typeof(x)}(x, index);
macro extract_byte    (x, int index)                    => _extract_byte{$Typeof(x)}(x, index);
macro deposit         (x, value, int start, int width)  => _deposit{$Typeof(x)}(x, value, start, width);
macro deposit_nibble  (x, value, int index)             => _deposit_nibble{$Typeof(x)}(x, value, index);
macro deposit_byte    (x, value, int index)             => _deposit_byte{$Typeof(x)}(x, value, index);
macro reduce_or       (x)                               => _reduce_or{$Typeof(x)}(x);
macro trunc_reduce_or (x, int width)                    => _trunc_reduce_or{$Typeof(x)}(x);

macro int first_set_bit(x) => _first_set_bit{$Typeof(x)}(x);
macro int last_set_bit(x) => _last_set_bit{$Typeof(x)}(x);
macro bool one_set_bit(x) => _one_set_bit{$Typeof(x)}(x);

macro count_leading_zeros  (x) => _count_leading_zeros{$Typeof(x)}(x);
macro count_leading_ones   (x) => _count_leading_ones{$Typeof(x)}(x);
macro count_trailing_zeros (x) => _count_trailing_zeros{$Typeof(x)}(x);
macro count_trailing_ones  (x) => _count_trailing_ones{$Typeof(x)}(x);
macro count_ones           (x) => _count_ones{$Typeof(x)}(x);
macro count_zeros          (x) => _count_zeros{$Typeof(x)}(x);

alias popcnt = count_ones;
alias lzcnt = count_leading_zeros;
alias tzcnt = count_trailing_zeros;


// <*
//  @ensure return >= 0, return <= K
// *>
// macro int unsigned_bitwidth(Unsigned x)
// {
// 	return K - lzcnt(x);
// }
//
// <*
//  Signed integer bit utilities.
//
//  @require is_signed(Signed)
// *>
// module radiance::integer <Signed>;
//
// alias Unsigned = unsigned_equivalent(Signed);
//
// <*
//  @ensure return >= 0, return <= bitsize(Signed) 
// *>
// macro int signed_bitwidth(Signed x)
// {
// 	return unsigned_bitwidth((Unsigned)(x >= 0 ? x : ~x)) + 1;
// }
