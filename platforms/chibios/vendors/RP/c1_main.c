/**
 * @file    c1_main.c
 * @brief   RP2040 Core 1 entry point for ChibiOS SMP.
 *
 * This file provides the c1_main() function that CRT0 calls on Core 1
 * after the multicore launch sequence. It initializes a second ChibiOS
 * OS instance (ch1) running on Core 1.
 *
 * Peripherals intended for Core 1 (e.g. OLED, split serial) should
 * be initialized and driven from threads created within this function
 * or pinned to Core 1's OS instance.
 */

#include "ch.h"
#include "hal.h"

/**
 * Core 1 entry point.
 *
 * Called by _crt0_c1_entry after Core 1's stacks and VTOR are set up.
 * Must initialize Core 1's ChibiOS OS instance before doing anything
 * else.
 */
void c1_main(void) {

    /*
     * Wait for Core 0's chSysInit() to finish and transition the
     * system to ch_sys_running state.  Core 1's CRT0 runs with
     * interrupts disabled; the OS instance init will set things up.
     */
    chSysWaitSystemState(ch_sys_running);
    chInstanceObjectInit(&ch1, &ch_core1_cfg);

    /* Enable interrupts — Core 1 is alive. */
    chSysUnlock();

    /*
     * Core 1 main thread loop.
     *
     * TODO: Create threads here for OLED display refresh and
     * split-keyboard serial I/O.
     */
    while (true) {
        chThdSleepMilliseconds(500);
    }
}
