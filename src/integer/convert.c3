// module radiance::integer <Integer>;
//
// <*
//  Used for invalid digit encodings when.
// *>
// faultdef INVALID_DIGIT;
//
// <*
//
// *>
// fn Integer? from_string(String string, int radix = 10)
// {
// 	sz len = string.len;
//
// 	if (!len) return std::core::string::EMPTY_STRING~;
//
// 	Integer result;
// 	sz i;
// 	bool sign;
//
// 	// if (char c = string[0], c == '+' || c == '-')
// 	// {
// 	// 	i++;
// 	// 	sign = c == '-';
// 	// }
//
// 	switch (char c = string[0], c)
// 	{
// 		case '+':
// 		case '-':
// 			i++;
// 			sign = c == '-';
//
// 		// case '0':
// 		// 	if (len == 1) return result;
// 		// 	switch 
// 		// 	if (char next = string[++i], next == 'x' || next == 'X')
// 		// 	{
// 		//
// 		// 	}
//
// 	}
//
// }
//
// fn Integer? convert_decimal_ascii_string(String string)
// {
// 	sz l = string.len;
// 	Integer accumulator;
// 	do
// 	{
// 		accumulator = _try_add(accumulator, char_to_integer(string))!;
// 	}
// 	while (l--);
// }



// [0-9]: 0x30 -> 0x39
//
// 0123456789abcdefghijklmnopqrstuvwxyz


// fn void vector_reduce_decimal_string(char[<*>] vec)
// {
// 	const N = vec.len;
// 	char[<N/2>] evens = vector::mask_even(vec)
//
// }
//
//
//
// <*
//  @require base > 0
// *>
// fn Integer convert_ascii_string(String string, int base)
// {
// 	foreach (c : string)
// 	{
//
// 	}
// }

