local commonImage = {}


function commonImage.imageSet(self, image, quad)
	self.image = image
	self.image_w, self.image_h = image:getDimensions()

	self.quad = quad
	if quad then
		local _x, _y
		_x, _y, self.quad_w, self.quad_h = quad:getViewport()
	else
		self.quad_w = nil
		self.quad_h = nil
	end
end


function commonImage.imageAlignHorizontal(self, align_h)
	local graphic_w
	if self.quad then
		graphic_w = self.quad_w
	else
		graphic_w = self.image_w
	end

	if align_h == "left" then
		return self.x

	elseif align_h == "center" then
		return self.x - graphic_w/2 + self.w/2

	elseif align_h == "right" then
		return self.x + self.w - graphic_w
	end
end


function commonImage.imageAlignVertical(self, align_v)
	local graphic_h
	if self.quad then
		graphic_h = self.quad_h
	else
		graphic_h = self.image_h
	end

	if align_v == "top" then
		return self.y

	elseif align_v == "middle" then
		return self.y - graphic_h/2 + self.h/2

	elseif align_v == "bottom" then
		return self.y + self.h - graphic_h
	end
end


function commonImage.imageRemove(self)
	self.image = nil
	self.image_w = nil
	self.image_h = nil
	self.quad = nil
	self.quad_w = nil
	self.quad_h = nil
end


return commonImage
