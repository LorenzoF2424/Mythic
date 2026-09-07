#include "cli/cli.h"
#include "drivers/display/kprintf.h"
#include "lib/stdintex/uint512_t.h"
uint8_t system_stack[65536];
extern uint8_t initstack[];

void init_all();
void foo();
void test();

void main() {

    __asm__ __volatile__ ("mov %0, %%rsp" : : "r"(system_stack + 65536));
    init_all();




    //vfs_print_prompt();


    //test();
    input.setStart();


    //thread_create(info_bar_thread);
    //foo();
    while (true) {


        current_tick = ticks;
        cli_main();
        previous_tick = current_tick;





    }

    //__asm__ __volatile__ ("hlt");

}


void init_all() {

    klog("MythOS: Boot sequence initiated");
    init_display();
    terminal.init();

    klog("Terminal initialized. Screen is active.");

    init_tss();
    init_gdt();
    init_idt();
    init_exceptions();

    klog("CPU Exceptions are now catching errors.");


    terminal.change_color(terminal_color(vga_palette[current_palette][0], vga_palette[current_palette][15]));
    terminal.write_welcome();

    init_memory();

    // aa
    info_bar_window = terminal;
    info_bar_window.y_offset=0;
    draw_info_bar();


    init_spurious();
    init_keyboard();
    init_timer(1000);
    enable_fpu();
    init_mouse();

    asm volatile ("sti");

    init_scheduler();

    // File System

    init_vfs();
    mbr_read_partitions();




    init_cmd_manager();

    klog("[%s] Kernel fully initialized. Interrupts enabled.", __func__);
}





void test() {

mbr_read_partitions();

// Test raw: read the file directly from hardware
uint8_t file_buffer[512];
kprintf("\nReading SECRET.TXT from Cluster 3...\n");

// We know from the print that it starts at cluster 3 and is 23 bytes
fat32_read_file(3, 23, file_buffer);

kprintf("File content: '%s'\n", (char*)file_buffer);

}


void foo() {

    uint512_t hi = (uint512_t)"293439842738474748349373984936748961974914981649";

    kprintf("%l512d\n",&hi);
}
