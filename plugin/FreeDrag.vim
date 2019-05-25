" This function is intended to allow free dragging of visual-block selected
" regions without impacting any characters that are not in the direction of
" move.

" The following algorithm is implemented.
"     1. Implement a separate function for each direction, since one giant
"        function will just have four branches. The following will be roughly
"        symmetric for each function.
"     2. Save two registers (a,b) in local variables; remember to restore them
"        when the function is done.
"     3. Get the bounding box on the visual selection using virtcol and
"        line.
"     4. Yank the selection into register a.
"     5. Depending on the direction, visually select the vertical or horizontal
"        strip on the correct side of the bounding box (left side for move left,
"        etc) and yank it into register b.
"         * If we're moving left at the left edge or up at the top edge,
"           terminate immediately (and re-select the region).
"         * If we're moving right or down at the respective edges, then create
"           the edge with spaces by using visual block mode append or a new line.
"     6. Visually block select a region equal in size to the region being moved,
"        except shifted one column or row in the correct direction.
"     7. Paste from register a to replace the region.
"     8. Visual block select the strip so the opposite direction from that which
"        was moved, and paste from register b.
"     9. Restore registers a and b.

" Takes the contents of a visual selection as an argument and determines
" whether it is rectangular by checking if each row contains the same number
" of columns.
function s:isDollarBlock(block)
 let l:len = -1
 for x in split(a:block, "\n")
    " echom x."ending"
    " echom strlen(x)
    if l:len == -1
       let l:len = strlen(x)
    endif
    if l:len != strlen(x)
       return 1
    endif
 endfor
 return 0
endfunction

" Finds the rightmost column among the lines from row0 to row1
function s:getRightMostColumn(row0, row1)
  let row = a:row0
  let rightMostColumn = 0
  while row <= a:row1
     let rowLength = strlen(getline(row))
     if rowLength > rightMostColumn
        let rightMostColumn = rowLength
     endif
     let row+=1
  endwhile
  return rightMostColumn
endfunction

