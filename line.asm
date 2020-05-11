section .data
    pixel   dd 0
    mask    db 0
    width   dd 0
    x_diff  dd 0
    y_diff  dd 0
    x_side  dd 1
    y_side  dd 1
    error   dd 0

section .text
global _draw_line
global draw_line
global _calculate_pix
global calculate_pix
global calculate_info
global _calculate_info
global test_1


_draw_line:
draw_line:
    push ebp
    mov ebp, esp
    mov ebx, [ebp+8]    ;   Argument
    mov ecx, [ebx+36]   ;   Pixel address
    mov [pixel], ecx    ;   Load pixel address in variable
    mov eax, [ecx]      ;   Pixel
    mov edx, [ebx+40]   ;   Mask
    not edx             ;   ~Mask
    and eax, edx        ;   Pixel And ~Mask
    mov [ecx], eax      ;   Load result in pixel address

    pop ebp
    ret


_calculate_info:
calculate_info:
    push ebp
    mov ebp, esp

    call calculate_width
    call calculate_mask
    mov edx, [ebp+8]    ; struct address
    call calculate_dx
    call calculate_dy

    mov eax, [x_diff]
    add eax, [y_diff]
    mov [error], eax
    mov [edx+28], eax


    pop ebp
    ret

calculate_dx:
    mov eax, [ebp+20]   ; x2
    mov ebx, [ebp+12]   ; x1
    mov [edx+20], DWORD 1
    cmp eax, ebx        ; if x1 > x2
    jae dx_end
    mov eax, [ebp+12]   ; x1
    mov ebx, [ebp+20]   ; x2
    mov [x_side], DWORD -1
    mov [edx+20], DWORD -1
dx_end:
    sub eax, ebx        ; |x2 - x1|
    mov [x_diff], eax   ; load in variable
    mov [edx+12], eax   ; load in struct

    ret

calculate_dy:
    mov eax, [ebp+16]   ; y1
    mov ebx, [ebp+24]   ; y2
    mov [edx+24], DWORD 1
    cmp eax, ebx        ; if y1 > y2
    jb dy_end
    mov eax, [ebp+24]   ; y2
    mov ebx, [ebp+16]   ; y1
    mov [x_side], DWORD -1
    mov [edx+24], DWORD -1

dy_end:
    sub eax, ebx        ; -|y1 - y2|
    mov [y_diff], eax   ; load in variable
    mov [edx+16], eax   ; load in struct

    ret

_calculate_width:
calculate_width:
    mov eax, [ebp+8]    ; address of img information
    mov eax, [eax]      ; img width in pixels
    add eax, 31         ; width + 31
    shr eax, 5          ; (width +31) >> 5
    shl eax, 2          ; ((width + 31) >> 5 )) << 2
    mov [width], eax    ; store width in variable
    mov ebx, [ebp+8]    ; address of img information
    mov [ebx+8], eax    ; store width in bytes as thirs field of img information

    ret

_calculate_mask:
calculate_mask:
    mov eax, 0x80
    mov ebx, [ebp+12]
    and ebx, 0x07
shift_mask:
    cmp ebx, 0
    jz shift_mask_end
    shr eax, 1
    dec ebx
    jmp shift_mask
shift_mask_end:
    mov ebx, [ebp+8]
    mov [mask], eax
    mov [ebx+40], eax
    ret

_calculate_pix:
calculate_pix:

    push ebp
    mov ebp, esp
    mov ebx, [ebp+12]
    mov ecx, [ebp+16]
    imul ebx, ecx
    mov eax, ebx
    mov ebx, [ebp+8]
    add eax, ebx
    mov ebx, [ebp+20]
    shr ebx, 3
    add eax, ebx
    mov [pixel], eax
    pop ebp
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

