;==============================================================================
; SYSTEM UTILITIES SUITE v3.0 - Linux x64 NASM
; Build:
;   nasm -f elf64 sysutils.asm -o sysutils.o
;   nasm -f elf64 sysutils.asm -o sysutils.o && ld sysutils.o -o sysutils && ./sysutils
;   ./sysutils
;
; Features:
;   1. System Information  — CPUID brand string, topology, cache, flags + /proc/meminfo
;   2. Stopwatch / Timer   — live tick display, raw terminal mode + poll
;   3. Scientific Calculator — +  -  *  /  and base conversion (bin/oct/hex)
;   4. Memory Viewer        — 256-byte hex dump of program's own .text
;   5. CPU Performance Test — scalar ADD, SSE ADDPS, AVX VADDPS + RDTSC GHz
;   6. Group Members        — project team
;==============================================================================

; ── Syscall numbers ──────────────────────────────────────────────────────────
%define SYS_READ          0
%define SYS_WRITE         1
%define SYS_OPEN          2
%define SYS_CLOSE         3
%define SYS_POLL          7
%define SYS_IOCTL         16
%define SYS_NANOSLEEP     35
%define SYS_CLOCK_GETTIME 228
%define SYS_EXIT          60

%define STDIN             0
%define STDOUT            1
%define CLOCK_MONOTONIC   1

; ── Terminal / poll ──────────────────────────────────────────────────────────
%define TCGETS            0x5401
%define TCSETS            0x5402
%define ICANON            0x2
%define ECHO              0x8
%define POLLIN            0x1

; ── Timespec offsets ─────────────────────────────────────────────────────────
%define TS_SEC            0
%define TS_NSEC           8

; ── ANSI colour macros ───────────────────────────────────────────────────────
; ESC = 0x1B
%define ESC               27

;==============================================================================
section .data
;==============================================================================

; ────────────────────────────────────────────────────────────────────────────
; ANSI escape sequences
; ────────────────────────────────────────────────────────────────────────────
COL_RESET   db ESC, "[0m", 0
COL_BOLD    db ESC, "[1m", 0
COL_CYAN    db ESC, "[1;36m", 0        ; bold cyan   — headers / boxes
COL_GREEN   db ESC, "[1;32m", 0        ; bold green  — labels / prompts
COL_YELLOW  db ESC, "[1;33m", 0        ; bold yellow — values / results
COL_RED     db ESC, "[1;31m", 0        ; bold red    — errors
COL_MAGENTA db ESC, "[1;35m", 0        ; bold magenta — menu numbers
COL_WHITE   db ESC, "[1;37m", 0        ; bold white  — menu text
COL_DIM     db ESC, "[2m", 0           ; dim         — separators

