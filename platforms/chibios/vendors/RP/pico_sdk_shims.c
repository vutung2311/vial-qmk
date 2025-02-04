// Copyright 2022 Stefan Kerkmann
// SPDX-License-Identifier: GPL-2.0-or-later

#include <stdbool.h>

extern void chSysHalt(const char *reason) __attribute__((noreturn));

void panic(const char *fmt, ...) {
    chSysHalt(fmt);
}

void hard_assertion_failure(void) {
    panic("hard assert");
}

/*
 * Bridge between ChibiOS clock management and pico-sdk.
 *
 * ChibiOS now handles clock initialization natively (rp_clock_init()).
 * pico-sdk code (PIO serial driver, etc.) calls clock_get_hz() which
 * normally reads pico-sdk's own configured_freq[] array.  We override
 * clock_get_hz() to read from ChibiOS instead, keeping a single source
 * of truth.
 */
#include "hal.h"
#ifdef RP_CLK_SYS_FREQ
#include "hardware/clocks.h"
#include "rp_clocks.h"

/* Map pico-sdk clock enum → ChibiOS RP_CLK_xxx index. */
static uint32_t pico_to_chibios_clk(clock_handle_t clock) {
    switch ((uint32_t)clock) {
    case (uint32_t)clk_sys:  return RP_CLK_SYS;
    case (uint32_t)clk_ref:  return RP_CLK_REF;
    case (uint32_t)clk_peri: return RP_CLK_PERI;
    case (uint32_t)clk_usb:  return RP_CLK_USB;
    case (uint32_t)clk_adc:  return RP_CLK_ADC;
    case (uint32_t)clk_rtc:  return RP_CLK_RTC;
    default:                 return RP_CLK_SYS;
    }
}

/* Override pico-sdk's clock_get_hz — single source from ChibiOS. */
uint32_t clock_get_hz(clock_handle_t clock) {
    return rp_clock_get_hz(pico_to_chibios_clk(clock));
}

/* runtime_init_clocks is called by clocks_init() — no-op since
   ChibiOS handles clocks via rp_clock_init(). */
void runtime_init_clocks(void) {
}
#endif
