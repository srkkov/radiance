module radiance::integer::bit;

<*
 @require[shift]  shift >= 0
 @require[width]  width > 0
 @require         width + shift <= K
*>
fn Unsigned mask(int width, int shift = 0) <Unsigned> @inline
{
	return (Unsigned::max >> (K - width)) << shift;
}

<*
 @require[index] index >= 0, index < K
*>
fn Unsigned bit(int index) <Unsigned> @inline
{
	return (Unsigned)1 << index;
}


module radiance::integer::bit <Unsigned> @private;

const int K = integer::bitsize(Unsigned);

// ======================
// --- Bit Operations ---
// ======================

<*
 @require[index] index >= 0, index < K
*>
fn Unsigned _test(Unsigned x, int index) @inline
{
	return (x >> index) & 1;
}

<*
 @require[index] index >= 0, index < K
*>
fn Unsigned _set(Unsigned x, int index) @inline
{
	return x | bit(index);
}

<*
 @require[index] index >= 0, index < K
*>
fn Unsigned _clear(Unsigned x, int index) @inline
{
	return x & ~bit(index);
}

<*
 @require[index] index >= 0, index < K
*>
fn Unsigned _toggle(Unsigned x, int index) @inline
{
	return x ^ bit(index);
}

<*
 @require[value] value <= 1
 @require[index] index >= 0, index < K
*>
fn Unsigned _write(Unsigned x, Unsigned value, int index) @inline
{
	return x | (value << index);
}

// =======================
// --- Word Operations ---
// =======================

<*
 @require[width] width > 0, width <= K
*>
fn Unsigned _isolate_low(Unsigned x, int width) @inline
{
	return x & mask(width);
}

<*
 @require[width] width > 0, width <= K
*>
fn Unsigned _isolate_high(Unsigned x, int width) @inline
{
	return x & mask(width, K - width);
}

<*
 @require[width] width > 0, width <= K
*>
fn Unsigned _clear_low(Unsigned x, int width) @inline
{
	return x & ~mask(width);
}

<*
 @require[width] width > 0, width <= K
*>
fn Unsigned _clear_high(Unsigned x, int width) @inline
{
	return x & ~mask(width, K - width);
}

<*
 @require[width] width > 0, width <= K
*>
fn Unsigned _extract_high(Unsigned x, int width) @inline
{
	return x >> (K - width);
}

<*
 @require[start]  start >= 0
 @require[len]    len > 0
 @require         start + len <= K
*>
fn Unsigned _extract(Unsigned x, int start, int len) @inline
{
	return (x >> start) & mask(len);
}

<*
 @require[index] index >= 0, x <= K/4
*>
fn char _extract_nibble(Unsigned x, int index) @inline
{
	return (char)((x >> 4*index) & 0x0f);
}

<*
 @require[index] index >= 0, x <= K/8
*>
fn char _extract_byte(Unsigned x, int index) @inline
{
	return (char)((x >> 8*index) & 0xff);
}

<*
 @require[start]  start >= 0
 @require[len]    len > 0
 @require         start + len <= K
*>
fn Unsigned _deposit(Unsigned x, Unsigned value, int start, int len) @inline
{
	Unsigned msk = mask(len);
	return (x & ~(msk << start)) | ((value & msk) << start);
}

<*
 @require[index] index >= 0, x <= K/4
*>
fn Unsigned _deposit_nibble(Unsigned x, char value, int index) @inline
{
	return _deposit(x, value, index, 4);
}

<*
 @require[index] index >= 0, x <= K/8
*>
fn Unsigned _deposit_byte(Unsigned x, char value, int index) @inline
{
	return _deposit(x, value, index, 8);
}



// <*
//  @require[delta] delta >= 0, delta < K
// *>
// fn Unsigned _delta_swap(Unsigned x, int delta, Unsigned mask)
// {
//     Unsigned y;
//
// 	y  = x >> delta ^ x;
// 	y &= mask;
//     return x ^ y ^ (y << delta);
// }
//
// <*
//  @require[start]  start >= 0
//  @require[len]    len > 0
//  @require         start + len <= K
//
//  @ensure          return <= 1
// *>
// fn Unsigned _reduce_or(Unsigned x, int start, int len) @inline
// {
// 	return (Unsigned)((x >> start) << (K - len) != 0);
// }

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











fn Unsigned _isolate_lowest_setbit(Unsigned x) @inline
{
	return x & -x;
}

