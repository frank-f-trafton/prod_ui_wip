local intersect = {}

function intersect.pointToRect(px, py, x1, y1, x2, y2)
	return px >= x1 and py >= y1 and px < x2 and py < y2
end

--- Get the linear interpolation of a point between two values.
-- For example, coord.interpolate(0, 20, 0.5) will return 10.
-- @param a First value
-- @param b Second value
-- @param point The input value, between 0.0 and 1.0
-- @return The interpolated value
function intersect.lerp(a, b, point)
	return (1 - point) * a + point * b
end

return intersect
