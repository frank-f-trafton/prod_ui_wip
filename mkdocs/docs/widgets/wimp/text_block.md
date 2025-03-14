# wimp/text_block

A skinned block of text. This widget can automatically resize along the horizontal or vertical axis as part of its reshaping mechanism.

TextBlocks are good for titles, headings, and short paragraphs that don't change often. They are not suitable for text that updates on every frame.

Changes to a TextBlock's font, text and alignment will not fully take effect until the widget is reshaped.

TextBlocks do not support [LÖVE coloredtext](https://love2d.org/wiki/love.graphics.print) sequences.


## API


### TextBlock:setFontID

Sets the font ID.

`TextBlock:setFontID(id)`

* `id`: (string) The font ID.


### TextBlock:getFontID

Gets the font ID.

`local font_id = TextBlock:getFontID()`

**Returns:** The font ID.


### TextBlock:setText

Sets the text.

`TextBlock:setText(text)`

* `text`: The new text string.


### TextBlock:getText

Gets the current text.

`local text = TextBlock:getText()`

**Returns:** The current text.


### TextBlock:setURL

Sets a URL, and configures the Text Block to be pressable (or not, if the URL is being removed).

`TextBlock:setURL(url)`

* `url`: The URL string, to be activated upon pressing, or false/nil to remove the URL.


#### Notes

User events `wid_buttonAction` (left click, enter key, space key) and `wid_buttonAction3` (middle click) are assigned a default function which attempts to open the TextBlock's URL with [love.system.openURL()](https://love2d.org/wiki/love.system.openURL). This function can be replaced to provide more functionality, like in-program navigation.


### TextBlock:getURL

Gets the current URL.

`local url = TextBlock:getURL()`

**Returns:** The URL string, or false if there is no string set.


### TextBlock:setAlign

Sets the text alignment.

`TextBlock:setAlign(align)`

* `align`: ([LÖVE AlignMode](https://love2d.org/wiki/AlignMode)) The text alignment.


### TextBlock:getAlign

Gets the text alignment.

`local align = TextBlock:getAlign()`

**Returns:** The text alignment.


### TextBlock:setVerticalAlign

Sets the text's vertical alignment.

`TextBlock:setVerticalAlign(v)`

* `v`: (number) The vertical alignment, from 0.0 (top) to 1.0 (bottom).


### TextBlock:getVerticalAlign

Gets the text's vertical alignment.

`local v = TextBlock:getVerticalAlign()`

**Returns:** The text's vertical alignment.


### TextBlock:setAutoSize

Sets or clears the widget's automatic size mode.

`TextBlock:setAutoSize(mode)`

* `mode`: "h" for horizontal mode, "v" for vertical mode, false/nil to disable.


### TextBlock:getAutoSize

Gets the widget's automatic size mode.

`local mode = TextBlock:getAutoSize`

**Returns:** The automatic size mode ("h", "v" or boolean false).


### TextBlock:setWrapping

Sets the widget's text wrapping mode.

`TextBlock:setWrapping(enabled)`

* `enabled`: (boolean) True to wrap text, false to allow it to exceed the widget's horizontal boundaries.


### TextBlock:getWrapping

Gets the widget's text wrapping mode.

`local enabled = TextBlock:getWrapping()`

**Returns:** true or false.


## Information

### Font IDs

Font IDs are determined by the widget skin. The default IDs are:

* `h1`
* `h2`
* `h3`
* `h4`
* `p` (paragraph)
* `small`