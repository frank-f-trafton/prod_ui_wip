# Acknowledgements

## Libraries

* [inspect.lua](https://github.com/kikito/inspect.lua) is used for debugging.

* [nativefs](https://github.com/EngineerSmith/nativefs/tree/main) is used with the file selector example.

* strict.lua is used for testing.

* `prod_ui/lib/pack_bin.lua` is adapted from [packer.js](https://github.com/jakesgordon/bin-packing/blob/master/js/packer.js).




## Concepts

* The concept of widget event bubbling and trickling is taken from [LUIGI](http://airstruck.github.io/luigi/doc/classes/Widget.html#Widget:bubbleEvent).

* Some tree traversal code, including the function to get the "last" descendant in a tree, is taken from [LUIGI](https://github.com/airstruck/luigi/blob/gh-pages/luigi/widget.lua#L375).

* The stepper widget concept is taken from [LUIGI](http://airstruck.github.io/luigi/doc/widgets/stepper.html).

* The uiDraw canvas stack behavior is based on the opacity stack in [lwtk](https://github.com/osch/lua-lwtk/blob/master/src/lwtk/love/DrawContext.lua#L51C5-L51C5).

* Parts of the layout system are inspired by the `pack` command in [Tk](https://www.tcl.tk/).

* The text editing component takes some code, design cues and general inspiration from [InputField](https://github.com/ReFreezed/InputField/tree/master).

* General inspiration taken from [GOOi](https://github.com/gustavostuff/gooi), [urutora](https://github.com/gustavostuff/urutora), [Love Frames](https://github.com/linux-man/LoveFrames), [SLAB](https://github.com/flamendless/Slab), and the aforementioned [LUIGI](https://github.com/airstruck/luigi).


## Thanks

* Thanks to Pedro Gimeno for [this tip on premultiplied alpha](https://love2d.org/forums/viewtopic.php?p=254694#p254694).
