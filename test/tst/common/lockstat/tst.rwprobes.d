/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright 2019 Apple, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

/*
 * ASSERTION:
 * 	Check the presence and trigger of lockstat rw lock probes
 */

int probes[string];

BEGIN
/ `MutexSpin > 100000 /
{
	/*
	 * On virtual machines, the adaptive spinning timeout is set to a
	 * high-enough value that block probes may never trigger
	 */
	probes["rw-block"] = 2;
}

lockstat:::rw-acquire,
lockstat:::rw-block,
lockstat:::rw-spin,
lockstat:::rw-release,
lockstat:::rw-upgrade,
lockstat:::rw-downgrade
{
	probes[probename] = 1
}


tick-500ms
/ probes["rw-acquire"] &&
  probes["rw-block"] &&
  probes["rw-spin"] &&
  probes["rw-release"] &&
  probes["rw-upgrade"] &&
  probes["rw-downgrade"] /
{
	exit(0);
}

tick-120s
{
	printf("rw-acquire: %d\n", probes["rw-acquire"]);
	printf("rw-block: %d\n", probes["rw-block"]);
	printf("rw-spin: %d\n", probes["rw-spin"]);
	printf("rw-release: %d\n", probes["rw-release"]);
	printf("rw-upgrade: %d\n", probes["rw-upgrade"]);
	printf("rw-downgrade: %d\n", probes["rw-downgrade"]);
	exit(1);
}
