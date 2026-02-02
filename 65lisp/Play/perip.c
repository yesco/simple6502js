/* This example uses the peripheral support in sim65.h */

#include <stdio.h>
#include <sim65.h>

static void print_current_counters(void)
{
    peripherals.counter.latch = 0; /* latch values */

    peripherals.counter.select = COUNTER_SELECT_CLOCKCYCLE_COUNTER;
    printf("clock cycles ............... : %08lx %08lx\n", peripherals.counter.value32[1], peripherals.counter.value32[0]);
    peripherals.counter.select = COUNTER_SELECT_INSTRUCTION_COUNTER;
    printf("instructions ............... : %08lx %08lx\n", peripherals.counter.value32[1], peripherals.counter.value32[0]);
    peripherals.counter.select = COUNTER_SELECT_WALLCLOCK_TIME;
    printf("wallclock time ............. : %08lx %08lx\n", peripherals.counter.value32[1], peripherals.counter.value32[0]);
    peripherals.counter.select = COUNTER_SELECT_WALLCLOCK_TIME_SPLIT;
    printf("wallclock time, split ...... : %08lx %08lx\n", peripherals.counter.value32[1], peripherals.counter.value32[0]);
    printf("\n");
}

int main(void)
{
    print_current_counters();
    print_current_counters();
    return 0;
}
