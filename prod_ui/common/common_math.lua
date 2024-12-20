local commonMath = {}


-- treats zero as positive
function commonMath.sign(n)
	return n < 0 and -1 or 1
end


-- 'a' is assumed to be <= 'b'
function commonMath.clamp(n, a, b) -- test
	return math.max(a, math.min(n, b))
end


function commonMath.pointInRect(px, py, x1, y1, x2, y2)
	return px >= x1 and py >= y1 and px < x2 and py < y2
end


--- Gets the linear interpolation of a point between two values.
-- For example, coord.interpolate(0, 20, 0.5) will return 10.
-- @param a First value
-- @param b Second value
-- @param point The input value, between 0.0 and 1.0
-- @return The interpolated value
function commonMath.lerp(a, b, point)
	return (1 - point) * a + point * b
end


return commonMath
