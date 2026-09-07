#include "drivers/display/printfCore.h"


// --- HELPERS TO BRIDGE PRIMITIVES AND CUSTOM CLASSES ---

uint64_t extract_low_64(uint64_t val)   { return val; }
uint64_t extract_low_64(uint128_t val)  { return val.parts.low; }
uint64_t extract_low_64(uint256_t val)  { return val.low.parts.low; }
uint64_t extract_low_64(uint512_t val)  { return val.low.low.parts.low; }
uint64_t extract_low_64(uint1024_t val) { return val.low.low.low.parts.low; }

// --- CORE PRINTING ENGINE ---

/**
 * Prints a uint64_t in the given base with optional padding.
 * Uses uppercase hex digits (A-F).
 */
static void core_print_number(void (*putc_cb)(char, void*), void* arg,
                               uint64_t num, int base, bool is_signed,
                               int padding, char pad_char) {
    char buffer[64];
    int  i           = 0;
    bool is_negative = false;

    if (is_signed && base == 10 && (int64_t)num < 0) {
        is_negative = true;
        num = (uint64_t)(-(int64_t)num);
    }

    if (num == 0) buffer[i++] = '0';

    while (num > 0) {
        int rem = num % base;
        buffer[i++] = (rem < 10) ? ('0' + rem) : ('A' + rem - 10);
        num /= base;
    }

    // Zero/space pad up to requested width
    while (i < padding) buffer[i++] = pad_char;

    if (is_negative) buffer[i++] = '-';

    while (--i >= 0) putc_cb(buffer[i], arg);
}

/**
 * Generic version for huge integers (uint128 to uint1024).
 * Uses the ultra-fast div_mod_64 block division algorithm.
 */
template <typename T>
static void core_print_generic_int(void (*putc_cb)(char, void*), void* arg,
                                    T val, uint32_t base, bool negative,
                                    int padding, char pad_char) {
    char buffer[320];
    int  i = 0;

    const uint64_t fast_base = (uint64_t)base;
    const T        zero_val  = T();

    if (val == zero_val) {
        buffer[i++] = '0';
    } else {
        T q;
        while (val > zero_val && i < 319) {
            uint64_t remainder = val.div_mod_64(fast_base, q);
            int rem = (int)remainder;
            buffer[i++] = (rem < 10) ? ('0' + rem) : ('A' + rem - 10);
            val = q;
        }
    }

    int count = i + (negative ? 1 : 0);
    while (count < padding) { putc_cb(pad_char, arg); count++; }

    if (negative) putc_cb('-', arg);
    while (i > 0) putc_cb(buffer[--i], arg);
}

/**
 * Prints a double with `precision` decimal places (default 6).
 * No heap, no libm — freestanding safe.
 * Max precision: 9 digits (uint64_t frac limit).
 */
static void core_print_float(void (*putc_cb)(char, void*), void* arg,
                              double val, int precision, int padding,
                              char pad_char) {
    if (precision < 0) precision = 6;
    if (precision > 9) precision = 9;

    bool negative = (val < 0.0);
    if (negative) val = -val;

    uint64_t int_part = (uint64_t)val;
    double   frac     = val - (double)int_part;

    uint64_t pow10 = 1;
    for (int k = 0; k < precision; k++) pow10 *= 10;
    uint64_t frac_part = (uint64_t)(frac * (double)pow10 + 0.5);

    if (frac_part >= pow10) { frac_part -= pow10; int_part++; }

    // Integer digits
    char ibuf[21];
    int  ilen = 0;
    if (int_part == 0) {
        ibuf[ilen++] = '0';
    } else {
        uint64_t tmp = int_part;
        while (tmp > 0) { ibuf[ilen++] = '0' + (tmp % 10); tmp /= 10; }
    }

    // Fractional digits (left-zero-padded)
    char fbuf[10];
    for (int k = precision - 1; k >= 0; k--) {
        fbuf[k] = '0' + (frac_part % 10);
        frac_part /= 10;
    }

    int total = (negative ? 1 : 0) + ilen + (precision > 0 ? 1 + precision : 0);
    while (total < padding) { putc_cb(pad_char, arg); total++; }

    if (negative) putc_cb('-', arg);
    while (ilen > 0) putc_cb(ibuf[--ilen], arg);
    if (precision > 0) {
        putc_cb('.', arg);
        for (int k = 0; k < precision; k++) putc_cb(fbuf[k], arg);
    }
}

