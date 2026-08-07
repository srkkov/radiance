<*
 is_int(VInteger) || is_int_vector(VInteger)
*>
module radiance::integer <VInteger>;
import std::math, std::math::vector;

const bool IS_INT = is_int(VInteger);

alias VMask = bool[< IS_INT ??? 1 : VInteger::len >];

fn VMask _vcmp_eq(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x == y) : VInteger.comp_eq(x, y);
fn VMask _vcmp_ne(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x != y) : VInteger.comp_ne(x, y);
fn VMask _vcmp_lt(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x <  y) : VInteger.comp_lt(x, y);
fn VMask _vcmp_le(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x <= y) : VInteger.comp_le(x, y);
fn VMask _vcmp_gt(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x >  y) : VInteger.comp_gt(x, y);
fn VMask _vcmp_ge(VInteger x, VInteger y) => IS_INT ??? (bool[<1>])(x >= y) : VInteger.comp_ge(x, y);

fn VMask _vcmp_z (VInteger x) => _vcmp_eq(x, {})@inline; 

fn VInteger _select(VInteger x, VInteger y, VMask mask)
{
	return IS_INT ??? (mask[0] ? x : y) : std::math::select(mask, x, y);
}

module radiance::integer;

macro vcmp_eq(x, y) => _vcmp_eq{$Typeof(x)}(x, y);
macro vcmp_ne(x, y) => _vcmp_ne{$Typeof(x)}(x, y);
macro vcmp_lt(x, y) => _vcmp_lt{$Typeof(x)}(x, y);
macro vcmp_le(x, y) => _vcmp_le{$Typeof(x)}(x, y);
macro vcmp_gt(x, y) => _vcmp_gt{$Typeof(x)}(x, y);
macro vcmp_ge(x, y) => _vcmp_ge{$Typeof(x)}(x, y);

macro vcmp_z(x) => _vcmp_z{$Typeof(x)}(x);

macro select(x, y, mask) => _select{$Typeof(x)}(x, y, mask);

// <*
//  @require @lanesof(input_vector_string) == @lanesof(@innerof(keyword_vector_strings))
//  @require @kindof(keyword_masks) == SLICE, type_is_maskof(@innerof(keyword_masks), @innerof(keyword_masks))
// *>
// macro vector_match_keywords(char[<*>] input_vector_string, char[<*>][] keyword_vector_strings, keyword_masks)
// {
// 	strmask = vector::cmp_z(vstr);
// 	foreach (kw : keywords)
// 	{
// 		mask = vector::cmp_eq(kw.vstr, vstr);
// 		if ((mask & strmask) == strmask)
// 		{
// 			return kw;
// 		}
// 	}
// 	return NOT_FOUND~;
// }







