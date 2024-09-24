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
 * Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

/*
 * Routines for manipulating tdesc and tdata structures
 */

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <pthread.h>

#include "ctftools.h"
#include "memory.h"
#include "traverse.h"

/*
 * The layout hash is used during the equivalency checking.  We have a node in
 * the child graph that may be equivalent to a node in the parent graph.  To
 * find the corresponding node (if any) in the parent, we need a quick way to
 * get to all nodes in the parent that look like the node in the child.  Since a
 * large number of nodes don't have names, we need to incorporate the layout of
 * the node into the hash.  If we don't, we'll end up with the vast majority of
 * nodes in bucket zero, with one or two nodes in each of the remaining buckets.
 *
 * There are a couple of constraints, both of which concern forward
 * declarations.  Recall that a forward declaration tdesc is equivalent to a
 * tdesc that actually defines the structure or union.  As such, we cannot
 * incorporate anything into the hash for a named struct or union node that
 * couldn't be found by looking at the forward, and vice versa.
 */
int
tdesc_layouthash(int nbuckets, void *node)
{
	tdesc_t *tdp = node;
	atom_t *name = ATOM_NULL;
	ulong_t h = 0;

	if (tdp->t_name)
		name = tdp->t_name;
	else {
		switch (tdp->t_type) {
		case POINTER:
		case TYPEDEF:
		case VOLATILE:
		case CONST:
		case RESTRICT:
			name = tdp->t_tdesc->t_name;
			break;
		case PTRAUTH:
			name = tdp->t_ptrauth->pta_type->t_name;
			break;
		case FUNCTION:
			h = tdp->t_fndef->fn_nargs +
			    tdp->t_fndef->fn_vargs;
			name = tdp->t_fndef->fn_ret->t_name;
			break;
		case ARRAY:
			h = tdp->t_ardef->ad_nelems;
			name = tdp->t_ardef->ad_contents->t_name;
			break;
		case STRUCT:
		case UNION:
			/*
			 * Unnamed structures, which cannot have forward
			 * declarations pointing to them.  We can therefore
			 * incorporate the name of the first member into
			 * the hash value.
			 */
			if (tdp->t_members != NULL) {
				name = tdp->t_members->ml_name;
			}
			break;
		case ENUM:
			/* Use the first element in the hash value */
			name = tdp->t_emem->el_name;
			break;
		default:
			/*
			 * Intrinsics, forwards, and typedefs all have
			 * names.
			 */
			warning("Unexpected unnamed %d tdesc (ID %d)\n",
			    tdp->t_type, tdp->t_id);
		}
	}

	if (name)
		h = atom_hash(name);

	return (h % nbuckets);
}

int
tdesc_layoutcmp(void *arg1, void *arg2)
{
	tdesc_t *tdp1 = arg1, *tdp2 = arg2;

	if (tdp1->t_name == tdp2->t_name)
		return 0;
	if (tdp1->t_name == ATOM_NULL)
		return (-1);
	if (tdp2->t_name == ATOM_NULL)
		return (1);
	return (strcmp(tdp1->t_name->value, tdp2->t_name->value));
}

int
tdesc_idhash(int nbuckets, void *data)
{
	tdesc_t *tdp = data;

	return (tdp->t_id % nbuckets);
}

int
tdesc_idcmp(void *arg1, void *arg2)
{
	tdesc_t *tdp1 = arg1, *tdp2 = arg2;

	if (tdp1->t_id == tdp2->t_id)
		return (0);
	else
		return (tdp1->t_id > tdp2->t_id ? 1 : -1);
}

int
tdesc_namehash(int nbuckets, void *data)
{
	tdesc_t *tdp = data;
	ulong_t h, g;
	const char *c;

	if (tdp->t_name == ATOM_NULL)
		return (0);

	for (h = 0, c = tdp->t_name->value; *c; c++) {
		h = (h << 4) + *c;
		if ((g = (h & 0xf0000000)) != 0) {
			h ^= (g >> 24);
			h ^= g;
		}
	}

	return (h % nbuckets);
}

int
tdesc_namecmp(void *arg1, void *arg2)
{
	tdesc_t *tdp1 = arg1, *tdp2 = arg2;

	return tdp1->t_name != tdp2->t_name;
}

/*ARGSUSED1*/
int
tdesc_print(void *data, void *private)
{
	tdesc_t *tdp = data;

	printf("%7d %s\n", tdp->t_id, tdesc_name(tdp));

	return (1);
}

static void
free_intr(tdesc_t *tdp)
{
	free(tdp->t_intr);
}

static void
free_ardef(tdesc_t *tdp)
{
	free(tdp->t_ardef);
}

static void
free_fundef(tdesc_t *tdp)
{
	free(tdp->t_fndef);
}

static void
free_mlist(tdesc_t *tdp)
{
	mlist_t *ml = tdp->t_members;
	mlist_t *oml;

	while (ml) {
		oml = ml;
		ml = ml->ml_next;
		free(oml);
	}
}

static void
free_elist(tdesc_t *tdp)
{
	elist_t *el = tdp->t_emem;
	elist_t *oel;

	while (el) {
		oel = el;
		el = el->el_next;
		free(oel);
	}
}

static void (*free_cbs[])(tdesc_t *) = {
	NULL,
	free_intr,	/* intrinsic */
	NULL,		/* pointer */
	free_ardef,	/* array */
	free_fundef,	/* function */
	free_mlist,	/* struct */
	free_mlist,	/* union */
	free_elist,	/* enum */
	NULL,		/* forward */
	NULL,		/* typedef */
	NULL,		/* typedef_unres */
	NULL,		/* volatile */
	NULL,		/* const */
	NULL,		/* restrict */
	NULL		/* ptrauth */
};

