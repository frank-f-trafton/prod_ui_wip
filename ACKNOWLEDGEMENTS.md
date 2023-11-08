# Acknowledgements

## Libraries

* [inspect.lua](https://github.com/kikito/inspect.lua) is used for debugging.

* [nativefs](https://github.com/EngineerSmith/nativefs/tree/main) is used in the theme building script, and also in the file selector example.

* strict.lua is used for testing.

* `prod_ui/lib/pack_bin.lua` is adapted from [packer.js](https://github.com/jakesgordon/bin-packing/blob/master/js/packer.js). The packing algorithm is also used in AtlasB, a dependency of the theme builder.

* The theme builder's table serialization library uses parts from [Serpent](https://github.com/pkulchenko/serpent).

* The text editing component takes some code (UTF-8 iteration and string sanitizing, if I recall correctly), feature ideas and general inspiration from [InputField](https://github.com/ReFreezed/InputField/tree/master).


## Concepts

* The concept of widget event bubbling and trickling is taken from [LUIGI](http://airstruck.github.io/luigi/doc/classes/Widget.html#Widget:bubbleEvent).

* Some tree traversal code, including the function to get the "last" descendant in a tree, is taken from [LUIGI](https://github.com/airstruck/luigi/blob/gh-pages/luigi/widget.lua#L375).

* The stepper widget concept is taken from [LUIGI](http://airstruck.github.io/luigi/doc/widgets/stepper.html).

* The uiDraw canvas stack behavior is based on the opacity stack in [lwtk](https://github.com/osch/lua-lwtk/blob/master/src/lwtk/love/DrawContext.lua#L51C5-L51C5).

* Parts of the layout system are inspired by the `pack` command in [Tk](https://www.tcl.tk/).

* General inspiration taken from [GOOi](https://github.com/gustavostuff/gooi), [urutora](https://github.com/gustavostuff/urutora), [Love Frames](https://github.com/linux-man/LoveFrames), [SLAB](https://github.com/flamendless/Slab), and the aforementioned [LUIGI](https://github.com/airstruck/luigi).


## Thanks

* Thanks to Pedro Gimeno for [this tip on premultiplied alpha](https://love2d.org/forums/viewtopic.php?p=254694#p254694).