/**
 * Prints the custom pointer dereference format:
 *   [0x00000000DEADBEEF | <value>]
 *
 * sub: 'd' → dereferences as int32_t  (decimal)
 *      'x' → dereferences as uint32_t (hex)
 *      'f' → dereferences as double
 *
 * Use: kprintf("%pf", &my_double);
 *      kprintf("%pd", &my_int32);
 *      kprintf("%px", &my_uint32);
 */
static void core_print_ptr_deref(void (*putc_cb)(char, void*), void* arg,
                                  void* raw_ptr, char sub) {
    if (!raw_ptr) {
        const char* null_msg = "[NULL|NULL]";
        while (*null_msg) putc_cb(*null_msg++, arg);
        return;
    }

    // [0xADDRESS |
    putc_cb('[', arg);
    putc_cb('0', arg); putc_cb('x', arg);
    core_print_number(putc_cb, arg, (uint64_t)raw_ptr, 16, false,
                      sizeof(void*) * 2, '0');
    putc_cb(' ', arg); putc_cb('|', arg); putc_cb(' ', arg);

    if (sub == 'd') {
        int32_t val = *(int32_t*)raw_ptr;
        core_print_number(putc_cb, arg, (uint64_t)(int64_t)val, 10, true, 0, ' ');
    } else if (sub == 'x') {
        uint32_t val = *(uint32_t*)raw_ptr;
        putc_cb('0', arg); putc_cb('x', arg);
        core_print_number(putc_cb, arg, (uint64_t)val, 16, false, 0, ' ');
    } else if (sub == 'f') {
        double val = *(double*)raw_ptr;
        core_print_float(putc_cb, arg, val, 6, 0, ' ');
    }

    putc_cb(']', arg);
}

// --- VA_LIST HANDLER FOR BIG INTEGERS ---

/**
 * Fetches T* from va_list and prints the big integer.
 * va_list is passed by value intentionally: we fetch exactly one pointer
 * (trivially copyable), so no advance needs to propagate back.
 *
 * Callers pass the address of their big integer:
 *   uint1024_t n = ...;
 *   kprintf("%llllld", &n);
 */
template <typename T>
static void handle_int_printing(void (*putc_cb)(char, void*), void* arg,
                                 va_list args, char format_char,
                                 int padding, char pad_char) {
    T* num_ptr = va_arg(args, T*);
    if (!num_ptr) return;

    if (format_char == 'x') {
        putc_cb('0', arg); putc_cb('x', arg);
        core_print_generic_int<T>(putc_cb, arg, *num_ptr, 16, false, padding, pad_char);
        return;
    }
    core_print_generic_int<T>(putc_cb, arg, *num_ptr, 10, false, padding, pad_char);
}

// --- MAIN PRINTF CORE ---

