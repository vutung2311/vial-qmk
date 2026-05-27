/**
 * @file    c1_main.c
 * @brief   RP2040 Core 1 entry point for ChibiOS SMP.
 *
 * Initializes Core 1's ChibiOS OS instance and runs peripheral threads
 * (OLED display, future: split serial) on the second core.
 */

#include "ch.h"
#include "hal.h"

#ifdef OLED_ENABLE
#include "oled_driver.h"

/*
 * Set by Core 0 at the end of keyboard_init() to signal that
 * is_keyboard_master() and other split state are valid.
 */
volatile bool c1_keyboard_init_complete = false;

/* OLED thread — owns I2C init + OLED init + OLED task loop.
 * Waits for Core 0's keyboard_init() so is_keyboard_master()
 * returns the correct value for rotation and content. */
static THD_WORKING_AREA(waOledThread, 2048);
static THD_FUNCTION(OledThread, arg) {
    (void)arg;
    chRegSetThreadName("oled");

    /* Wait for Core 0's keyboard_init() to finish
     * (includes split detection, so is_keyboard_master() is valid). */
    while (!c1_keyboard_init_complete) {
        chThdSleepMilliseconds(10);
    }

    /* I2C init + OLED init — all on Core 1.
     * oled_init_user() can now correctly check is_keyboard_master()
     * for rotation, and SSD1306 hardware is configured to match. */
    oled_init(OLED_ROTATION_0);

    /* OLED task loop. */
    while (true) {
        oled_task();
        chThdSleepMilliseconds(20); /* ~50 Hz refresh */
    }
}
#endif /* OLED_ENABLE */

/**
 * Core 1 entry point.
 */
void c1_main(void) {

    /* Wait for Core 0's chSysInit() to complete. */
    chSysWaitSystemState(ch_sys_running);
    chInstanceObjectInit(&ch1, &ch_core1_cfg);

    /* Enable interrupts — Core 1 is alive. */
    chSysUnlock();

#ifdef OLED_ENABLE
    /* Start OLED thread on Core 1. */
    chThdCreateStatic(waOledThread, sizeof(waOledThread),
                      NORMALPRIO, OledThread, NULL);
#endif

    /* Core 1 main thread idles. */
    while (true) {
        chThdSleepMilliseconds(500);
    }
}