" This helper function performs the meat of the work, and allows convenient
" control flow.
function FreeDrag#DragHelper(dir)
    " Grab the topleft and bottomright corner of the visual selection
    " It is assumed that (col0,row0) is always the top left corner, even if
    " the selection is performed from bottom right towards the top left. This
    " seems to be true empirically.
	let col0   = virtcol("'<")
	let row0   = line("'<")
	let col1   = virtcol("'>")
	let row1   = line("'>")

	" echom col0 row0 col1 row1

    " Yank the contents into register a
    " Note that we need to reselect the region because we exited visual mode
    " when this function was called.
    silent normal! gv"ay

    " If the region is non-rectangular, then compute col1 as the rightmost
    " column using the longest line in the selected region
    let isDollarBlock = s:isDollarBlock(@a)
    if isDollarBlock
        let col1 = s:getRightMostColumn(row0,row1)
    endif
    echom col1

    " This is set after the IsDollarBlock check because otherwise register a
    " contains padded lines, making it impossible to non-rectangular regions
    " by counting lines.
    set virtualedit=all

    let width=col1-col0+1
    let height=row1-row0+1

    if a:dir == "up"
        " Abort if we can't go up anymore
        if row0 == 1
           " Restore the selection before aborting
           normal gv
           return
        endif

        " Grab characters immediately above the current selection and put them
        " into register b
        call cursor(row0-1, col0)
        execute "normal! \"by".width."l"

        " Select the block that we are replacing and paste from register a
        call cursor(row0-1, col0)
        execute "normal! \<C-V>"
        call cursor(row1-1, col1)
        normal! "ap

        " Put the characters above the current selection on the row that we
        " just abandoned
        call cursor(row1, col0)
        execute "normal! \<C-V>"
        call cursor(row1, col1)
        normal! "bp

        " Reselect the block that was moved
        call cursor(row0-1, col0)
        execute "normal! \<C-V>"
        call cursor(row1-1, col1)

    elseif a:dir == "down"
        " Check for EOF, since virtualedit does not allow the cursor to go down past the
        " end of the line.
        if row1 == line('$')
            call append(line('$'), '')
        endif

        " Grab characters immediately below the current selection and put them
        " into register b
        call cursor(row1+1, col0)
        execute "normal! \"by".width."l"

        " Select the block that we are replacing and paste from register a
        call cursor(row0+1, col0)
        execute "normal! \<C-V>"
        call cursor(row1+1, col1)
        normal "ap

        " Put the characters below the current selection on the row that we
        " just abandoned
        call cursor(row0, col0)
        execute "normal! \<C-V>"
        call cursor(row0, col1)
        normal "bp

        " Reselect the block that was moved
        call cursor(row0+1, col0)
        execute "normal! \<C-V>"
        call cursor(row1+1, col1)

    elseif a:dir == "left"
        " Abort if we can't go left anymore
        if col0 == 1
           " Restore the selection before aborting
           normal gv
           return
        endif

        " Grab characters immediately to the left of the current selection and
        " put them into register b
        call cursor(row0, col0 - 1)
        execute "normal! \<C-V>"
        call cursor(row1, col0 - 1)
        normal "by

        " Select the block that we are replacing and paste from register a
        call cursor(row0, col0-1)
        execute "normal! \<C-V>"
        call cursor(row1, col1-1)
        normal "ap

        " Put the characters to the right of the current selection on the
        " column that we just abandoned
        call cursor(row0, col1)
        execute "normal! \<C-V>"
        call cursor(row1, col1)
        normal "bp

        " Reselect the block that was moved
        call cursor(row0, col0-1)
        execute "normal! \<C-V>"
        call cursor(row1, col1-1)

    elseif a:dir == "right"
        " Grab characters immediately to the right of the current selection and
        " put them into register b
        call cursor(row0, col1 + 1)
        execute "normal! \<C-V>"
        call cursor(row1, col1 + 1)
        normal "by

        " Select the block that we are replacing and paste from register a
        call cursor(row0, col0+1)
        execute "normal! \<C-V>"
        call cursor(row1, col1+1)
        normal "ap

        " Put the characters to the left of the current selection on the
        " column that we just abandoned
        call cursor(row0, col0)
        execute "normal! \<C-V>"
        call cursor(row1, col0)
        normal "bp

        " Reselect the block that was moved
        call cursor(row0, col0 + 1)
        execute "normal! \<C-V>"
        call cursor(row1, col1 + 1)
    endif

    " Restore dollar selection if that was in place before.
    " Without special case for isDollarBlock, then we lose the protruding part
    " of the dollar selection if virtualedit was not originally unabled by the
    " user.
    if isDollarBlock
        normal $
    endif

    " Remove trailing whitespace
	for l:linenum in range(row0-1, row1+1)
		call setline(l:linenum, substitute(getline(l:linenum), "\\s\\+$", '', ''))
	endfor

endfunction

function FreeDrag#Drag(dir)
    " Only allow function in virtual block mode
    if visualmode() != "\<C-V>"
       echom "FreeDrag only works in Visual Block Mode!"
       normal gv
       return
    endif

    " Save the registers we will use as scratch registers
    let l:saved_a=@a
    let l:saved_b=@b

    " Save the setting of virtualedit so that we can restore it after we're done
    let l:saved_virtualedit=&virtualedit

    " Doing the bulk of the work in a different function helps us make sure
    " cleanup happens even if the function fails.
    call FreeDrag#DragHelper(a:dir)

    " Restore the setting of virtualedit
    let &virtualedit=l:saved_virtualedit

    " Restore the registers we will use as scratch registers
    let @a = l:saved_a
    let @b = l:saved_b
endfunction

" Export global names for user to map.
vnoremap <silent><script> <Plug>FreeDragUp
    \ :<C-U>call FreeDrag#Drag("up")<CR>

vnoremap <silent><script> <Plug>FreeDragDown
    \ :<C-U>call FreeDrag#Drag("down")<CR>

vnoremap <silent><script> <Plug>FreeDragLeft
    \ :<C-U>call FreeDrag#Drag("left")<CR>

vnoremap <silent><script> <Plug>FreeDragRight
    \ :<C-U>call FreeDrag#Drag("right")<CR>