; ────────────────────────────────────────────────────────────────────────────
; Title / Menu
; ────────────────────────────────────────────────────────────────────────────
title_msg:
    db ESC, "[1;36m"   ; bold cyan
    db 10
    db "  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓", 10
    db "  ┃", ESC, "[1;37m"
    db "          S Y S T E M   U T I L I T I E S   S U I T E          "
    db ESC, "[1;36m", "┃", 10
    db "  ┃", ESC, "[2;37m"
    db "                    Linux x64  ·  NASM  v3.0                   "
    db ESC, "[1;36m", "┃", 10
    db "  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    db ESC, "[0m", 10, 0

menu_msg:
    db 10
    db ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "                      M A I N   M E N U                         ", ESC, "[1;36m", "│", 10
    db "  ├──────────────────────────────────────────────────────────────────┤", 10
    db "  │  ", ESC, "[1;35m", "1", ESC, "[1;37m", ".  System Information                                        ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;35m", "2", ESC, "[1;37m", ".  Stopwatch / Timer                                         ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;35m", "3", ESC, "[1;37m", ".  Scientific Calculator                                     ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;35m", "4", ESC, "[1;37m", ".  Memory Viewer                                             ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;35m", "5", ESC, "[1;37m", ".  CPU Performance Test                                      ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;35m", "6", ESC, "[1;37m", ".  Group Members                                             ", ESC, "[1;36m", "│", 10
    db "  │  ", ESC, "[1;31m", "0", ESC, "[1;37m", ".  Exit                                                      ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘", 10
    db ESC, "[0m"
    db "  ", ESC, "[1;32m", "Choice: ", ESC, "[1;33m", 0

invalid_msg:
    db ESC, "[0m", 10
    db ESC, "[1;31m", "  [!] Invalid choice — please enter a number 0–6.", ESC, "[0m", 10, 0

goodbye_msg:
    db 10
    db ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "       Thank you for using System Utilities Suite!              ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

; ────────────────────────────────────────────────────────────────────────────
; Section header macro (reused per feature)
; ────────────────────────────────────────────────────────────────────────────
hdr_sysinfo:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "                    S Y S T E M   I N F O                       ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

hdr_stopwatch:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "                S T O P W A T C H   /   T I M E R               ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

hdr_calc:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "            S C I E N T I F I C   C A L C U L A T O R           ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

hdr_memview:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "                  M E M O R Y   V I E W E R                     ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

hdr_perf:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "            C P U   P E R F O R M A N C E   T E S T             ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 1 — System Info (CPUID + /proc/meminfo)
; ────────────────────────────────────────────────────────────────────────────
; CPUID labels
lbl_cpuid_hdr   db ESC, "[2m", "  ── CPUID (direct hardware query) ─────────────────────────────", ESC, "[0m", 10, 0
lbl_brand       db ESC, "[1;32m", "  CPU Brand   : ", ESC, "[1;33m", 0
lbl_vendor      db ESC, "[1;32m", "  Vendor ID   : ", ESC, "[1;33m", 0
lbl_family      db ESC, "[1;32m", "  Family      : ", ESC, "[1;33m", 0
lbl_model_id    db ESC, "[1;32m", "  Model       : ", ESC, "[1;33m", 0
lbl_stepping    db ESC, "[1;32m", "  Stepping    : ", ESC, "[1;33m", 0
lbl_logcores    db ESC, "[1;32m", "  Log. Cores  : ", ESC, "[1;33m", 0
lbl_physcores   db ESC, "[1;32m", "  Phys.Cores  : ", ESC, "[1;33m", 0
lbl_cache_hdr   db ESC, "[2m", "  ── Cache ─────────────────────────────────────────────────────", ESC, "[0m", 10, 0
lbl_l1d         db ESC, "[1;32m", "  L1 D-Cache  : ", ESC, "[1;33m", 0
lbl_l1i         db ESC, "[1;32m", "  L1 I-Cache  : ", ESC, "[1;33m", 0
lbl_l2          db ESC, "[1;32m", "  L2 Cache    : ", ESC, "[1;33m", 0
lbl_l3          db ESC, "[1;32m", "  L3 Cache    : ", ESC, "[1;33m", 0
lbl_flags_hdr   db ESC, "[2m", "  ── Key CPU Flags ─────────────────────────────────────────────", ESC, "[0m", 10, 0
lbl_mem_hdr     db ESC, "[2m", "  ── Memory (/proc/meminfo) ────────────────────────────────────", ESC, "[0m", 10, 0
lbl_memtotal    db ESC, "[1;32m", "  Mem Total   : ", ESC, "[1;33m", 0
lbl_memavail    db ESC, "[1;32m", "  Mem Free    : ", ESC, "[1;33m", 0

str_kb          db ESC, "[0m", " kB", 10, 0
str_nl          db ESC, "[0m", 10, 0
str_kb_plain    db " kB", 10, 0

; flag strings
str_flag_sse2   db ESC, "[1;32m", "  SSE2 ", 0
str_flag_sse4   db ESC, "[1;32m", "  SSE4.1 ", 0
str_flag_avx    db ESC, "[1;32m", "  AVX ", 0
str_flag_avx2   db ESC, "[1;32m", "  AVX2 ", 0
str_flag_avx512 db ESC, "[1;32m", "  AVX-512 ", 0
str_flag_aes    db ESC, "[1;32m", "  AES-NI ", 0
str_flag_rdrand db ESC, "[1;32m", "  RDRAND ", 0
str_flag_sep    db ESC, "[2m", " │ ", ESC, "[0m", 0
str_flags_end   db 10, 0
str_kb_size     db " KB", 10, 0
str_dash_val    db ESC, "[2m", "  (not reported)", ESC, "[0m", 10, 0
str_ways        db "-way, line=", 0
str_bytes       db "B", 10, 0

; /proc paths + tokens
meminfo_path    db "/proc/meminfo", 0
token_memtotal  db "MemTotal:", 0
token_memavail  db "MemAvailable:", 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 2 — Stopwatch
; ────────────────────────────────────────────────────────────────────────────
sw_start_prompt db ESC, "[1;32m", "  Press [Enter] to START...", ESC, "[0m", 0
sw_running      db ESC, "[1;32m", "  Running — press [Enter] to STOP", ESC, "[0m", 10, 0
sw_tick_pfx     db 13, ESC, "[1;33m", "  ⏱  ", ESC, "[1;37m", 0
sw_tick_sep     db ESC, "[2m", ".", ESC, "[0m", 0
sw_tick_sfx     db ESC, "[1;32m", " s   ", ESC, "[0m", 0
sw_final_pfx    db 10, ESC, "[1;32m", "  Elapsed : ", ESC, "[1;33m", 0
sw_final_sep    db ESC, "[2m", ".", ESC, "[0m", 0
sw_final_sfx    db ESC, "[1;32m", " seconds", ESC, "[0m", 10, 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 3 — Calculator
; ────────────────────────────────────────────────────────────────────────────
calc_p1         db ESC, "[1;32m", "  First operand      : ", ESC, "[1;33m", 0
calc_pop        db ESC, "[1;32m", "  Operator (+,-,*,/) : ", ESC, "[1;33m", 0
calc_p2         db ESC, "[1;32m", "  Second operand     : ", ESC, "[1;33m", 0
calc_result     db 10, ESC, "[1;32m", "  Result : ", ESC, "[1;33m", 0
calc_nl         db ESC, "[0m", 10, 0
calc_err_zero   db 10, ESC, "[1;31m", "  [!] Division by zero!", ESC, "[0m", 10, 0
calc_err_op     db 10, ESC, "[1;31m", "  [!] Unknown operator.", ESC, "[0m", 10, 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 4 — Memory Viewer
; ────────────────────────────────────────────────────────────────────────────
mv_col_hdr:
    db ESC, "[2m"
    db "  Address            +0 +1 +2 +3 +4 +5 +6 +7   +8 +9 +A +B +C +D +E +F", 10
    db "  ───────────────────────────────────────────────────────────────────────", 10
    db ESC, "[0m", 0
mv_row_prefix   db "  ", 0
mv_col_sep      db "   ", 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 5 — CPU Perf Test
; ────────────────────────────────────────────────────────────────────────────
perf_intro:
    db ESC, "[2m", "  Measuring using RDTSC (hardware cycle counter) + clock_gettime", ESC, "[0m", 10
    db ESC, "[2m", "  Each test runs for 1 second. Higher = better.", ESC, "[0m", 10, 10, 0
perf_scalar_lbl db ESC, "[1;32m", "  [1] Scalar  ADD (64-bit)  : ", ESC, "[1;33m", 0
perf_sse_lbl    db ESC, "[1;32m", "  [2] SSE     ADDPS (4×f32) : ", ESC, "[1;33m", 0
perf_avx_lbl    db ESC, "[1;32m", "  [3] AVX     ADDPS (8×f32) : ", ESC, "[1;33m", 0
perf_mops       db ESC, "[2m", " Mop/s  ", ESC, "[0m", 0
perf_ghz_pfx    db ESC, "[2m", "  CPU approx. ", ESC, "[1;33m", 0
perf_ghz_sfx    db ESC, "[2m", " GHz (RDTSC cycles / wall time)", ESC, "[0m", 10, 0
perf_rdtsc_note db ESC, "[2m", "  Computing CPU frequency via RDTSC...", ESC, "[0m", 10, 0
perf_dot        db ".", 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 6 — Group Members
; ────────────────────────────────────────────────────────────────────────────
hdr_group:
    db 10, ESC, "[1;36m"
    db "  ┌──────────────────────────────────────────────────────────────────┐", 10
    db "  │", ESC, "[1;37m", "                    G R O U P   M E M B E R S                   ", ESC, "[1;36m", "│", 10
    db "  └──────────────────────────────────────────────────────────────────┘"
    db ESC, "[0m", 10, 0

group_members:
    db "  ", ESC, "[1;33m", "1. ", ESC, "[1;31m", "Joseph George Wahba", ESC, "[0m", 10
    db "  ", ESC, "[1;33m", "2. ", ESC, "[1;37m", "Menna-Allah Ahmed",   ESC, "[0m", 10
    db "  ", ESC, "[1;33m", "3. ", ESC, "[1;37m", "Abdelhalim Ramadan",  ESC, "[0m", 10
    db "  ", ESC, "[1;33m", "4. ", ESC, "[1;37m", "Zeyad Muhamed Yehya", ESC, "[0m", 10
    db 0

; ────────────────────────────────────────────────────────────────────────────
; Feature 3 extras — Base conversion
; ────────────────────────────────────────────────────────────────────────────
calc_conv_prompt  db ESC, "[1;32m", "  Enter number to convert : ", ESC, "[1;33m", 0
calc_conv_op      db ESC, "[1;32m", "  Convert to (b=Binary, o=Octal, h=Hex) : ", ESC, "[1;33m", 0
calc_bin_pfx      db 10, ESC, "[1;32m", "  Binary  : ", ESC, "[1;33m", 0
calc_oct_pfx      db 10, ESC, "[1;32m", "  Octal   : ", ESC, "[1;33m", 0
calc_hex_pfx      db 10, ESC, "[1;32m", "  Hex     : ", ESC, "[1;33m", "0x", 0
calc_conv_nl      db ESC, "[0m", 10, 0
calc_err_conv     db 10, ESC, "[1;31m", "  [!] Unknown conversion. Use b, o, or h.", ESC, "[0m", 10, 0

; updated operator prompt now mentions conversion too
calc_op_prompt    db ESC, "[1;32m", "  Op (+  -  *  /  b  o  h) : ", ESC, "[1;33m", 0
hex_chars       db "0123456789ABCDEF"
newline         db 10, 0
str_dash        db "-", 0
str_space       db " ", 0

;==============================================================================
section .bss
;==============================================================================
input_buf       resb 256
meminfo_buf     resb 2048
num_buf         resb 64
ts_start        resb 16
ts_stop         resb 16
ts_tick         resb 16
hex_buf         resb 64
calc_op1        resq 1
calc_opchar     resb 1
conv_buf        resb 68         ; binary string: up to 64 digits + "0b" prefix + NUL
termios_old     resb 64
termios_new     resb 64
poll_fds        resb 8
; CPUID brand string: 3 leaves × 16 bytes = 48 chars + NUL
cpuid_brand     resb 52
; vendor string: 12 chars + NUL
cpuid_vendor    resb 16

;==============================================================================
section .text
;==============================================================================
    global _start

;──────────────────────────────────────────────────────────────────────────────
_start:
    mov rsi, title_msg
    call print_str

main_menu:
    mov rsi, menu_msg
    call print_str
    call read_line

    movzx eax, byte [input_buf]
    cmp al, '0'
    je  .exit
    cmp al, '1'
    je  feature_sysinfo
    cmp al, '2'
    je  feature_stopwatch
    cmp al, '3'
    je  feature_calculator
    cmp al, '4'
    je  feature_memviewer
    cmp al, '5'
    je  feature_perf
    cmp al, '6'
    je  feature_group
    mov rsi, invalid_msg
    call print_str
    jmp main_menu

.exit:
    mov rsi, goodbye_msg
    call print_str
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

;══════════════════════════════════════════════════════════════════════════════
; FEATURE 1 — System Information via CPUID + /proc/meminfo
;
; CPUID leaves used:
;   EAX=0          → vendor string in EBX:EDX:ECX
;   EAX=1          → family/model/stepping (EAX), logical cores (EBX),
;                    feature flags (ECX=ecx_flags, EDX=edx_flags)
;   EAX=4, ECX=0-3 → cache topology (deterministic cache params)
;   EAX=0xB        → core topology (threads/cores)
;   EAX=0x80000002-4 → brand string
;══════════════════════════════════════════════════════════════════════════════
feature_sysinfo:
    mov rsi, hdr_sysinfo
    call print_str

    ; ── CPUID header ─────────────────────────────────────────────────────────
    mov rsi, lbl_cpuid_hdr
    call print_str

    ; ── Brand string (leaves 0x80000002–4) ───────────────────────────────────
    ; Each leaf returns 16 bytes (EAX,EBX,ECX,EDX) = ASCII chars
    ; Store into cpuid_brand[0..47]
    mov rdi, cpuid_brand
    mov eax, 0x80000002
    cpuid
    mov [rdi],    eax
    mov [rdi+4],  ebx
    mov [rdi+8],  ecx
    mov [rdi+12], edx
    mov eax, 0x80000003
    cpuid
    mov [rdi+16], eax
    mov [rdi+20], ebx
    mov [rdi+24], ecx
    mov [rdi+28], edx
    mov eax, 0x80000004
    cpuid
    mov [rdi+32], eax
    mov [rdi+36], ebx
    mov [rdi+40], ecx
    mov [rdi+44], edx
    mov byte [rdi+48], 0

    ; print brand — skip leading spaces
    mov rsi, lbl_brand
    call print_str
    mov rax, cpuid_brand
    call skip_spaces            ; some CPUs pad with spaces at start
    mov rsi, rax
    call print_to_newline

    ; ── Vendor string (leaf 0) ───────────────────────────────────────────────
    xor eax, eax
    cpuid                       ; EBX:EDX:ECX = vendor (12 chars, unusual order)
    mov [cpuid_vendor],   ebx
    mov [cpuid_vendor+4], edx   ; note: EDX comes before ECX in the string
    mov [cpuid_vendor+8], ecx
    mov byte [cpuid_vendor+12], 0

    mov rsi, lbl_vendor
    call print_str
    mov rsi, cpuid_vendor
    call print_str
    mov rsi, str_nl
    call print_str

    ; ── Family / Model / Stepping (leaf 1, EAX) ──────────────────────────────
    mov eax, 1
    cpuid
    ; Save ECX and EDX feature flags for later (flags section)
    push rcx                    ; ecx_flags (SSE4.1, AVX, AES, RDRAND etc.)
    push rdx                    ; edx_flags (SSE2 etc.)

    ; EAX layout: [3:0]=stepping, [7:4]=base_model, [11:8]=base_family,
    ;             [19:16]=ext_model, [27:20]=ext_family
    mov rbx, rax                ; save full EAX
    ; Stepping
    mov rsi, lbl_stepping
    call print_str
    mov rdi, rax
    and rdi, 0xF
    call print_uint
    mov rsi, str_nl
    call print_str
    ; Base family
    mov rsi, lbl_family
    call print_str
    mov rdi, rbx
    shr rdi, 8
    and rdi, 0xF
    call print_uint
    mov rsi, str_nl
    call print_str
    ; Model = ext_model<<4 | base_model
    mov rsi, lbl_model_id
    call print_str
    mov rdi, rbx
    mov rax, rdi
    shr rax, 12                 ; ext_model at [19:16] → shift to [3:0]
    and rax, 0xF0               ; keep bits [7:4] as ext_model<<4
    mov rcx, rbx
    shr rcx, 4
    and rcx, 0xF                ; base_model
    or  rax, rcx
    mov rdi, rax
    call print_uint
    mov rsi, str_nl
    call print_str

    ; Logical processor count from CPUID leaf 1 EBX[23:16]
    mov rsi, lbl_logcores
    call print_str
    mov rdi, rbx               ; rbx still has leaf-1 EAX... wait, we need EBX from leaf 1
    ; We need to re-run cpuid or we saved the wrong reg. Let's redo leaf 1:
    mov eax, 1
    cpuid                       ; eax=version, ebx=misc, ecx=feat, edx=feat
    ; pop and re-push flags since we re-ran cpuid
    add rsp, 16                 ; discard old pushes
    push rcx
    push rdx
    shr ebx, 16                 ; bring EBX[23:16] down to BL
    movzx rdi, bl               ; max logical processors
    call print_uint
    mov rsi, str_nl
    call print_str

    ; Physical cores via leaf 4 EAX[31:26]+1 (or leaf 0xB)
    mov rsi, lbl_physcores
    call print_str
    mov eax, 4
    xor ecx, ecx
    cpuid
    mov rdi, rax
    shr rdi, 26
    and rdi, 0x3F
    inc rdi                     ; cores = EAX[31:26]+1
    call print_uint
    mov rsi, str_nl
    call print_str

    ; ── Cache topology (leaf 4, ECX=0,1,2,3) ─────────────────────────────────
    mov rsi, lbl_cache_hdr
    call print_str

    ; Leaf 4 fields: EAX[4:0]=type (0=null,1=data,2=inst,3=unified)
    ;                EAX[7:5]=level, EAX[31:26]=max_cores_sharing-1
    ;                EBX[11:0]=line_size-1, EBX[21:12]=partitions-1,
    ;                EBX[31:22]=ways-1
    ;                ECX=sets-1
    ;                size = (ways+1)*(partitions+1)*(line_size+1)*(sets+1)

    xor r15, r15                ; sub-leaf counter
.cache_loop:
    mov eax, 4
    mov ecx, r15d
    cpuid
    mov r12d, eax               ; save EAX
    and eax, 0x1F               ; cache type
    jz  .cache_done             ; type 0 = no more caches

    ; compute size in KB: (ways+1)*(partitions+1)*(line_size+1)*(sets+1) / 1024
    movzx rdi, bx               ; line_size-1 in low 12 bits
    and rdi, 0xFFF
    inc rdi                     ; line_size
    mov rax, r12
    ; extract level EAX[7:5]
    mov r13d, r12d
    shr r13d, 5
    and r13d, 0x7               ; level (1,2,3)
    ; ways = EBX[31:22]+1
    mov r14d, ebx
    shr r14d, 22
    and r14d, 0x3FF
    inc r14d
    ; partitions = EBX[21:12]+1
    mov eax, ebx
    shr eax, 12
    and eax, 0x3FF
    inc eax
    ; sets = ECX+1
    mov esi, ecx
    inc esi
    ; size = ways * partitions * sets * line_size
    imul rdi, r14               ; ways * line_size
    imul rdi, rax               ; * partitions
    mov esi, esi                ; zero-extend to 64-bit (implicit in x86-64)
    imul rdi, rsi               ; * sets
    shr rdi, 10                 ; / 1024 → KB

    ; print label based on type and level
    mov eax, r12d
    and eax, 0x1F               ; type
    cmp r13d, 1
    jne .not_l1
    cmp eax, 1
    je  .print_l1d
    cmp eax, 2
    je  .print_l1i
    jmp .print_unified
.print_l1d:
    mov rsi, lbl_l1d
    call print_str
    jmp .print_size
.print_l1i:
    mov rsi, lbl_l1i
    call print_str
    jmp .print_size
.not_l1:
    cmp r13d, 2
    jne .not_l2
    mov rsi, lbl_l2
    call print_str
    jmp .print_size
.not_l2:
    cmp r13d, 3
    jne .cache_next
    mov rsi, lbl_l3
    call print_str
    jmp .print_size
.print_unified:
    cmp r13d, 2
    je  .not_l1
    jmp .cache_next
.print_size:
    call print_uint             ; rdi = size in KB
    mov rsi, str_kb_size
    call print_str
.cache_next:
    inc r15
    cmp r15, 8
    jl  .cache_loop
.cache_done:

    ; ── CPU Feature flags ─────────────────────────────────────────────────────
    mov rsi, lbl_flags_hdr
    call print_str
    mov rsi, mv_row_prefix
    call print_str              ; "  " indent

    pop rdx                     ; edx_flags from leaf 1
    pop rcx                     ; ecx_flags from leaf 1

    ; SSE2: EDX bit 26
    bt  edx, 26
    jnc .no_sse2
    mov rsi, str_flag_sse2
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_sse2:
    ; SSE4.1: ECX bit 19
    bt  ecx, 19
    jnc .no_sse4
    mov rsi, str_flag_sse4
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_sse4:
    ; AVX: ECX bit 28
    bt  ecx, 28
    jnc .no_avx
    mov rsi, str_flag_avx
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_avx:
    ; AES-NI: ECX bit 25
    bt  ecx, 25
    jnc .no_aes
    mov rsi, str_flag_aes
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_aes:
    ; RDRAND: ECX bit 30
    bt  ecx, 30
    jnc .no_rdrand
    mov rsi, str_flag_rdrand
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_rdrand:
    ; AVX2: leaf 7 EBX bit 5
    push rcx
    mov eax, 7
    xor ecx, ecx
    cpuid
    pop rcx
    bt  ebx, 5
    jnc .no_avx2
    mov rsi, str_flag_avx2
    call print_str
    mov rsi, str_flag_sep
    call print_str
.no_avx2:
    ; AVX-512F: leaf 7 EBX bit 16
    bt  ebx, 16
    jnc .no_avx512
    mov rsi, str_flag_avx512
    call print_str
.no_avx512:
    mov rsi, str_flags_end
    call print_str

    ; ── Memory from /proc/meminfo ─────────────────────────────────────────────
    mov rsi, lbl_mem_hdr
    call print_str

    mov rdi, meminfo_path
    mov rsi, meminfo_buf
    mov rdx, 2047
    call read_file

    mov rsi, lbl_memtotal
    call print_str
    mov rdi, meminfo_buf
    mov rsi, token_memtotal
    call find_token
    test rax, rax
    jz  .no_mt
    call skip_past_colon
    call skip_spaces
    call parse_uint
    mov rdi, rax
    call print_uint
    mov rsi, str_kb
    call print_str
    jmp .after_mt
.no_mt:
    mov rsi, str_nl
    call print_str
.after_mt:

    mov rsi, lbl_memavail
    call print_str
    mov rdi, meminfo_buf
    mov rsi, token_memavail
    call find_token
    test rax, rax
    jz  .no_ma
    call skip_past_colon
    call skip_spaces
    call parse_uint
    mov rdi, rax
    call print_uint
    mov rsi, str_kb
    call print_str
    jmp .after_ma
.no_ma:
    mov rsi, str_nl
    call print_str
.after_ma:

    jmp main_menu

;══════════════════════════════════════════════════════════════════════════════
; FEATURE 2 — Stopwatch (raw terminal, poll, live tick)
;══════════════════════════════════════════════════════════════════════════════
feature_stopwatch:
    push r12
    push r13
    push r14
    push r15

    mov rsi, hdr_stopwatch
    call print_str

    ; save terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    mov rdx, termios_old
    syscall

    ; copy to termios_new
    mov rcx, 64
    mov rsi, termios_old
    mov rdi, termios_new
.cp: mov al, [rsi+rcx-1]
    mov [rdi+rcx-1], al
    dec rcx
    jnz .cp

    ; clear ICANON | ECHO in c_lflag (offset 12)
    mov eax, dword [termios_new+12]
    and eax, ~(ICANON | ECHO)
    mov dword [termios_new+12], eax
    mov byte [termios_new+22], 0    ; VTIME=0
    mov byte [termios_new+23], 0    ; VMIN=0

    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_new
    syscall

    mov rsi, sw_start_prompt
    call print_str

    ; drain buffered input
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buf
    mov rdx, 64
    syscall

    ; start time
    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_start
    syscall

    mov rsi, sw_running
    call print_str

    ; setup poll struct
    mov dword [poll_fds],   STDIN
    mov word  [poll_fds+4], POLLIN
    mov word  [poll_fds+6], 0

.sw_tick:
    mov rax, SYS_POLL
    mov rdi, poll_fds
    mov rsi, 1
    mov rdx, 100
    syscall
    test rax, rax
    jg  .sw_stopped

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_tick
    syscall

    mov rax, [ts_tick+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    mov rdx, [ts_tick+TS_NSEC]
    sub rdx, [ts_start+TS_NSEC]
    jns .sw_nsok
    dec rax
    add rdx, 1000000000
.sw_nsok:
    push rax
    push rdx

    mov rsi, sw_tick_pfx
    call print_str
    pop rdx
    pop rax
    push rax
    push rdx
    mov rdi, rax
    call print_uint
    mov rsi, sw_tick_sep
    call print_str
    pop rdx
    pop rax
    push rax
    ; tenths: nsec / 100_000_000
    mov rax, rdx
    xor rdx, rdx
    mov rcx, 100000000
    div rcx
    mov rdi, rax
    call print_uint
    mov rsi, sw_tick_sfx
    call print_str
    pop rax
    jmp .sw_tick

.sw_stopped:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buf
    mov rdx, 16
    syscall

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_stop
    syscall

    ; restore terminal
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_old
    syscall

    ; final elapsed
    mov rax, [ts_stop+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    mov rdx, [ts_stop+TS_NSEC]
    sub rdx, [ts_start+TS_NSEC]
    jns .sw_fnsok
    dec rax
    add rdx, 1000000000
.sw_fnsok:
    mov rsi, sw_final_pfx
    call print_str
    mov rdi, rax
    call print_uint
    mov rsi, sw_final_sep
    call print_str
    mov rax, rdx
    xor rdx, rdx
    mov rcx, 1000000
    div rcx
    mov rdi, rax
    call print_uint3
    mov rsi, sw_final_sfx
    call print_str

    pop r15
    pop r14
    pop r13
    pop r12
    jmp main_menu

;══════════════════════════════════════════════════════════════════════════════
; FEATURE 3 — Scientific Calculator
;══════════════════════════════════════════════════════════════════════════════
feature_calculator:
    push r12
    push r13
    mov rsi, hdr_calc
    call print_str

    mov rsi, calc_p1
    call print_str
    call read_line
    mov rsi, input_buf
    call parse_int
    mov [calc_op1], rax

    mov rsi, calc_op_prompt
    call print_str
    call read_line
    movzx eax, byte [input_buf]
    mov [calc_opchar], al

    movzx ecx, byte [calc_opchar]
    ; base-conversion operators only need one operand — handle before asking op2
    cmp cl, 'b'
    je  .conv
    cmp cl, 'o'
    je  .conv
    cmp cl, 'h'
    je  .conv

    mov rsi, calc_p2
    call print_str
    call read_line
    mov rsi, input_buf
    call parse_int
    mov rbx, rax

    mov rax, [calc_op1]
    mov rsi, calc_result
    call print_str

    movzx ecx, byte [calc_opchar]
    cmp cl, '+'
    je  .add
    cmp cl, '-'
    je  .sub
    cmp cl, '*'
    je  .mul
    cmp cl, '/'
    je  .div
    mov rsi, calc_err_op
    call print_str
    jmp .calc_exit

.add: add rax, rbx
      jmp .out
.sub: sub rax, rbx
      jmp .out
.mul: imul rax, rbx
      jmp .out
.div:
    test rbx, rbx
    jnz .div_ok
    mov rsi, calc_err_zero
    call print_str
    jmp .calc_exit
.div_ok:
    cqo
    idiv rbx
.out:
    mov rdi, rax
    call print_int
    mov rsi, calc_nl
    call print_str
    jmp .calc_exit

; ── Base conversion (b / o / h) ──────────────────────────────────────────────
; operand already in [calc_op1]; no second operand needed
.conv:
    mov r12, [calc_op1]         ; value to convert
    movzx r13d, byte [calc_opchar]

    cmp r13b, 'b'
    jne .try_oct

    ; ── Binary ───────────────────────────────────────────────────────────────
    mov rsi, calc_bin_pfx
    call print_str
    ; find highest set bit so we don't print leading zeros (min 1 digit)
    mov rcx, 63
    mov rax, r12
.bin_scan:
    bt  rax, rcx
    jc  .bin_found
    dec rcx
    jns .bin_scan
    xor rcx, rcx                ; value is 0 — print single "0"
.bin_found:
    ; print bits from rcx down to 0
    lea rdi, [conv_buf]
    xor rbx, rbx                ; index into conv_buf
.bin_loop:
    bt  r12, rcx
    jnc .bin_zero
    mov byte [rdi+rbx], '1'
    jmp .bin_next
.bin_zero:
    mov byte [rdi+rbx], '0'
.bin_next:
    inc rbx
    dec rcx
    jns .bin_loop
    mov byte [rdi+rbx], 0
    mov rsi, rdi
    call print_str
    mov rsi, calc_conv_nl
    call print_str
    jmp .calc_exit

.try_oct:
    cmp r13b, 'o'
    jne .try_hex

    ; ── Octal ────────────────────────────────────────────────────────────────
    mov rsi, calc_oct_pfx
    call print_str
    ; build octal string right-to-left in conv_buf
    lea rdi, [conv_buf + 66]
    mov byte [rdi], 0
    mov rax, r12
    test rax, rax
    jns .oct_pos
    ; handle negative: print '-' then negate
    push rax
    mov rsi, str_dash
    call print_str
    pop rax
    neg rax
.oct_pos:
    mov rcx, 8
.oct_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .oct_loop
    mov rsi, rdi
    call print_str
    mov rsi, calc_conv_nl
    call print_str
    jmp .calc_exit

.try_hex:
    cmp r13b, 'h'
    jne .conv_err

    ; ── Hexadecimal ──────────────────────────────────────────────────────────
    mov rsi, calc_hex_pfx       ; prints "0x"
    call print_str
    mov rax, r12
    test rax, rax
    jns .hex_pos
    push rax
    mov rsi, str_dash
    call print_str
    pop rax
    neg rax
.hex_pos:
    ; build hex string right-to-left
    lea rdi, [conv_buf + 66]
    mov byte [rdi], 0
.hex_loop:
    mov rdx, rax
    and rdx, 0xF
    movzx edx, byte [hex_chars + rdx]
    dec rdi
    mov [rdi], dl
    shr rax, 4
    test rax, rax
    jnz .hex_loop
    mov rsi, rdi
    call print_str
    mov rsi, calc_conv_nl
    call print_str
    jmp .calc_exit

.conv_err:
    mov rsi, calc_err_conv
    call print_str
    jmp .calc_exit

;══════════════════════════════════════════════════════════════════════════════

.calc_exit:
    pop r13
    pop r12
    jmp main_menu

; FEATURE 4 — Memory Viewer (256 bytes of .text from _start)
;══════════════════════════════════════════════════════════════════════════════
feature_memviewer:
    push r12
    push r13
    push r14
    push r15

    mov rsi, hdr_memview
    call print_str
    mov rsi, mv_col_hdr
    call print_str

    mov r12, _start
    xor r13, r13                ; row 0..15

.mv_row:
    cmp r13, 16
    jge .mv_done

    ; row base address into rbx
    mov rbx, r13
    shl rbx, 4
    add rbx, r12

    ; build address string on stack
    sub rsp, 32
    mov rax, rbx
    mov rcx, 15
.mv_addr:
    mov rdx, rax
    and rdx, 0xF
    lea rsi, [rel hex_chars]
    movzx edx, byte [rsi+rdx]
    mov [rsp+rcx], dl
    shr rax, 4
    dec rcx
    jns .mv_addr
    mov byte [rsp+16], ' '
    mov byte [rsp+17], ' '
    mov byte [rsp+18], 0

    ; print address in dim colour
    push rbx
    mov rsi, mv_row_prefix
    call print_str
    mov rsi, COL_DIM
    call print_str
    mov rsi, rsp
    add rsi, 8                  ; skip pushed rbx
    call print_str
    mov rsi, COL_RESET
    call print_str
    pop rbx
    add rsp, 32

    ; print 16 bytes
    xor r14, r14
    mov r15, rbx

.mv_col:
    cmp r14, 16
    jge .mv_eol
    cmp r14, 8
    jne .mv_ng
    mov rsi, mv_col_sep
    call print_str
.mv_ng:
    movzx ebx, byte [r15+r14]

    ; colour: dim for 0x00, yellow for printable, cyan otherwise
    test ebx, ebx
    jnz .mv_not_zero
    mov rsi, COL_DIM
    call print_str
    jmp .mv_print_byte
.mv_not_zero:
    cmp ebx, 0x20
    jl  .mv_nonprint
    cmp ebx, 0x7E
    jg  .mv_nonprint
    mov rsi, COL_YELLOW
    call print_str
    jmp .mv_print_byte
.mv_nonprint:
    mov rsi, COL_CYAN
    call print_str
.mv_print_byte:
    sub rsp, 8
    lea rsi, [rel hex_chars]
    movzx eax, bl
    shr al, 4
    movzx eax, al
    movzx eax, byte [rsi+rax]
    mov [rsp], al
    movzx eax, bl
    and al, 0xF
    movzx eax, al
    movzx eax, byte [rsi+rax]
    mov [rsp+1], al
    mov byte [rsp+2], ' '
    mov byte [rsp+3], 0
    mov rsi, rsp
    call print_str
    add rsp, 8
    mov rsi, COL_RESET
    call print_str

    inc r14
    jmp .mv_col

.mv_eol:
    mov rsi, newline
    call print_str
    inc r13
    jmp .mv_row

.mv_done:
    pop r15
    pop r14
    pop r13
    pop r12
    jmp main_menu

;══════════════════════════════════════════════════════════════════════════════
; FEATURE 5 — CPU Performance Test
;
; Three tests, each 1 second:
;   A. Scalar:  ADD  r64, r64          (1 op/cycle theoretical IPC=4+)
;   B. SSE:     ADDPS xmm, xmm         (4×f32 per op)
;   C. AVX:     VADDPS ymm, ymm, ymm   (8×f32 per op)
; Plus: RDTSC before/after 1-second wall window → actual GHz
;══════════════════════════════════════════════════════════════════════════════
feature_perf:
    push r12
    push r13
    push r14
    push r15

    mov rsi, hdr_perf
    call print_str
    mov rsi, perf_intro
    call print_str

    ; ── RDTSC frequency measurement ──────────────────────────────────────────
    mov rsi, perf_rdtsc_note
    call print_str

    ; read start TSC
    mfence
    rdtsc
    shl rdx, 32
    or  rdx, rax
    mov r12, rdx                ; r12 = TSC start

    ; start wall clock
    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_start
    syscall

    ; spin 1 second
    mov r15, 0
.rdtsc_spin:
    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_stop
    syscall
    mov rax, [ts_stop+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    cmp rax, 1
    jl  .rdtsc_spin

    ; read end TSC
    mfence
    rdtsc
    shl rdx, 32
    or  rdx, rax
    sub rax, r12                ; rax = cycles elapsed in 1 second
    ; GHz = cycles / 1_000_000_000  (divide by 1e9)
    mov r13, rax                ; save cycles
    xor rdx, rdx
    mov rcx, 1000000000
    div rcx
    mov r14, rax                ; r14 = whole GHz
    ; tenths: (cycles - GHz*1e9) / 100_000_000
    imul rax, r14, 1000000000
    sub r13, rax                ; r13 = remainder
    mov rax, r13
    xor rdx, rdx
    mov rcx, 100000000
    div rcx                     ; rax = tenths digit

    mov rsi, perf_ghz_pfx
    call print_str
    mov rdi, r14
    call print_uint
    mov rsi, perf_dot
    call print_str
    mov rdi, rax
    call print_uint
    mov rsi, perf_ghz_sfx
    call print_str

    ; ── Test A: Scalar ADD ───────────────────────────────────────────────────
    mov rsi, perf_scalar_lbl
    call print_str

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_start
    syscall

    xor r12, r12                ; op counter (millions)
    xor r13, r13                ; dummy accumulator (prevents dead-code elim)
    xor r14, r14
    xor r15, r15

.scalar_outer:
    ; 1,000,000 scalar ADDs per batch (4 ops unrolled × 250,000 iterations)
    mov rcx, 250000
.scalar_inner:
    add r13, 1
    add r14, 3
    add r15, 7
    add r13, r14
    dec rcx
    jnz .scalar_inner
    inc r12

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_stop
    syscall
    mov rax, [ts_stop+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    cmp rax, 1
    jl  .scalar_outer

    ; r12 = millions of batches; each batch = 4*250000 = 1M ops
    imul r12, 4
    mov rdi, r12
    call print_uint
    mov rsi, perf_mops
    call print_str

    ; ── Test B: SSE ADDPS (4×f32) ────────────────────────────────────────────
    mov rsi, perf_sse_lbl
    call print_str

    ; init xmm registers with 1.0 (0x3F800000)
    mov eax, 0x3F800000
    movd xmm0, eax
    shufps xmm0, xmm0, 0        ; broadcast 1.0 to all 4 lanes
    movaps xmm1, xmm0
    movaps xmm2, xmm0
    movaps xmm3, xmm0

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_start
    syscall

    xor r12, r12

.sse_outer:
    mov rcx, 250000
.sse_inner:
    addps xmm0, xmm1            ; 4 fp32 adds
    addps xmm2, xmm3            ; 4 fp32 adds
    addps xmm1, xmm0            ; 4 fp32 adds
    addps xmm3, xmm2            ; 4 fp32 adds
    dec rcx
    jnz .sse_inner
    inc r12

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_stop
    syscall
    mov rax, [ts_stop+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    cmp rax, 1
    jl  .sse_outer

    ; r12 batches × 4 ops/iter × 250000 iters × 4 floats = effective ops
    imul r12, 4 * 250000 * 4    ; = 4M float ops per batch
    mov rcx, 1000000
    xor rdx, rdx
    mov rax, r12
    div rcx
    mov rdi, rax
    call print_uint
    mov rsi, perf_mops
    call print_str

    ; ── Test C: AVX VADDPS (8×f32) ───────────────────────────────────────────
    mov rsi, perf_avx_lbl
    call print_str

    ; Check AVX support first (CPUID leaf 1 ECX bit 28)
    mov eax, 1
    cpuid
    bt  ecx, 28
    jnc .no_avx_test

    ; init ymm with 1.0
    mov eax, 0x3F800000
    movd xmm0, eax
    vbroadcastss ymm0, xmm0
    vmovaps ymm1, ymm0
    vmovaps ymm2, ymm0
    vmovaps ymm3, ymm0

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_start
    syscall

    xor r12, r12

.avx_outer:
    mov rcx, 250000
.avx_inner:
    vaddps ymm0, ymm0, ymm1     ; 8 fp32 adds
    vaddps ymm2, ymm2, ymm3     ; 8 fp32 adds
    vaddps ymm1, ymm1, ymm0     ; 8 fp32 adds
    vaddps ymm3, ymm3, ymm2     ; 8 fp32 adds
    dec rcx
    jnz .avx_inner
    inc r12

    mov rax, SYS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    mov rsi, ts_stop
    syscall
    mov rax, [ts_stop+TS_SEC]
    sub rax, [ts_start+TS_SEC]
    cmp rax, 1
    jl  .avx_outer

    imul r12, 4 * 250000 * 8    ; 8 floats × 4 ops × 250k iters
    mov rcx, 1000000
    xor rdx, rdx
    mov rax, r12
    div rcx
    mov rdi, rax
    call print_uint
    mov rsi, perf_mops
    call print_str
    jmp .perf_done

.no_avx_test:
    mov rsi, COL_DIM
    call print_str
    mov rsi, str_dash
    call print_str
    mov rsi, str_space
    call print_str
    mov rsi, COL_RESET
    call print_str

.perf_done:
    mov rsi, newline
    call print_str

    pop r15
    pop r14
    pop r13
    pop r12
    jmp main_menu

;══════════════════════════════════════════════════════════════════════════════
;══════════════════════════════════════════════════════════════════════════════
; FEATURE 6 — Group Members
;══════════════════════════════════════════════════════════════════════════════
feature_group:
    mov rsi, hdr_group
    call print_str
    mov rsi, group_members
    call print_str
    jmp main_menu

;══════════════════════════════════════════════════════════════════════════════
;  L I B R A R Y
;══════════════════════════════════════════════════════════════════════════════

;──────────────────────────────────────────────────────────────────────────────
; read_file  —  open RDI path, read ≤RDX bytes into RSI buffer
;──────────────────────────────────────────────────────────────────────────────
read_file:
    push rbx
    push r12
    push r13
    mov r12, rsi
    mov r13, rdx
    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js  .fail
    mov rbx, rax
    mov rax, SYS_READ
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    syscall
    push rax
    test rax, rax
    js  .cl
    mov byte [r12+rax], 0
.cl:
    mov rax, SYS_CLOSE
    mov rdi, rbx
    syscall
    pop rax
    jmp .done
.fail:
.done:
    pop r13
    pop r12
    pop rbx
    ret

;──────────────────────────────────────────────────────────────────────────────
; print_str  —  write null-terminated string at RSI  (preserves all regs)
;──────────────────────────────────────────────────────────────────────────────
print_str:
    push rax
    push rdi
    push rsi
    push rdx
    xor rdx, rdx
.l: cmp byte [rsi+rdx], 0
    je  .w
    inc rdx
    jmp .l
.w: test rdx, rdx
    jz  .done
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.done:
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;──────────────────────────────────────────────────────────────────────────────
; print_to_newline  —  print RSI up to LF or NUL, then emit newline
;──────────────────────────────────────────────────────────────────────────────
print_to_newline:
    push rax
    push rdi
    push rsi
    push rdx
    xor rdx, rdx
.l: movzx eax, byte [rsi+rdx]
    cmp al, 10
    je  .w
    test al, al
    jz  .w
    inc rdx
    jmp .l
.w: test rdx, rdx
    jz  .nl
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.nl:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;──────────────────────────────────────────────────────────────────────────────
; read_line  —  read up to 255 bytes from stdin into input_buf
;──────────────────────────────────────────────────────────────────────────────
read_line:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buf
    mov rdx, 255
    syscall
    test rax, rax
    jle .done
    mov byte [input_buf+rax], 0
    lea rcx, [rax-1]
    cmp byte [input_buf+rcx], 10
    jne .done
    mov byte [input_buf+rcx], 0
.done:
    ret

;──────────────────────────────────────────────────────────────────────────────
; find_token  —  find needle (RSI) in haystack (RDI); Out: RAX=ptr or 0
;──────────────────────────────────────────────────────────────────────────────
find_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, rdi
    mov rcx, rsi
.hay:
    cmp byte [rbx], 0
    je  .miss
    mov rdi, rbx
    mov rsi, rcx
.cmp:
    movzx eax, byte [rsi]
    test al, al
    jz  .hit
    movzx edx, byte [rdi]
    test dl, dl
    jz  .next
    cmp al, dl
    jne .next
    inc rsi
    inc rdi
    jmp .cmp
.next:
    inc rbx
    jmp .hay
.hit:
    mov rax, rbx
    jmp .ret
.miss:
    xor rax, rax
.ret:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

;──────────────────────────────────────────────────────────────────────────────
; count_occurrences  —  count needle (RSI) in haystack (RDI); Out: RAX=count
;──────────────────────────────────────────────────────────────────────────────
count_occurrences:
    push rbx
    push rcx
    push rdx
    mov rcx, rsi
    xor rdx, rdx
.nl:
    cmp byte [rcx+rdx], 0
    je  .nld
    inc rdx
    jmp .nl
.nld:
    xor rbx, rbx
.lp:
    call find_token
    test rax, rax
    jz  .done
    inc rbx
    add rax, rdx
    mov rdi, rax
    jmp .lp
.done:
    mov rax, rbx
    pop rdx
    pop rcx
    pop rbx
    ret

;──────────────────────────────────────────────────────────────────────────────
; skip_past_colon  /  skip_spaces  /  parse_uint  /  parse_int
;──────────────────────────────────────────────────────────────────────────────
skip_past_colon:
.l: cmp byte [rax], 0
    je  .d
    cmp byte [rax], ':'
    je  .f
    inc rax
    jmp .l
.f: inc rax
.d: ret

skip_spaces:
.l: movzx ecx, byte [rax]
    cmp cl, ' '
    je  .s
    cmp cl, 9
    je  .s
    ret
.s: inc rax
    jmp .l

parse_uint:
    push rcx
    xor rcx, rcx
.l: movzx edx, byte [rax]
    cmp dl, '0'
    jl  .d
    cmp dl, '9'
    jg  .d
    sub dl, '0'
    imul rcx, rcx, 10
    movzx edx, dl
    add rcx, rdx
    inc rax
    jmp .l
.d: mov rax, rcx
    pop rcx
    ret

parse_int:
    push rbx
    push rcx
    mov rbx, rsi
    xor rcx, rcx
    xor r8, r8
    movzx eax, byte [rbx]
    cmp al, '-'
    jne .d
    inc r8
    inc rbx
.d: movzx eax, byte [rbx]
    cmp al, '0'
    jl  .done
    cmp al, '9'
    jg  .done
    sub al, '0'
    imul rcx, rcx, 10
    movzx eax, al
    add rcx, rax
    inc rbx
    jmp .d
.done:
    mov rax, rcx
    test r8, r8
    jz  .p
    neg rax
.p: pop rcx
    pop rbx
    ret

;──────────────────────────────────────────────────────────────────────────────
; print_uint  —  print unsigned integer RDI
;──────────────────────────────────────────────────────────────────────────────
print_uint:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    mov rax, rdi
    lea rsi, [num_buf+31]
    mov byte [rsi], 0
    mov rbx, 10
.l: xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .l
    call print_str
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;──────────────────────────────────────────────────────────────────────────────
; print_uint3  —  print unsigned integer RDI zero-padded to 3 digits
;──────────────────────────────────────────────────────────────────────────────
print_uint3:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    mov rax, rdi
    lea rsi, [num_buf+31]
    mov byte [rsi], 0
    mov rbx, 10
    mov rcx, 3
.l: xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    dec rcx
    jnz .l
    call print_str
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;──────────────────────────────────────────────────────────────────────────────
; print_int  —  print signed integer RDI
;──────────────────────────────────────────────────────────────────────────────
print_int:
    push rdi
    push rsi
    mov rax, rdi
    test rax, rax
    jns .p
    push rax
    mov rsi, str_dash
    call print_str
    pop rax
    neg rax
.p: mov rdi, rax
    call print_uint
    pop rsi
    pop rdi
    ret

