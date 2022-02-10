#pragma once

#include "ruby/internal/config.h"

#ifdef __linux__
// Normally,  gcc(1)  translates  calls to alloca() with inlined code.  This is not done when either the -ansi, -std=c89, -std=c99, or the -std=c11 option is given and the header <alloca.h> is not included.
# include <alloca.h>
#endif

#include "eval_intern.h"
#include "gc.h"
#include "hrtime.h"
#include "internal.h"
#include "internal/class.h"
#include "internal/cont.h"
#include "internal/error.h"
#include "internal/hash.h"
#include "internal/io.h"
#include "internal/object.h"
#include "internal/proc.h"
#include "ruby/fiber/scheduler.h"
#include "internal/signal.h"
#include "internal/thread.h"
#include "internal/time.h"
#include "internal/warnings.h"
#include "iseq.h"
#include "mjit.h"
#include "ruby/debug.h"
#include "ruby/io.h"
#include "ruby/thread.h"
#include "ruby/thread_native.h"
#include "timev.h"
#include "vm_core.h"
#include "ractor_core.h"
#include "vm_debug.h"
#include "vm_sync.h"

#define RUBY_VM_CHECK_INTS_BLOCKING(ec) vm_check_ints_blocking(ec)
static inline int vm_check_ints_blocking(rb_execution_context_t *ec);
static int sleep_hrtime(rb_thread_t *, rb_hrtime_t, unsigned int fl);
static void native_sleep(rb_thread_t *th, rb_hrtime_t *rel);
static void rb_check_deadlock(rb_ractor_t *r);
static void rb_thread_sleep_deadly_allow_spurious_wakeup(VALUE blocker);
