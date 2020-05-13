section .data
    pixel   dd 0
    mask    db 0
    width   dd 0
    x_diff  dd 0
    y_diff  dd 0
    x_side  db 1
    y_side  db 1
    error   dd 0
    x       dd 0
    y       dd 0
    x2      dd 0
    y2      dd 0

section .text
global _draw_line
global draw_line
global _horizontal_line
global horizontal_line
global _vertical_line
global vertical_line
global _single_pixel
global single_pixel

_single_pixel:
single_pixel:
    push ebp
    mov ebp, esp

    mov eax, [ebp+12]
    mov [x], eax
    mov eax, [ebp+16]
    mov [y], eax
    mov edx, [ebp+8]
    call calculate_width
    call calculate_pix
    call calculate_mask
    call draw_pixel


    pop ebp
    ret

_vertical_line:
vertical_line:
    push ebp
    mov ebp, esp

    mov eax, [ebp+12]
    mov [y], eax
    mov eax, [ebp+16]
    mov [y2], eax
    mov eax, [ebp+20]
    mov [x], eax
    mov edx, [ebp+8]
    call calculate_width
    call calculate_pix
    call calculate_mask

vertical_line_loop:
    call draw_pixel
    mov eax, [y]
    mov ebx, [y2]
    cmp eax, ebx
    jz vertical_line_loop_end
    mov ecx, [pixel]
    mov edx, [width]
    jg vertical_line_loop_dec
vertical_line_loope_inc:
    inc eax
    add ecx, edx
    jmp vertical_line_loop_next_pix
vertical_line_loop_dec:
    dec eax
    sub ecx, edx
vertical_line_loop_next_pix:
    mov [y], eax
    mov [pixel], ecx
    jmp vertical_line_loop
vertical_line_loop_end:
    pop ebp
    ret


_horizontal_line:
horizontal_line:
    push ebp
    mov ebp, esp

    mov eax, [ebp+12]
    mov [x], eax
    mov eax, [ebp+20]
    mov [y], eax
    mov eax, [ebp+16]
    mov [x2], eax
    mov edx, [ebp+8]
    call calculate_width
    call calculate_pix
    call calculate_mask

horizontal_line_loop:
    call draw_pixel
    mov eax, [x]
    mov ebx, [x2]
    cmp eax, ebx
    jz horizontal_line_loop_end
    jg horizontal_line_loop_dec
horizontal_line_loop_inc:
    mov bl, [mask]
    ror bl, 1
    mov [mask], bl
    mov ebx, [x]
    mov ecx, ebx
    inc ecx
    jmp horizontal_line_loop_next_pix
horizontal_line_loop_dec:
    mov bl, [mask]
    rol bl, 1
    mov [mask], bl
    mov ebx, [x]
    mov ecx, ebx
    dec ecx
horizontal_line_loop_next_pix:
    mov [x], ecx
    shr ebx, 3
    shr ecx, 3
    sub ecx, ebx
    mov ebx, [pixel]
    add ebx, ecx
    mov [pixel], ebx
    jmp horizontal_line_loop
horizontal_line_loop_end:
    pop ebp
    ret

_draw_line:
draw_line:
    push ebp
    mov ebp, esp
    call calculate_full_info
draw_line_loop_start:
    call draw_pixel
; if x == x2 and y == y2, break
draw_line_loop_break_condition_1:
    mov eax, [x]
    mov ebx, [x2]
    cmp eax, ebx
    jnz draw_line_loop_x_cond
draw_line_loop_break_condition_2:
    mov eax, [y]
    mov ebx, [y2]
    cmp eax, ebx
    jz draw_line_loop_end
draw_line_loop_x_cond:
    ; e2 in eax
    mov eax, [error]
    shl eax, 1
    mov ebx, [y_diff]
    cmp eax, ebx
    jl draw_line_loop_y_cond
    ; err += dx
    mov ecx, [error]
    add ecx, ebx
    mov [error], ecx
    ; x++ / x--
    mov bl, [x_side]
    cmp bl, 0
    jl draw_line_loop_x_dec
