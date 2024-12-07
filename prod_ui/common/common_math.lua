local commonMath = {}


-- treats zero as positive
function commonMath.sign(n)
	return n < 0 and -1 or 1
end


-- 'a' is assumed to be <= 'b'
function commonMath.clamp(n, a, b) -- test
	return math.max(a, math.min(n, b))
end


return commonMath
