section .data
    pixel   dd 0
    mask    db 0
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

    pop ebp
    ret


_calculate_width:
calculate_width:
    mov eax, [ebp+8]    ; address of img information
    mov eax, [eax]      ; img width in pixels
    add eax, 31         ; width + 31
    shr eax, 5          ; (width +31) >> 5
    shl eax, 2          ; ((width + 31) >> 5 )) << 2
;    mov [width], eax    ; store width in variable
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
    mov [ebx+40], eax
    ret

_calculate_pix:
calculate_pix:

    push ebp
    mov ebp, esp
    mov eax, [ebp+12]
    mov ebx, [ebp+16]
    imul eax, ebx
    mov ebx, [ebp+8]
    add eax, ebp
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