draw_line_loop_x_inc:
    mov bl, [mask]
    ror bl, 1
    mov [mask], bl
    mov ebx, [x]
    mov ecx, ebx
    inc ecx
    jmp draw_line_loop_x_end
draw_line_loop_x_dec:
    mov bl, [mask]
    rol bl, 1
    mov [mask], bl
    mov ebx, [x]
    mov ecx, ebx
    dec ecx
draw_line_loop_x_end:
    mov [x], ecx
    shr ebx, 3
    shr ecx, 3
    sub ecx, ebx
    mov ebx, [pixel]
    add ebx, ecx
    mov [pixel], ebx
draw_line_loop_y_cond:
    mov ebx, [x_diff]
    cmp eax, ebx
    jg draw_line_loop_next_pix
    ; err += dx
    mov ecx, [error]
    add ecx, ebx
    mov [error], ecx
    mov al, [y_side]
    mov ebx, [width]
    mov ecx, [pixel]
    mov edx, [y]
    cmp al, 0
    jl draw_line_loop_y_dec
draw_line_loop_y_inc:
    add ecx, ebx
    inc edx
    jmp draw_line_loop_y_end
draw_line_loop_y_dec:
    sub ecx, ebx
    dec edx
draw_line_loop_y_end:
    mov [pixel], ecx
    mov [y], edx
draw_line_loop_next_pix:
    jmp draw_line_loop_start
draw_line_loop_end:
    pop ebp
    ret

draw_pixel:
    mov edx, [pixel]    ;   Pixel address
    mov eax, [edx]      ;   Pixel
    mov bl, [mask]     ;   Mask
    and al, bl        ;   Pixel And Mask
    mov [edx], eax      ;   Load result in pixel address
    ret

calculate_full_info:

    mov eax, [ebp+12]
    mov [x], eax
    mov eax, [ebp+16]
    mov [y], eax
    mov eax, [ebp+20]
    mov [x2], eax
    mov eax, [ebp+24]
    mov [y2], eax
    mov edx, [ebp+8]
    call calculate_width
    call calculate_pix
    call calculate_mask
    call calculate_dx
    call calculate_dy
    mov eax, [x_diff]
    add eax, [y_diff]
    mov [error], eax
    mov eax, [width]
    ret

calculate_dx:
    mov eax, [x2]   ; x2
    mov ebx, [x]   ; x1
    mov [x_side], BYTE 1
    cmp eax, ebx        ; if x1 > x2
    jge dx_end
    mov eax, [x]   ; x1
    mov ebx, [x2]   ; x2
    mov [x_side], BYTE -1
dx_end:
    sub eax, ebx        ; |x2 - x1|
    mov [x_diff], eax   ; load in variable
    ret

calculate_dy:
    mov eax, [y]   ; y1
    mov ebx, [y2]   ; y2
    mov [y_side], BYTE 1
    cmp eax, ebx        ; if y1 > y2
    jle dy_end
    mov eax, [y2]   ; y2
    mov ebx, [y]   ; y1
    mov [y_side], BYTE -1
dy_end:
    sub eax, ebx        ; -|y1 - y2|
    mov [y_diff], eax   ; load in variable
    ret

calculate_width:
    mov eax, [edx]      ; img width in pixels
    add eax, 31         ; width + 31
    shr eax, 5          ; (width +31) >> 5
    shl eax, 2          ; ((width + 31) >> 5 )) << 2
    mov [width], eax    ; store width in variable

    ret

calculate_mask:
    mov ecx, [x]
    mov bl, 0x7F    ;   01111111
    and cl, 0x07    ;   x mod 8
    ror bl, cl      ;   01111111 >> (x mod 8)
    mov [mask], bl
    ret

calculate_pix:
    mov eax, [width]
    mov ebx, [y]
    imul eax, ebx
    mov ebx, [edx+8]    ; start pixel address
    add ebx, eax
    mov eax, [x]
    shr eax, 3
    add ebx, eax
    mov [pixel], ebx
    ret


