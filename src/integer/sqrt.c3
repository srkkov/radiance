module radiance::integer;


<*
	@require is_unsigned($typeof(n))
	@require has_doublewidth_type($typeof(n))
*>
macro sqrt_binary_search(n)
{ 
	var $InputType = $typeof(n);
	var $Type = type_atleast($InputType, uint);
	var $DType = doublewidth_type($Type);

	if (n < 2) return n;

	$Type left, right, midpoint;

	// we search in [left,right),
	// left is always valid, right is always too large.
	right = n; 

	while (left != right - 1)
	{
		midpoint = (left + right) / 2;
		if (($DType)midpoint*($DType)midpoint <= n)
		{
			left = midpoint;
		}
		else
		{
			right = midpoint;
		}
	}
    return ($InputType)left;
}
