section .data
    pixel   dd 0
    mask    dd 0
    width   dd 0
    x_diff  dd 0
    y_diff  dd 0
    x_side  dd 1
    y_side  dd 1
    error   dd 0
    x       dd 0
    y       dd 0
    x2      dd 0
    y2      dd 0
    start_pixel     dd 0
    width_in_pix    dd 0

section .text
global _draw_line
global draw_line
global test_1


_draw_line:
draw_line:
    push ebp
    mov ebp, esp

    call calculate_info

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
    mov ebx, [x_side]
    cmp ebx, 0
    jl draw_line_loop_x_dec
draw_line_loop_x_inc:
    mov ebx, [mask]
    ror bl, 1
    mov [mask], ebx
    mov ebx, [x]
    mov ecx, ebx
    inc ecx
    jmp draw_line_loop_x_end
draw_line_loop_x_dec:
    mov ebx, [mask]
    rol bl, 1
    mov [mask], ebx
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
    jg next_pix
    ; err += dx
    mov ecx, [error]
    add ecx, ebx
    mov [error], ecx
    mov eax, [y_side]
    mov ebx, [width]
    mov ecx, [pixel]
    mov edx, [y]
    cmp eax, 0
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
next_pix:
    jmp draw_line_loop_start
draw_line_loop_end:
    pop ebp
    ret

draw_pixel:
    mov edx, [pixel]    ;   Pixel address
    mov eax, [edx]      ;   Pixel
    mov ebx, [mask]     ;   Mask
    not ebx             ;   ~Mask
    and eax, ebx        ;   Pixel And ~Mask
    mov [edx], eax      ;   Load result in pixel address
    ret

calculate_info:

    mov eax, [ebp+12]
    mov [x], eax
    mov eax, [ebp+16]
    mov [y], eax
    mov eax, [ebp+20]
    mov [x2], eax
    mov eax, [ebp+24]
    mov [y2], eax
    mov edx, [ebp+8]
    mov eax, [edx+8]
    mov [start_pixel], eax
    mov eax, [edx]
    mov [width_in_pix], eax

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
    mov [x_side], DWORD 1
    cmp eax, ebx        ; if x1 > x2
    jge dx_end
    mov eax, [x]   ; x1
    mov ebx, [x2]   ; x2
    mov [x_side], DWORD -1
dx_end:
    sub eax, ebx        ; |x2 - x1|
    mov [x_diff], eax   ; load in variable

    ret

calculate_dy:
    mov eax, [y]   ; y1
    mov ebx, [y2]   ; y2
    mov [y_side], DWORD 1
    cmp eax, ebx        ; if y1 > y2
    jle dy_end
    mov eax, [y2]   ; y2
    mov ebx, [y]   ; y1
    mov [y_side], DWORD -1
dy_end:
    sub eax, ebx        ; -|y1 - y2|
    mov [y_diff], eax   ; load in variable

    ret

calculate_width:
    mov eax, [width_in_pix]      ; img width in pixels
    add eax, 31         ; width + 31
    shr eax, 5          ; (width +31) >> 5
    shl eax, 2          ; ((width + 31) >> 5 )) << 2
    mov [width], eax    ; store width in variable

    ret

calculate_mask:
    mov ecx, [x]
    mov ebx, 0x80
    and cl, 0x07
    shr ebx, cl
    mov [mask], ebx
    ret

calculate_pix:

    mov [pixel], dword 0
    mov eax, [width]
    mov ebx, [y]
    imul eax, ebx
    mov ebx, [start_pixel]
    add ebx, eax
    mov eax, [x]
    shr eax, 3
    add ebx, eax
    mov [pixel], ebx

    ret



test_1:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]    ; pixel adress
    mov ecx, [eax]      ; pixel adress
    mov ebx, [ebp+12]   ; mask
    not ebx             ; !mask
    and ecx, ebx        ; pixel adress AND !maks
    mov [eax], ecx      ; save adress
    pop ebp
    ret