void printf_core(void (*putc_cb)(char, void*), void* arg,
                 const char* format, va_list args) {
    // Safety check
    if (!format) return;

    for (int i = 0; format[i] != '\0'; i++) {

        if (format[i] != '%') {
            putc_cb(format[i], arg);
            continue;
        }

        i++;
        if (format[i] == '\0') break;

        // --- Padding ---
        char pad_char = ' ';
        if (format[i] == '0') { pad_char = '0'; i++; }

        int padding = 0;
        while (format[i] >= '0' && format[i] <= '9') {
            padding = padding * 10 + (format[i] - '0');
            i++;
        }

        // --- Optional precision: %.4f ---
        int precision = -1;
        if (format[i] == '.') {
            i++;
            precision = 0;
            while (format[i] >= '0' && format[i] <= '9') {
                precision = precision * 10 + (format[i] - '0');
                i++;
            }
        }

        switch (format[i]) {

            // ── Strings & chars ──────────────────────────────────────────────
            case 's': {
                const char* s = va_arg(args, const char*);
                if (!s) s = "(null)";
                while (*s) putc_cb(*s++, arg);
                break;
            }
            case 'c': putc_cb((char)va_arg(args, int), arg); break;

            // ── Signed decimal ───────────────────────────────────────────────
            case 'd': {
                int64_t num = va_arg(args, int);
                core_print_number(putc_cb, arg, (uint64_t)num, 10, true, padding, pad_char);
                break;
            }

            // ── Unsigned decimal ─────────────────────────────────────────────
            case 'u': {
                uint64_t num = va_arg(args, uint64_t);
                core_print_number(putc_cb, arg, num, 10, false, padding, pad_char);
                break;
            }

            // ── Hex (32-bit) ─────────────────────────────────────────────────
            case 'x': {
                uint64_t num = va_arg(args, uint64_t);
                putc_cb('0', arg); putc_cb('x', arg);
                core_print_number(putc_cb, arg, num, 16, false, padding, pad_char);
                break;
            }

            // ── Pointer ──────────────────────────────────────────────────────
            //   %p          → 0x<full-width zero-padded address>
            //   %pd / %px / %pf → [0xADDR | dereferenced value]
            case 'p': {
                char next = format[i + 1];
                if (next == 'd' || next == 'x' || next == 'f') {
                    i++; // consume sub-specifier
                    void* ptr = va_arg(args, void*);
                    core_print_ptr_deref(putc_cb, arg, ptr, next);
                } else {
                    uint64_t ptr = (uint64_t)va_arg(args, void*);
                    putc_cb('0', arg); putc_cb('x', arg);
                    core_print_number(putc_cb, arg, ptr, 16, false,
                                      sizeof(void*) * 2, '0');
                }
                break;
            }

            // ── Float ────────────────────────────────────────────────────────
            case 'f': {
                double num = va_arg(args, double);
                core_print_float(putc_cb, arg, num, precision, padding, pad_char);
                break;
            }

            // ── Long prefix (e.g., %ld, %lld, %l256d, %l1024x) ───────────────────────
            case 'l': {
                bool handled_fastpath = false;

                // 1. Fast-path checks using switch
                switch (format[i + 1]) {
                    // Standard %ld or %lx (64-bit)
                    case 'd':
                    case 'x': {
                        i++; // Move directly to 'd' or 'x'
                        uint64_t num = va_arg(args, uint64_t);

                        switch (format[i]) {
                            case 'x':
                                putc_cb('0', arg);
                                putc_cb('x', arg);
                                core_print_number(putc_cb, arg, num, 16, false, padding, pad_char);
                                break;
                            case 'd':
                            default:
                                core_print_number(putc_cb, arg, num, 10, true, padding, pad_char);
                                break;
                        }
                        handled_fastpath = true;
                        break;
                    }
                    // Standard %lld or %llx (128-bit)
                    case 'l': {
                        switch (format[i + 2]) {
                            case 'd':
                            case 'x': {
                                i += 2; // Move directly to 'd' or 'x'
                                handle_int_printing<uint128_t>(putc_cb, arg, args, format[i], padding, pad_char);
                                handled_fastpath = true;
                                break;
                            }
                        }
                        break; // End of 'l' check
                    }
                }

                // If processed by fast-paths, early break out of the main case
                if (handled_fastpath) {
                    break;
                }

                // 3. Fallback: explicit bit-width parsing for 256+ (e.g., %l256d, %l1024x)
                i++; // Skip the initial 'l'
                int bit_width = 0;

                while (format[i] >= '0' && format[i] <= '9') {
                    bit_width = bit_width * 10 + (format[i] - '0');
                    i++;
                }

                if (format[i] == '\0') {
                    return; // Early return on unexpected end of string
                }

                // Handle explicitly parsed larger types (passed by pointer)
                switch (bit_width) {
                    case 256:  handle_int_printing<uint256_t> (putc_cb, arg, args, format[i], padding, pad_char); break;
                    case 512:  handle_int_printing<uint512_t> (putc_cb, arg, args, format[i], padding, pad_char); break;
                    case 1024: handle_int_printing<uint1024_t>(putc_cb, arg, args, format[i], padding, pad_char); break;
                    default:   putc_cb('?', arg); break;
                }

                break;
            }

            case '%': putc_cb('%', arg); break;
            default:
                putc_cb('%', arg);
                putc_cb(format[i], arg);
                break;
        }
    }
}
