module radiance::integer <Integer>;

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 3, Layers = [1, 1, 1]

 @ensure #x1 >= #x2, #x2 >= #x3, #x2 >= #x3
*>
macro void @sort3(Integer #x1, Integer #x2, Integer #x3)
{
	@_maxmin(#x1, #x3); 
	@_maxmin(#x1, #x2); 
	@_maxmin(#x2, #x3); 
}

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 3, Layers = [2, 2, 1]

 @ensure #x1 >= #x2, #x2 >= #x3, #x3 >= #x4, #x3 >= #x4
*>
macro void @sort4(Integer #x1, Integer #x2, Integer #x3, Integer #x4)
{
	@_maxmin(#x1, #x3); @_maxmin(#x2, #x4); 
	@_maxmin(#x1, #x2); @_maxmin(#x3, #x4); 
	@_maxmin(#x2, #x3); 
}

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 5, Layers = [2, 2, 2, 2, 1]

 @ensure #x1 >= #x2, #x2 >= #x3, #x3 >= #x4, #x4 >= #x5, #x4 >= #x5
*>
macro void @sort5(Integer #x1, Integer #x2, Integer #x3, Integer #x4, Integer #x5)
{
	@_maxmin(#x1, #x4); @_maxmin(#x2, #x5); 
	@_maxmin(#x1, #x3); @_maxmin(#x2, #x4); 
	@_maxmin(#x1, #x2); @_maxmin(#x3, #x5); 
	@_maxmin(#x2, #x3); @_maxmin(#x4, #x5); 
	@_maxmin(#x3, #x4); 
}

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 5, Layers = [3, 2, 2, 3, 2]

 @ensure #x1 >= #x2, #x2 >= #x3, #x3 >= #x4, #x4 >= #x5, #x5 >= #x6, #x5 >= #x6
*>
macro void @sort6(Integer #x1, Integer #x2, Integer #x3, Integer #x4, Integer #x5, Integer #x6)
{
	@_maxmin(#x1, #x6); @_maxmin(#x2, #x4); @_maxmin(#x3, #x5); 
	@_maxmin(#x2, #x3); @_maxmin(#x4, #x5); 
	@_maxmin(#x1, #x4); @_maxmin(#x3, #x6); 
	@_maxmin(#x1, #x2); @_maxmin(#x3, #x4); @_maxmin(#x5, #x6); 
	@_maxmin(#x2, #x3); @_maxmin(#x4, #x5); 
}

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 6, Layers = [3, 3, 3, 2, 2, 3]

 @ensure #x1 >= #x2, #x2 >= #x3, #x3 >= #x4, #x4 >= #x5, #x5 >= #x6, #x6 >= #x7, #x6 >= #x7
*>
macro void @sort7(Integer #x1, Integer #x2, Integer #x3, Integer #x4, Integer #x5, Integer #x6, Integer #x7)
{
	@_maxmin(#x1, #x7); @_maxmin(#x3, #x4); @_maxmin(#x5, #x6); 
	@_maxmin(#x1, #x3); @_maxmin(#x2, #x5); @_maxmin(#x4, #x7); 
	@_maxmin(#x1, #x2); @_maxmin(#x3, #x6); @_maxmin(#x4, #x5); 
	@_maxmin(#x2, #x3); @_maxmin(#x5, #x7); 
	@_maxmin(#x3, #x4); @_maxmin(#x5, #x6); 
	@_maxmin(#x2, #x3); @_maxmin(#x4, #x5); @_maxmin(#x6, #x7); 
}

<*
 Sorts 3 variables in descending order using a sorting network.
 Latency = 6, Layers = [4, 4, 4, 2, 2, 3]

 @ensure #x1 >= #x2, #x2 >= #x3, #x3 >= #x4, #x4 >= #x5, #x5 >= #x6, #x6 >= #x7, #x7 >= #x8, #x7 >= #x8
*>
macro void @sort8(Integer #x1, Integer #x2, Integer #x3, Integer #x4, Integer #x5, Integer #x6, Integer #x7, Integer #x8)
{
	@_maxmin(#x1, #x3); @_maxmin(#x2, #x4); @_maxmin(#x5, #x7); @_maxmin(#x6, #x8); 
	@_maxmin(#x1, #x5); @_maxmin(#x2, #x6); @_maxmin(#x3, #x7); @_maxmin(#x4, #x8); 
	@_maxmin(#x1, #x2); @_maxmin(#x3, #x4); @_maxmin(#x5, #x6); @_maxmin(#x7, #x8); 
	@_maxmin(#x3, #x5); @_maxmin(#x4, #x6); 
	@_maxmin(#x2, #x5); @_maxmin(#x4, #x7); 
	@_maxmin(#x2, #x3); @_maxmin(#x4, #x5); @_maxmin(#x6, #x7); 
}




module radiance::integer;

<*
 @require @is_int(...$vaarg)
 @require @type_match(...$vaarg)
*>
macro void @sort(...)
{
	var $Type = $Typeof($vaarg[0]);

	$switch $vaarg.len:
		$case 1:
			return;
		$case 2:
			@_maxmin{$Type}(...$vaarg);
		$case 3:
			@sort3{$Type}(...$vaarg);
		$case 4:
			@sort4{$Type}(...$vaarg);
		$case 5:
			@sort5{$Type}(...$vaarg);
		$case 6:
			@sort6{$Type}(...$vaarg);
		$case 7:
			@sort7{$Type}(...$vaarg);
		$case 8:
			@sort8{$Type}(...$vaarg);
	$endswitch
}