/*ARGSUSED1*/
static int
tdesc_free_cb(tdesc_t *tdp, void *private)
{
	if (free_cbs[tdp->t_type])
		free_cbs[tdp->t_type](tdp);
	free(tdp);

	return (1);
}

void
tdesc_free(tdesc_t *tdp)
{
	(void) tdesc_free_cb(tdp, NULL);
}

static int
tdata_label_cmp(void *e1, void *e2)
{
	labelent_t *le1 = e1;
	labelent_t *le2 = e2;
	return (le1->le_idx - le2->le_idx);
}

void
tdata_label_add(tdata_t *td, char *label, int idx)
{
	labelent_t *le = xmalloc(sizeof (*le));

	le->le_name = atom_get(label);
	le->le_idx = (idx == -1 ? td->td_nextid - 1 : idx);

	array_add(&td->td_labels, le);
}

labelent_t *
tdata_label_top(tdata_t *td)
{
	array_sort(td->td_labels, tdata_label_cmp);
	return array_get(td->td_labels, -1);
}

static int
tdata_label_newmax_cb(void *data, void *arg)
{
	labelent_t *le = data;
	int *newmaxp = arg;

	if (le->le_idx > *newmaxp) {
		le->le_idx = *newmaxp;
		return (1);
	}

	return (0);
}

int
tdata_label_iter(tdata_t *td, int (*cb)(labelent_t *, void *), void *priv)
{
	array_sort(td->td_labels, tdata_label_cmp);
	return array_iter(td->td_labels, (int(*)())cb, priv);
}

void
tdata_label_newmax(tdata_t *td, int newmax)
{
	(void) array_iter(td->td_labels, tdata_label_newmax_cb, &newmax);
}

/*ARGSUSED1*/
static void
tdata_label_free_cb(void *le, void *private)
{
	free(le);
}

void
tdata_label_free(tdata_t *td)
{
	array_free(&td->td_labels, tdata_label_free_cb, NULL);
}

tdata_t *
tdata_new(void)
{
	tdata_t *new = xcalloc(sizeof (tdata_t));

	new->td_layouthash = hash_new(TDATA_LAYOUT_HASH_SIZE, tdesc_layouthash,
	    tdesc_layoutcmp);
	new->td_idhash = hash_new(TDATA_ID_HASH_SIZE, tdesc_idhash,
	    tdesc_idcmp);
	/*
	 * This is also traversed as a list, but amortized O(1)
	 * lookup massively impacts part of the merge phase, so
	 * we store the iidescs as a hash.
	 */
	new->td_iihash = hash_new(IIDESC_HASH_SIZE, iidesc_hash, NULL);
	new->td_nextid = 1;
	new->td_curvgen = 1;

	pthread_mutex_init(&new->td_mergelock, NULL);

	return (new);
}

void
tdata_free(tdata_t *td)
{
	hash_free(td->td_iihash, (void (*)())iidesc_free, NULL);
	hash_free(td->td_layouthash, (void (*)())tdesc_free_cb, NULL);
	hash_free(td->td_idhash, NULL, NULL);

	tdata_label_free(td);

	pthread_mutex_destroy(&td->td_mergelock);

	free(td);
}

/*ARGSUSED1*/
static int
build_hashes(tdesc_t *ctdp, tdesc_t **ctdpp, void *private)
{
	tdata_t *td = private;

	hash_add(td->td_idhash, ctdp);
	hash_add(td->td_layouthash, ctdp);

	return (1);
}

static tdtrav_cb_f build_hashes_cbs[] = {
	NULL,
	build_hashes,	/* intrinsic */
	build_hashes,	/* pointer */
	build_hashes,	/* array */
	build_hashes,	/* function */
	build_hashes,	/* struct */
	build_hashes,	/* union */
	build_hashes,	/* enum */
	build_hashes,	/* forward */
	build_hashes,	/* typedef */
	tdtrav_assert,	/* typedef_unres */
	build_hashes,	/* volatile */
	build_hashes,	/* const */
	build_hashes,	/* restrict */
	build_hashes	/* ptrauth */
};

static void
tdata_build_hashes_common(tdata_t *td, hash_t *hash)
{
	(void) iitraverse_hash(hash, &td->td_curvgen, NULL, NULL,
	    build_hashes_cbs, td);
}

void
tdata_build_hashes(tdata_t *td)
{
	tdata_build_hashes_common(td, td->td_iihash);
}

/* Merge td2 into td1.  td2 is destroyed by the merge */
void
tdata_merge(tdata_t *td1, tdata_t *td2)
{
	td1->td_curemark = MAX(td1->td_curemark, td2->td_curemark);
	td1->td_curvgen = MAX(td1->td_curvgen, td2->td_curvgen);
	td1->td_nextid = MAX(td1->td_nextid, td2->td_nextid);

	hash_merge(td1->td_iihash, td2->td_iihash);

	/* Add td2's type tree to the hashes */
	tdata_build_hashes_common(td1, td2->td_iihash);

	array_concat(&td1->td_labels, &td2->td_labels);

	/* free the td2 hashes (data is now part of td1) */

	hash_free(td2->td_layouthash, NULL, NULL);
	td2->td_layouthash = NULL;

	hash_free(td2->td_iihash, NULL, NULL);
	td2->td_iihash = NULL;

	tdata_free(td2);
}
