#include <dt_impl.h>
#include <dt_provider.h>
#include <ctype.h>
#include <TargetConditionals.h>
#include <mach/machine.h>

#if TARGET_OS_EMBEDDED
#include <sys/sysctl.h>
#else
#include <sys/csr.h>
#endif

int
dt_probe_noprobe_errno(dtrace_hdl_t *dtp, dtrace_probedesc_t *pdp)
{
	dt_provider_t *pvp;
	/*
	 * If the provider is a userspace process provider (aka, it terminates
	 * with a number and has DTRACE_PRIV_PROC if it exists), just return
	 * EDT_NOPROBE to indicate we could not find the probe
	 */
	if (isdigit(pdp->dtpd_provider[strlen(pdp->dtpd_provider) - 1]) &&
		((pvp = dt_provider_lookup(dtp, pdp->dtpd_provider)) == NULL ||
		 pvp->pv_desc.dtvd_priv.dtpp_flags & DTRACE_PRIV_PROC)) {
		return EDT_NOPROBE;
	}
	/*
	 * Set a different error if DTrace is restricted on the device.
	 * On embedded, this means the -unsafe_kernel_text boot-arg was not set
	 * On macOS, this means that System Integrity Protection is on
	 *
	 * This does not mean that we did not find the probe because DTrace is
	 * restricted (since we have no way of knowing whether the probe would
	 * actually exist).
	 */

#if !TARGET_OS_EMBEDDED
	if (csr_check(CSR_ALLOW_UNRESTRICTED_DTRACE) != 0) {
		return EDT_PROBE_RESTRICTED;
	}
#else
#endif

	return EDT_NOPROBE;
}

