#
# Raspberry Pi RP2040 specific drivers
#
# QMK provides its own boot2 in stage2_bootloaders.c — prevent ChibiOS
# from also including one (which would make .boot2 section 512 bytes
# instead of 256, breaking the RP2040 flash layout).
RP2040_BOOT_STAGE2 :=
##############################################################################
COMMON_VPATH += $(PLATFORM_PATH)/$(PLATFORM_KEY)/$(DRIVER_DIR)/vendor/$(MCU_FAMILY)/$(MCU_SERIES)

ifeq ($(strip $(WS2812_DRIVER)), vendor)
    OPT_DEFS += -DRP_DMA_REQUIRED=TRUE
endif

#
# Raspberry Pi Pico SDK Support
##############################################################################
ADEFS  += -DCRT0_VTOR_INIT=1 \
		  -DCRT0_EXTRA_CORES_NUMBER=1 \
          -DCRT0_INIT_VECTORS=1

CFLAGS += -DPICO_NO_FPGA_CHECK \
          -DNDEBUG

# CRT0_EXTRA_CORES_NUMBER must also be a C define (not just ADEFS)
# so crt1.c compiles the Core 1 startup stubs (__c1_cpu_init, etc.)
OPT_DEFS += -DCRT0_EXTRA_CORES_NUMBER=1

#
# Pico SDK source and header files needed by QMK and ChibiOS
##############################################################################
PICOSDKROOT   := $(TOP_DIR)/lib/pico-sdk

PICOSDKSRC     = $(PICOSDKROOT)/src/rp2_common/hardware_pio/pio.c \
                 $(PICOSDKROOT)/src/rp2_common/hardware_timer/timer.c \
                 $(PICOSDKROOT)/src/rp2_common/hardware_flash/flash.c \
                 $(PICOSDKROOT)/src/rp2_common/hardware_gpio/gpio.c \
                 $(PICOSDKROOT)/src/common/hardware_claim/claim.c \
                 $(PICOSDKROOT)/src/rp2_common/hardware_watchdog/watchdog.c \
                 $(PICOSDKROOT)/src/rp2_common/hardware_ticks/ticks.c \
                 $(PICOSDKROOT)/src/rp2_common/pico_bootrom/bootrom.c

PICOSDKINC     = $(PLATFORM_PATH)/$(PLATFORM_KEY)/vendors/$(MCU_FAMILY)/pico_sdk_shims \
                 $(PICOSDKROOT)/src/common/boot_picoboot_headers/include \
                 $(PICOSDKROOT)/src/common/boot_picobin_headers/include \
                 $(PICOSDKROOT)/src/common/pico_base_headers/include \
				 $(PICOSDKROOT)/src/common/hardware_claim/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_platform_compiler/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_platform_common/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_platform_sections/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_platform_panic/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_runtime_init/include \
				 $(PICOSDKROOT)/src/rp2_common/pico_runtime/include \
                 $(PICOSDKROOT)/src/rp2_common/pico_platform/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_base/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_clocks/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_flash/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_gpio/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_irq/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_pll/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_pio/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_sync/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_timer/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_resets/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_watchdog/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_xosc/include \
                 $(PICOSDKROOT)/src/rp2040/hardware_regs/include \
                 $(PICOSDKROOT)/src/rp2040/hardware_structs/include \
				 $(PICOSDKROOT)/src/rp2040/pico_platform/include \
                 $(PICOSDKROOT)/src/boards/include \
                 $(PICOSDKROOT)/src/rp2_common/boot_bootrom_headers/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_boot_lock/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_sync_spin_lock/include \
                 $(PICOSDKROOT)/src/rp2_common/pico_flash/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_xip_cache/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_ticks/include \
                 $(PICOSDKROOT)/src/rp2_common/hardware_vreg/include \
                 $(PICOSDKROOT)/src/rp2_common/pico_bootrom/include

PLATFORM_SRC += $(PICOSDKSRC)
EXTRAINCDIRS += $(PICOSDKINC)

PLATFORM_RP2040_PATH := $(PLATFORM_PATH)/$(PLATFORM_KEY)/vendors/$(MCU_FAMILY)

PLATFORM_SRC +=	$(PLATFORM_RP2040_PATH)/stage2_bootloaders.c \
				$(PLATFORM_RP2040_PATH)/pico_sdk_shims.c \
				$(PLATFORM_RP2040_PATH)/c1_main.c

EXTRAINCDIRS += $(PLATFORM_RP2040_PATH)

#
# RP2040 optimized compiler intrinsics
##############################################################################

# The RP2040 sdk provides optimized compiler intrinsics which override the GCC
# built-ins. Some of these functions are located in the bootrom of the RP2040.
# Execution of these functions is realized via a vtable that is populated on
# bootup. This mechanism needs startup code and linker script support from
# ChibiOS, which is currently not implemented thus these functions are disabled
# ATM.
PICOSDKINTRINSICSSRC =  $(PICOSDKROOT)/src/rp2_common/pico_divider/divider_hardware.S \
                        $(PICOSDKROOT)/src/rp2_common/pico_int64_ops/pico_int64_ops_aeabi.S

PICOSDKINTRINSICSINC =  $(PICOSDKROOT)/src/common/pico_base/include \
                        $(PICOSDKROOT)/src/rp2_common/pico_platform/include \
                        $(PICOSDKROOT)/src/rp2_common/hardware_divider/include

# integer division intrinsics utilizing the RP2040 hardware divider
OPT_DEFS += -DPICO_DIVIDER_IN_RAM=1
OPT_DEFS += -DPICO_RP2040
OPT_DEFS += -DPICO_DIVIDER_DISABLE_INTERRUPTS=1

CFLAGS += -Wl,--wrap=__aeabi_idiv
CFLAGS += -Wl,--wrap=__aeabi_idivmod
CFLAGS += -Wl,--wrap=__aeabi_ldivmod
CFLAGS += -Wl,--wrap=__aeabi_uidiv
CFLAGS += -Wl,--wrap=__aeabi_uidivmod
CFLAGS += -Wl,--wrap=__aeabi_uldivmod

# 64bit integer intrinsics
OPT_DEFS += -DPICO_INT64_OPS_IN_RAM=1

CFLAGS += -Wl,--wrap=__aeabi_lmul

PLATFORM_SRC += $(PICOSDKINTRINSICSSRC)
EXTRAINCDIRS += $(PICOSDKINTRINSICSINC)
