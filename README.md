# Vim Free Drag

This plugin enables the movement of *rectangular blocks* of text, selected
using Vim's *visual block mode*.
It was inspired by running this [this issue](https://github.com/zirrostig/vim-schlepp/issues/12#issuecomment-496709494)
with a similar plugin [vim-schlepp](https://github.com/zirrostig/vim-schlepp),
which was an adaptation of DragVisuals.vim.

## Movement Model

When a block of text moves in a particular direction, there is quite likely to
be a pre-existing row or column of text that is now covered by the text being
moved. This plugin moves text by _displacement_: Pre-existing text in the
direction of movement is used to fill the space that is left behind by the
moved text. Where there is no pre-existing text and the movement direction is
Right or Down, the plugin assumes whitespace. For example, consider the
following block of text. Suppose we selection the rectangular block 4710..

```
1234
5478
9102
```

Moving this block Up will move the line above it down to fill the gaps in the
row that was left behind on the bottom.

```
1474
5108
9232
```

Moving this block Down creates a new line and then moves the whitespace from
the newline into the row that was left behind on the top.
```
1234
5  8
9472
 10
```

Moving this block Left:
```
1234
4758
1092
```
Moving this block Right:
```
1234
5847
9210
```

## Installation

Simply clone this plugin into the plugin directory that is read by Vim8.

```
pushd  ~/.vim/pack/plugins/start
git clone https://github.com/hq6/VimFreeDrag.git
```

To actually use it, create mappings in your `~/.vimrc` for each direction of
dragging.

```
vmap <unique> K  <Plug>FreeDragUp
vmap <unique> J  <Plug>FreeDragDown
vmap <unique> H  <Plug>FreeDragLeft
vmap <unique> L  <Plug>FreeDragRight
```

Please create issues if you find scenarios where it does not work as expected
that are not described in the limitations below.

## Limitations
 * Works only with in Visual Block mode. It will detect and reject other visual
   modes.
 * This plugin has undefined behavior when the selection is non-rectangular;
   this can happen when using the `$` command in visual block mode.