fn Unsigned mask_lowest_setbit(Unsigned x) @inline
{
	return (x - 1) ^ x;
}

<*
 @require[x] x > 0
 @ensure return >= 0, return < K
*>
fn int _lowest_setbit_index(Unsigned x) @inline
{
	return _lzcnt(x);
}

<*
 @require[x] x > 0
 @ensure return >= 0, return < K
*>
fn int _last_setbit(Unsigned x)
{
	return K - 1 - _lzcnt(x);
}

fn bool _one_setbit(Unsigned x)
{
	return x && x & (x - 1);
}

fn bool _is_contiguous_span(Unsigned x)
{
	return x & (x + _isolate_lowest_setbit(x)) == 0;
}

macro bool is_lengthmask(x) => (x + 1) & x == 0;

// These are technically useless since they just call `std::bits::*` functions, so... yeah.
// But I like them as functions much better than as methods.

<*
 @ensure return >= 0, return <= K
*>
fn int _popcnt(Unsigned x)
{
	return x.popcount();
}

<*
 @ensure return >= 0, return <= K
*>
fn int _lzcnt(Unsigned x)
{
	return x.clz();
}

<*
 @ensure return >= 0, return <= K
*>
fn int _tzcnt(Unsigned x)
{
	return x.ctz();
}

<*
 @require[amount] amount >= 0, amount < K
*>
fn Unsigned _funnel_shl(Unsigned x, Unsigned y, int amount)
{
	return Unsigned.fshl(x, y, (Unsigned)amount);
}

<*
 @require[amount] amount >= 0, amount < K
*>
fn Unsigned _funnel_shr(Unsigned x, Unsigned y, int amount)
{
	return Unsigned.fshr(x, y, (Unsigned)amount);
}

<*
 @require[amount] amount >= 0, amount < K
*>
fn Unsigned _rol(Unsigned x, int amount)
{
	return Unsigned.rotl(x, (Unsigned)amount);
}

<*
 @require[amount] amount >= 0, amount < K
*>
fn Unsigned _ror(Unsigned x, int amount)
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

macro test   (x, int index)         => _test{$Typeof(x)}(x, index);
macro set    (x, int index)         => _set{$Typeof(x)}(x, index);
macro clear  (x, int index)         => _clear{$Typeof(x)}(x, index);
macro toggle (x, int index)         => _toggle{$Typeof(x)}(x, index);
macro write  (x, value, int index)  => _write{$Typeof(x)}(x, value, index);
macro copy   (x, y, int ix, int iy) => _copy{$Typeof(x)}(x, y, ix, iy);

macro msb(x) => _test{$Typeof(x)}(x, K{$Typeof(x)} - 1);

macro isolate_low(x, int bits) => _isolate_low{$Typeof(x)}(x, bits);
macro isolate_high(x, int bits) => _isolate_high{$Typeof(x)}(x, bits);
macro clear_low(x, int bits) => _clear_low{$Typeof(x)}(x, bits);
macro clear_high(x, int bits) => _clear_high{$Typeof(x)}(x, bits);

macro extract         (x, int start, int len)         => _extract{$Typeof(x)}(x, start, len);
macro extract_nibble  (x, int index)                  => _extract_nibble{$Typeof(x)}(x, index);
macro extract_byte    (x, int index)                  => _extract_byte{$Typeof(x)}(x, index);
macro deposit         (x, value, int start, int len)  => _deposit{$Typeof(x)}(x, value, start, len);
macro deposit_nibble  (x, value, int index)           => _deposit_nibble{$Typeof(x)}(x, value, index);
macro deposit_byte    (x, value, int index)           => _deposit_byte{$Typeof(x)}(x, value, index);

macro int first_setbit(x) => _first_setbit{$Typeof(x)}(x);
macro int last_setbit(x) => _last_setbit{$Typeof(x)}(x);
macro bool one_setbit(x) => _one_setbit{$Typeof(x)}(x);

macro popcnt (x) => _popcnt{$Typeof(x)}(x);
macro lzcnt  (x) => _lzcnt{$Typeof(x)}(x);
macro tzcnt  (x) => _tzcnt{$Typeof(x)}(x);

// <*
//  @ensure return >= 0, return <= K
// *>
// macro int unsignedbitwidth(Unsigned x)
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
// macro int signedbitwidth(Signed x)
// {
// 	return unsignedbitwidth((Unsigned)(x >= 0 ? x : ~x)) + 1;
// }
