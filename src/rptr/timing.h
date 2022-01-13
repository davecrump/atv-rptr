#ifndef __TIMING_H__
#define __TIMING_H__

#include <stdint.h>
#include <stdbool.h>

uint64_t monotonic_ms(void);

uint64_t timestamp_ms(void);

void sleep_ms(uint32_t _duration);

void sleep_ms_or_signal(uint32_t _duration, bool *app_exit_ptr);

#endif /* __TIMING_H__ */
