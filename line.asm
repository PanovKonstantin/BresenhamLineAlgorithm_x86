section .data
    pixel   dd 0
    mask    db 0
    width   dd 0
    x_diff  dd 0
    y_diff  dd 0
    x_side  db 1
    y_side  db 1
    error   dd 0

section .text
global _calculate_pix
global calculate_pix
global calculate_width
global _calculate_width
global _calculate_mask
global calculate_mask
global calculate_info
global _calculate_info
global test_1

_calculate_info:
calculate_info:
    push ebp
    mov ebp, esp

    call calculate_width
    call calculate_mask

;dx
    mov eax, [ebp+20]   ; x2
    mov ebx, [ebp+12]   ; x1
    cmp eax, ebx        ; if x1 > x2
    jae dx_end
    mov eax, [ebp+12]   ; x1
    mov ebx, [ebp+20]   ; x2
    mov [x_side], DWORD -1

dx_end:
    sub eax, ebx        ; |x2 - x1|
    mov [x_diff], eax   ; load in variable
    mov ebx, [ebp+8]    ; struct address
    mov [ebx+12], eax   ; load in struct
    mov [ebx+20], DWORD x_side

;dy
    mov eax, [ebp+16]   ; y1
    mov ebx, [ebp+24]   ; y2
    sub eax, ebx        ; y1 - y2
    mov [y_diff], eax   ; load in varibale
    mov ebx, [ebp+8]    ; struct address
    mov [ebx+16], eax   ; load in struct

    pop ebp
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

