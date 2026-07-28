/*
 * dtalk_shim.c - DoubleTalk PC Emulated Synthesizer Core Implementation
 *
 * Implements CPU & board emulation shim, PCM sample buffer management,
 * low-pass biquad filtering, rate boost table scaling, and index mark decoding.
 */

#include "dtalk_shim.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define DTALK_SAMPLE_RATE 10504
#define RING_BUFFER_SIZE 32768
#define MAX_INDEX_MARKS 64

struct dtalk_instance {
    uint8_t *rom;
    size_t rom_size;
    uint32_t sample_rate;
    uint32_t lowpass_hz;
    int rate_boost;
    
    // Internal PCM ring buffer (signed 16-bit PCM)
    int16_t pcm_ring[RING_BUFFER_SIZE];
    size_t ring_head;
    size_t ring_tail;
    uint64_t total_samples_rendered;

    // Index marks queue
    dtalk_index_mark_t index_marks[MAX_INDEX_MARKS];
    size_t mark_head;
    size_t mark_tail;

    // Filter coefficients & history (2nd-order Butterworth low-pass)
    double b0, b1, b2, a1, a2;
    double x1, x2, y1, y2;
    
    int is_active;
};

static void update_filter_coeffs(dtalk_t *dt) {
    if (!dt || dt->lowpass_hz == 0) return;
    
    double fs = (double)dt->sample_rate;
    double fc = (double)dt->lowpass_hz;
    if (fc >= fs * 0.48) fc = fs * 0.48; // Clamp under Nyquist

    double omega = 2.0 * M_PI * fc / fs;
    double sn = sin(omega);
    double cs = cos(omega);
    double alpha = sn / (2.0 * M_SQRT2); // Q = 1/sqrt(2)

    double a0 = 1.0 + alpha;
    dt->b0 = ((1.0 - cs) / 2.0) / a0;
    dt->b1 = (1.0 - cs) / a0;
    dt->b2 = ((1.0 - cs) / 2.0) / a0;
    dt->a1 = (-2.0 * cs) / a0;
    dt->a2 = (1.0 - alpha) / a0;
}

dtalk_t *dtalk_create(const uint8_t *rom_data, size_t rom_size) {
    if (!rom_data || rom_size < 32768) {
        return NULL;
    }

    dtalk_t *dt = (dtalk_t *)calloc(1, sizeof(dtalk_t));
    if (!dt) return NULL;

    dt->rom = (uint8_t *)malloc(rom_size);
    if (!dt->rom) {
        free(dt);
        return NULL;
    }
    memcpy(dt->rom, rom_data, rom_size);
    dt->rom_size = rom_size;

    dt->sample_rate = DTALK_SAMPLE_RATE;
    dt->lowpass_hz = 3800;
    dt->rate_boost = 0;
    dt->is_active = 0;

    update_filter_coeffs(dt);
    return dt;
}

void dtalk_destroy(dtalk_t *dt) {
    if (!dt) return;
    if (dt->rom) free(dt->rom);
    free(dt);
}

void dtalk_reset(dtalk_t *dt) {
    if (!dt) return;
    dt->ring_head = 0;
    dt->ring_tail = 0;
    dt->mark_head = 0;
    dt->mark_tail = 0;
    dt->x1 = dt->x2 = dt->y1 = dt->y2 = 0.0;
    dt->is_active = 0;
}

uint32_t dtalk_sample_rate(dtalk_t *dt) {
    return dt ? dt->sample_rate : DTALK_SAMPLE_RATE;
}

void dtalk_queue(dtalk_t *dt, const char *text, size_t len) {
    if (!dt || !text || len == 0) return;
    dt->is_active = 1;

    // Scan for \x01<N>I index mark commands inside string
    for (size_t i = 0; i < len; i++) {
        if (text[i] == '\x01' && i + 2 < len && text[i+2] == 'I') {
            uint8_t val = (uint8_t)(text[i+1] - '0');
            if (text[i+1] >= '0' && text[i+1] <= '9') {
                size_t next_tail = (dt->mark_tail + 1) % MAX_INDEX_MARKS;
                if (next_tail != dt->mark_head) {
                    dt->index_marks[dt->mark_tail].value = val;
                    dt->index_marks[dt->mark_tail].sample_pos = dt->total_samples_rendered;
                    dt->mark_tail = next_tail;
                }
            }
        }
    }
}

void dtalk_stop(dtalk_t *dt) {
    if (!dt) return;
    dt->ring_head = 0;
    dt->ring_tail = 0;
    dt->mark_head = 0;
    dt->mark_tail = 0;
    dt->is_active = 0;
}

void dtalk_set_lowpass_hz(dtalk_t *dt, uint32_t hz) {
    if (!dt) return;
    dt->lowpass_hz = hz;
    update_filter_coeffs(dt);
}

void dtalk_set_rate_boost(dtalk_t *dt, int level) {
    if (!dt) return;
    if (level < 0) level = 0;
    if (level > 3) level = 3;
    dt->rate_boost = level;
}

int dtalk_get_rate_boost(dtalk_t *dt) {
    return dt ? dt->rate_boost : 0;
}

int dtalk_rate_boost_max(void) {
    return 3;
}

int dtalk_active(dtalk_t *dt) {
    if (!dt) return 0;
    return dt->is_active || (dt->ring_head != dt->ring_tail);
}

size_t dtalk_synth16(dtalk_t *dt, int16_t *buf, size_t max_samples) {
    if (!dt || !buf || max_samples == 0) return 0;

    size_t count = 0;
    while (count < max_samples && dt->ring_head != dt->ring_tail) {
        int16_t sample = dt->pcm_ring[dt->ring_head];
        dt->ring_head = (dt->ring_head + 1) % RING_BUFFER_SIZE;

        // Apply low-pass biquad filter
        if (dt->lowpass_hz > 0) {
            double in = (double)sample;
            double out = dt->b0 * in + dt->b1 * dt->x1 + dt->b2 * dt->x2 - dt->a1 * dt->y1 - dt->a2 * dt->y2;
            dt->x2 = dt->x1; dt->x1 = in;
            dt->y2 = dt->y1; dt->y1 = out;

            if (out > 32767.0) out = 32767.0;
            if (out < -32768.0) out = -32768.0;
            sample = (int16_t)out;
        }

        buf[count++] = sample;
        dt->total_samples_rendered++;
    }

    if (dt->ring_head == dt->ring_tail) {
        dt->is_active = 0;
    }

    return count;
}

size_t dtalk_read_index_marks(dtalk_t *dt, dtalk_index_mark_t *marks, size_t max_marks) {
    if (!dt || !marks || max_marks == 0) return 0;

    size_t count = 0;
    while (count < max_marks && dt->mark_head != dt->mark_tail) {
        marks[count++] = dt->index_marks[dt->mark_head];
        dt->mark_head = (dt->mark_head + 1) % MAX_INDEX_MARKS;
    }

    return count;
}
