#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#
# This script tests that the proc:::exec probe fires, followed by the
# proc:::exec-success probe (in a successful exec(2)).
#
# If this fails, the script will run indefinitely; it relies on the harness
# to time it out.
#
script()
{
	$dtrace -xstatusrate=200ms -s /dev/stdin <<EOF
	int pids[int];

	proc:::exec
	/curpsinfo->pr_ppid == $child && args[0] == "/bin/sleep"/
	{
		pids[curpsinfo->pr_pid] = 1;
		trace("proc:::exec\n");
	}

	proc:::exec-success
	/pids[curpsinfo->pr_pid]/
	{
		exit(0);
	}
EOF
}

sleeper()
{
	while true; do
		/bin/sleep 1
	done
}

dtrace=/usr/sbin/dtrace

sleeper &
child=$!

script
status=$?

kill $child
exit $status
