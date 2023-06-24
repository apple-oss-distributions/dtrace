/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
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

#include <ctf_impl.h>
#include <assert.h>

static int
ctf_type_compat_helper(ctf_file_t*, ctf_id_t, ctf_file_t*,  ctf_id_t, int);

uint32_t
get_type_ctt_info(const ctf_file_t *fp, const void *tp)
{
    if (fp->ctf_version < CTF_VERSION_4)
        return ((const ctf_type_v1_t *)tp)->ctt_info;

    return ((const ctf_type_t *)tp)->ctt_info;
}

uint32_t
get_type_ctt_type(const ctf_file_t *fp, const void *tp)
{
    if (fp->ctf_version < CTF_VERSION_4)
        return ((const ctf_type_v1_t *)tp)->ctt_type;

    return ((const ctf_type_t *)tp)->ctt_type;
}

uint32_t
get_type_ctt_name(const ctf_file_t *fp, const void *tp)
{
    if (fp->ctf_version < CTF_VERSION_4)
        return ((const ctf_type_v1_t *)tp)->ctt_name;

    return ((const ctf_type_t *)tp)->ctt_name;
}

uint32_t
get_type_ctt_size(const ctf_file_t *fp, const void *tp)
{
    if (fp->ctf_version < CTF_VERSION_4)
        return ((const ctf_type_v1_t *)tp)->ctt_size;

    return ((const ctf_type_t *)tp)->ctt_size;
}

uint64_t
ctf_get_ctt_lsize(const ctf_file_t *fp, const void *tp)
{
    if (fp->ctf_version < CTF_VERSION_4)
        return CTF_TYPE_LSIZE((const ctf_type_v1_t *)tp);

    return CTF_TYPE_LSIZE((ctf_type_t *)tp);
}

ssize_t
ctf_get_ctt_size(const ctf_file_t *fp, const void *tp, ssize_t *sizep,
    ssize_t *incrementp)
{
	ssize_t size, increment;

	if (fp->ctf_version > CTF_VERSION_1 &&
	    get_type_ctt_size(fp, tp) == LCTF_LSIZE_SENT(fp)) {
        size = ctf_get_ctt_lsize(fp, tp);
        increment = (fp->ctf_version < CTF_VERSION_4) ? sizeof (ctf_type_v1_t) : sizeof (ctf_type_t);
	} else {
        size = get_type_ctt_size(fp, tp);
        increment = (fp->ctf_version < CTF_VERSION_4) ? sizeof (ctf_stype_v1_t) : sizeof (ctf_stype_t);
    }

	if (sizep)
		*sizep = size;
	if (incrementp)
		*incrementp = increment;

	return (size);
}

/*
 * Iterate over the members of a STRUCT or UNION.  We pass the name, member
 * type, and offset of each member to the specified callback function.
 */
int
ctf_member_iter(ctf_file_t *fp, ctf_id_t type, ctf_member_f *func, void *arg)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	ssize_t size, increment;
	uint32_t kind, n;
	int rc;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (CTF_ERR); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	(void) ctf_get_ctt_size(fp, tp, &size, &increment);
	kind = LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp));

	if (kind != CTF_K_STRUCT && kind != CTF_K_UNION)
		return (ctf_set_errno(ofp, ECTF_NOTSOU));

	if (fp->ctf_version == CTF_VERSION_1 || size < CTF_LSTRUCT_THRESH) {
        if (fp->ctf_version < CTF_VERSION_4) {
            const ctf_member_v1_t *mp = (const ctf_member_v1_t *)
                ((uintptr_t)tp + increment);

            for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
                const char *name = ctf_strptr(fp, mp->ctm_name);
                if ((rc = func(name, mp->ctm_type, mp->ctm_offset,
                    arg)) != 0)
                    return (rc);
            }
        } else {
            const ctf_member_t *mp = (const ctf_member_t *)
                ((uintptr_t)tp + increment);

            for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
                const char *name = ctf_strptr(fp, mp->ctm_name);
                if ((rc = func(name, mp->ctm_type, mp->ctm_offset,
                    arg)) != 0)
                    return (rc);
            }
        }

	} else {
		if (fp->ctf_version < CTF_VERSION_4) {
			const ctf_lmember_v1_t *lmp = (const ctf_lmember_v1_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				const char *name = ctf_strptr(fp, lmp->ctlm_name);
				if ((rc = func(name, lmp->ctlm_type,
					(unsigned long)CTF_LMEM_OFFSET(lmp), arg)) != 0)
					return (rc);
			}
		} else {
			const ctf_lmember_t *lmp = (const ctf_lmember_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				const char *name = ctf_strptr(fp, lmp->ctlm_name);
				if ((rc = func(name, lmp->ctlm_type,
					(unsigned long)CTF_LMEM_OFFSET(lmp), arg)) != 0)
					return (rc);
			}
		}
	}

	return (0);
}

/*
 * Iterate over the members of an ENUM.  We pass the string name and associated
 * integer value of each enum element to the specified callback function.
 */
int
ctf_enum_iter(ctf_file_t *fp, ctf_id_t type, ctf_enum_f *func, void *arg)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	const ctf_enum_t *ep;
	ssize_t increment;
	uint32_t n;
	int rc;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (CTF_ERR); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	if (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)) != CTF_K_ENUM)
		return (ctf_set_errno(ofp, ECTF_NOTENUM));

	(void) ctf_get_ctt_size(fp, tp, NULL, &increment);

	ep = (const ctf_enum_t *)((uintptr_t)tp + increment);

	for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, ep++) {
		const char *name = ctf_strptr(fp, ep->cte_name);
		if ((rc = func(name, ep->cte_value, arg)) != 0)
			return (rc);
	}

	return (0);
}

/*
 * Iterate over every root (user-visible) type in the given CTF container.
 * We pass the type ID of each type to the specified callback function.
 */
int
ctf_type_iter(ctf_file_t *fp, ctf_type_f *func, void *arg)
{
	ctf_id_t id, max = fp->ctf_typemax;
	int rc, child = (fp->ctf_flags & LCTF_CHILD);

	for (id = 1; id <= max; id++) {
		const void *tp = LCTF_INDEX_TO_TYPEPTR(fp, id);
		if (CTF_INFO_ISROOT(get_type_ctt_info(fp, tp)) &&
		    (rc = func(LCTF_INDEX_TO_TYPE(fp, id, child), arg)) != 0)
			return (rc);
	}

	return (0);
}

/*
 * Follow a given type through the graph for TYPEDEF, VOLATILE, CONST, and
 * RESTRICT nodes until we reach a "base" type node.  This is useful when
 * we want to follow a type ID to a node that has members or a size.  To guard
 * against infinite loops, we implement simplified cycle detection and check
 * each link against itself, the previous node, and the topmost node.
 */
ctf_id_t
ctf_type_resolve(ctf_file_t *fp, ctf_id_t type)
{
	ctf_id_t prev = type, otype = type;
	ctf_file_t *ofp = fp;
	const void *tp;

	while ((tp = ctf_lookup_by_id(&fp, type)) != NULL) {
		switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
		case CTF_K_TYPEDEF:
		case CTF_K_VOLATILE:
		case CTF_K_CONST:
		case CTF_K_RESTRICT:
			if (get_type_ctt_type(fp, tp) == type || get_type_ctt_type(fp, tp) == otype ||
			    get_type_ctt_type(fp, tp) == prev) {
				ctf_dprintf("type %ld cycle detected\n", otype);
				return (ctf_set_errno(ofp, ECTF_CORRUPT));
			}
			prev = type;
			type = get_type_ctt_type(fp, tp);
			break;
		default:
			return (type);
		}
	}

	return (CTF_ERR); /* errno is set for us */
}

/*
 * Lookup the given type ID and print a string name for it into buf.  Return
 * the actual number of bytes (not including \0) needed to format the name.
 */
ssize_t
ctf_type_lname(ctf_file_t *fp, ctf_id_t type, char *buf, size_t len)
{
	ctf_decl_t cd;
	ctf_decl_node_t *cdp;
	ctf_decl_prec_t prec, lp, rp;
	int ptr, arr;
	uint32_t k;

	if (fp == NULL && type == CTF_ERR)
		return (-1); /* simplify caller code by permitting CTF_ERR */

	ctf_decl_init(&cd, buf, len);
	ctf_decl_push(&cd, fp, type);

	if (cd.cd_err != 0) {
		ctf_decl_fini(&cd);
		return (ctf_set_errno(fp, cd.cd_err));
	}

	/*
	 * If the type graph's order conflicts with lexical precedence order
	 * for pointers or arrays, then we need to surround the declarations at
	 * the corresponding lexical precedence with parentheses.  This can
	 * result in either a parenthesized pointer (*) as in int (*)() or
	 * int (*)[], or in a parenthesized pointer and array as in int (*[])().
	 */
	ptr = cd.cd_order[CTF_PREC_POINTER] > CTF_PREC_POINTER;
	arr = cd.cd_order[CTF_PREC_ARRAY] > CTF_PREC_ARRAY;

	rp = arr ? CTF_PREC_ARRAY : ptr ? CTF_PREC_POINTER : -1;
	lp = ptr ? CTF_PREC_POINTER : arr ? CTF_PREC_ARRAY : -1;

	k = CTF_K_POINTER; /* avoid leading whitespace (see below) */

	for (prec = CTF_PREC_BASE; prec < CTF_PREC_MAX; prec++) {
		for (cdp = ctf_list_next(&cd.cd_nodes[prec]);
		    cdp != NULL; cdp = ctf_list_next(cdp)) {

			ctf_file_t *rfp = fp;
			const void *tp =
			    ctf_lookup_by_id(&rfp, cdp->cd_type);
			const char *name = ctf_strptr(rfp, get_type_ctt_name(rfp, tp));

			if (k != CTF_K_POINTER && k != CTF_K_ARRAY)
				ctf_decl_sprintf(&cd, " ");

			if (lp == prec) {
				ctf_decl_sprintf(&cd, "(");
				lp = -1;
			}

			switch (cdp->cd_kind) {
			case CTF_K_INTEGER:
			case CTF_K_FLOAT:
			case CTF_K_TYPEDEF:
				ctf_decl_sprintf(&cd, "%s", name);
				break;
			case CTF_K_POINTER:
				ctf_decl_sprintf(&cd, "*");
				break;
			case CTF_K_ARRAY:
				ctf_decl_sprintf(&cd, "[%u]", cdp->cd_n);
				break;
			case CTF_K_FUNCTION:
				ctf_decl_sprintf(&cd, "()");
				break;
			case CTF_K_STRUCT:
			case CTF_K_FORWARD:
				ctf_decl_sprintf(&cd, "struct %s", name);
				break;
			case CTF_K_UNION:
				ctf_decl_sprintf(&cd, "union %s", name);
				break;
			case CTF_K_ENUM:
				ctf_decl_sprintf(&cd, "enum %s", name);
				break;
			case CTF_K_VOLATILE:
				ctf_decl_sprintf(&cd, "volatile");
				break;
			case CTF_K_CONST:
				ctf_decl_sprintf(&cd, "const");
				break;
			case CTF_K_RESTRICT:
				ctf_decl_sprintf(&cd, "restrict");
				break;
			case CTF_K_PTRAUTH:
				ctf_decl_sprintf(&cd, "ptrauth");
				break;
			}

			k = cdp->cd_kind;
		}

		if (rp == prec)
			ctf_decl_sprintf(&cd, ")");
	}

	if (cd.cd_len >= len)
		(void) ctf_set_errno(fp, ECTF_NAMELEN);

	ctf_decl_fini(&cd);
	return (cd.cd_len);
}

/*
 * Lookup the given type ID and print a string name for it into buf.  If buf
 * is too small, return NULL: the ECTF_NAMELEN error is set on 'fp' for us.
 */
char *
ctf_type_name(ctf_file_t *fp, ctf_id_t type, char *buf, size_t len)
{
	ssize_t rv = ctf_type_lname(fp, type, buf, len);
	return (rv >= 0 && rv < len ? buf : NULL);
}

/*
 * Resolve the type down to a base type node, and then return the size
 * of the type storage in bytes.
 */
ssize_t
ctf_type_size(ctf_file_t *fp, ctf_id_t type)
{
	const void *tp;
	ssize_t size;
	ctf_arinfo_t ar;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (-1); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (-1); /* errno is set for us */

	switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
	case CTF_K_POINTER:
	case CTF_K_PTRAUTH:
		return (fp->ctf_dmodel->ctd_pointer);

	case CTF_K_FUNCTION:
		return (0); /* function size is only known by symtab */

	case CTF_K_ARRAY:
		/*
		 * Array size is not directly returned by stabs data.  Instead,
		 * it defines the element type and requires the user to perform
		 * the multiplication.  If ctf_get_ctt_size() returns zero, the
		 * current version of ctfconvert does not compute member sizes
		 * and we compute the size here on its behalf.
		 */
		if ((size = ctf_get_ctt_size(fp, tp, NULL, NULL)) > 0)
			return (size);

		if (ctf_array_info(fp, type, &ar) == CTF_ERR ||
		    (size = ctf_type_size(fp, ar.ctr_contents)) == CTF_ERR)
			return (-1); /* errno is set for us */

		return (size * ar.ctr_nelems);

	default:
		return (ctf_get_ctt_size(fp, tp, NULL, NULL));
	}
}

/*
 * Resolve the type down to a base type node, and then return the alignment
 * needed for the type storage in bytes.
 */
ssize_t
ctf_type_align(ctf_file_t *fp, ctf_id_t type)
{
	const void *tp;
	ctf_arinfo_t r;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (-1); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (-1); /* errno is set for us */

	switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
	case CTF_K_POINTER:
	case CTF_K_PTRAUTH:
	case CTF_K_FUNCTION:
		return (fp->ctf_dmodel->ctd_pointer);

	case CTF_K_ARRAY:
		if (ctf_array_info(fp, type, &r) == CTF_ERR)
			return (-1); /* errno is set for us */
		return (ctf_type_align(fp, r.ctr_contents));

	case CTF_K_STRUCT:
	case CTF_K_UNION: {
		uint32_t n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp));
		ssize_t size, increment;
		size_t align = 0;
		const void *vmp;

		(void) ctf_get_ctt_size(fp, tp, &size, &increment);
		vmp = (uint8_t *)tp + increment;

		if (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)) == CTF_K_STRUCT)
			n = MIN(n, 1); /* only use first member for structs */

		if (fp->ctf_version == CTF_VERSION_1 ||
		    size < CTF_LSTRUCT_THRESH) {

            if (fp->ctf_version == CTF_VERSION_4) {
                const ctf_member_t *mp = vmp;
                for (; n != 0; n--, mp++) {
                    ssize_t am = ctf_type_align(fp, mp->ctm_type);
                    align = MAX(align, am);
                }
            } else {
                const ctf_member_v1_t *mp = vmp;
                for (; n != 0; n--, mp++) {
                    ssize_t am = ctf_type_align(fp, mp->ctm_type);
                    align = MAX(align, am);
                }
            }
		} else {
			if (fp->ctf_version == CTF_VERSION_4) {
				const ctf_lmember_t *lmp = vmp;
				for (; n != 0; n--, lmp++) {
					ssize_t am = ctf_type_align(fp, lmp->ctlm_type);
					align = MAX(align, am);
				}
			} else {
				const ctf_lmember_v1_t *lmp = vmp;
				for (; n != 0; n--, lmp++) {
					ssize_t am = ctf_type_align(fp, lmp->ctlm_type);
					align = MAX(align, am);
				}
			}
		}

		return (align);
	}

	default:
		return (ctf_get_ctt_size(fp, tp, NULL, NULL));
	}
}

/*
 * Return the kind (CTF_K_* constant) for the specified type ID.
 */
int
ctf_type_kind(ctf_file_t *fp, ctf_id_t type)
{
	const void *tp;

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	return (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)));
}

/*
 * If the type is one that directly references another type (such as POINTER),
 * then return the ID of the type to which it refers.
 */
ctf_id_t
ctf_type_reference(ctf_file_t *fp, ctf_id_t type)
{
	ctf_file_t *ofp = fp;
	const void *tp;

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
	case CTF_K_POINTER:
	case CTF_K_PTRAUTH:
	case CTF_K_TYPEDEF:
	case CTF_K_VOLATILE:
	case CTF_K_CONST:
	case CTF_K_RESTRICT:
		return (get_type_ctt_type(fp, tp));
	default:
		return (ctf_set_errno(ofp, ECTF_NOTREF));
	}
}

/*
 * Find a pointer to type by looking in fp->ctf_ptrtab.  If we can't find a
 * pointer to the given type, see if we can compute a pointer to the type
 * resulting from resolving the type down to its base type and use that
 * instead.  This helps with cases where the CTF data includes "struct foo *"
 * but not "foo_t *" and the user accesses "foo_t *" in the debugger.
 */
ctf_id_t
ctf_type_pointer(ctf_file_t *fp, ctf_id_t type)
{
	ctf_file_t *ofp = fp;
	ctf_id_t ntype;

	if (ctf_lookup_by_id(&fp, type) == NULL)
		return (CTF_ERR); /* errno is set for us */

	if ((ntype = fp->ctf_ptrtab[LCTF_TYPE_TO_INDEX(fp, type)]) != 0)
		return (LCTF_INDEX_TO_TYPE(fp, ntype, (fp->ctf_flags & LCTF_CHILD)));

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (ctf_set_errno(ofp, ECTF_NOTYPE));

	if (ctf_lookup_by_id(&fp, type) == NULL)
		return (ctf_set_errno(ofp, ECTF_NOTYPE));

	if ((ntype = fp->ctf_ptrtab[LCTF_TYPE_TO_INDEX(fp, type)]) != 0)
		return (LCTF_INDEX_TO_TYPE(fp, ntype, (fp->ctf_flags & LCTF_CHILD)));

	return (ctf_set_errno(ofp, ECTF_NOTYPE));
}

/*
 * Return the encoding for the specified INTEGER or FLOAT.
 */
int
ctf_type_encoding(ctf_file_t *fp, ctf_id_t type, ctf_encoding_t *ep)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	ssize_t increment;
	uint32_t data;

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	(void) ctf_get_ctt_size(fp, tp, NULL, &increment);

	switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
	case CTF_K_INTEGER:
		data = *(const uint32_t *)((uintptr_t)tp + increment);
		ep->cte_format = CTF_INT_ENCODING(data);
		ep->cte_offset = CTF_INT_OFFSET(data);
		ep->cte_bits = CTF_INT_BITS(data);
		break;
	case CTF_K_FLOAT:
		data = *(const uint32_t *)((uintptr_t)tp + increment);
		ep->cte_format = CTF_FP_ENCODING(data);
		ep->cte_offset = CTF_FP_OFFSET(data);
		ep->cte_bits = CTF_FP_BITS(data);
		break;
	default:
		return (ctf_set_errno(ofp, ECTF_NOTINTFP));
	}

	return (0);
}

int
ctf_type_ptrauth(ctf_file_t *fp, ctf_id_t type, ctf_ptrauth_t *pta)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	ssize_t increment = SSIZE_MAX;
	uint32_t data;

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR);

	(void) ctf_get_ctt_size(fp, tp, NULL, &increment);
	assert(increment != SSIZE_MAX);

	switch (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp))) {
	case CTF_K_PTRAUTH:
		data = *(const uint32_t *)((uintptr_t)tp + increment);
		pta->ctp_key = CTF_PTRAUTH_KEY(data);
		pta->ctp_discriminator = CTF_PTRAUTH_DISCRIMINATOR(data);
		pta->ctp_discriminated = CTF_PTRAUTH_DISCRIMINATED(data);
		break;
	default:
		return (ctf_set_errno(ofp, ECTF_NOTPTRAUTH));
	}

	return (0);
}

int
ctf_type_cmp(ctf_file_t *lfp, ctf_id_t ltype, ctf_file_t *rfp, ctf_id_t rtype)
{
	int rval;

	if (ltype < rtype)
		rval = -1;
	else if (ltype > rtype)
		rval = 1;
	else
		rval = 0;

	if (lfp == rfp)
		return (rval);

	if (LCTF_TYPE_ISPARENT(lfp, ltype) && lfp->ctf_parent != NULL)
		lfp = lfp->ctf_parent;

	if (LCTF_TYPE_ISPARENT(rfp, rtype) && rfp->ctf_parent != NULL)
		rfp = rfp->ctf_parent;

	if (lfp < rfp)
		return (-1);

	if (lfp > rfp)
		return (1);

	return (rval);
}

/*
 * Return a boolean value indicating if two types are compatible integers or
 * floating-pointer values.  This function returns true if the two types are
 * the same, or if they have the same ASCII name and encoding properties.
 * This function could be extended to test for compatibility for other kinds.
 */
int
ctf_type_compat(ctf_file_t *lfp, ctf_id_t ltype, ctf_file_t *rfp, ctf_id_t rtype)
{
	return ctf_type_compat_helper(lfp, ltype, rfp, rtype, 1);
}

/*
 * This is a less pedantic version of ctf_type_compat.  For printf
 * compatibility, the function does not need the type to have the
 * same type.  Calling this function will only check for encoding
 * compatibility.
 */
int
ctf_type_printf_compat(ctf_file_t *lfp, ctf_id_t ltype, ctf_file_t *rfp, ctf_id_t rtype)
{
	return ctf_type_compat_helper(lfp, ltype, rfp, rtype, 0);
}


int
ctf_type_compat_helper(ctf_file_t *lfp, ctf_id_t ltype, ctf_file_t *rfp,  ctf_id_t rtype, int nameMustMatch)
{
	const void *ltp, *rtp;
	ctf_encoding_t le, re;
	ctf_arinfo_t la, ra;
	uint32_t lkind, rkind;

	if (ctf_type_cmp(lfp, ltype, rfp, rtype) == 0)
		return (1);

	ltype = ctf_type_resolve(lfp, ltype);
	lkind = ctf_type_kind(lfp, ltype);

	rtype = ctf_type_resolve(rfp, rtype);
	rkind = ctf_type_kind(rfp, rtype);

	ltp = ctf_lookup_by_id(&lfp, ltype);
	rtp = ctf_lookup_by_id(&rfp, rtype);

	if (nameMustMatch) {
		if (lkind != rkind || ltp == NULL || rtp == NULL ||
		    strcmp(ctf_strptr(lfp, get_type_ctt_name(lfp, ltp)), ctf_strptr(rfp, get_type_ctt_name(rfp, rtp))) != 0)
			return (0);
	}

	switch (lkind) {
	case CTF_K_INTEGER:
	case CTF_K_FLOAT:
		return (ctf_type_encoding(lfp, ltype, &le) == 0 &&
		    ctf_type_encoding(rfp, rtype, &re) == 0 &&
		    bcmp(&le, &re, sizeof (ctf_encoding_t)) == 0);
	case CTF_K_PTRAUTH:
		ltype = ctf_type_reference(lfp, ltype);
		/*FALLTHRU*/
	case CTF_K_POINTER:
		if (rkind == CTF_K_PTRAUTH)
			rtype = ctf_type_reference(rfp, rtype);
		return (ctf_type_compat(lfp, ctf_type_reference(lfp, ltype),
		    rfp, ctf_type_reference(rfp, rtype)));
	case CTF_K_ARRAY:
		return (ctf_array_info(lfp, ltype, &la) == 0 &&
		    ctf_array_info(rfp, rtype, &ra) == 0 &&
		    la.ctr_nelems == ra.ctr_nelems && ctf_type_compat(
		    lfp, la.ctr_contents, rfp, ra.ctr_contents) &&
		    ctf_type_compat(lfp, la.ctr_index, rfp, ra.ctr_index));
	case CTF_K_STRUCT:
	case CTF_K_UNION:
		return (ctf_type_size(lfp, ltype) == ctf_type_size(rfp, rtype));
	case CTF_K_ENUM:
	case CTF_K_FORWARD:
		return (1); /* no other checks required for these type kinds */
	default:
		return (0); /* should not get here since we did a resolve */
	}
}

static int
_ctf_member_info(ctf_file_t *fp, ctf_id_t type, const char *name, unsigned long off,
    ctf_membinfo_t *mip)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	ssize_t size, increment;
	uint32_t kind, n;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (CTF_ERR); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	(void) ctf_get_ctt_size(fp, tp, &size, &increment);
	kind = LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp));

	if (kind != CTF_K_STRUCT && kind != CTF_K_UNION)
		return (ctf_set_errno(ofp, ECTF_NOTSOU));

	if (fp->ctf_version == CTF_VERSION_1 || size < CTF_LSTRUCT_THRESH) {
		if (fp->ctf_version == CTF_VERSION_4) {
			const ctf_member_t *mp = (const ctf_member_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
				if (mp->ctm_name == 0 &&
					_ctf_member_info(fp, mp->ctm_type, name,
					mp->ctm_offset + off, mip) == 0)
					return (0);
				if (strcmp(ctf_strptr(fp, mp->ctm_name), name) == 0) {
					mip->ctm_type = mp->ctm_type;
					mip->ctm_offset = mp->ctm_offset + off;
					return (0);
				}
			}
		} else {
			const ctf_member_v1_t *mp = (const ctf_member_v1_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
				if (mp->ctm_name == 0 &&
					_ctf_member_info(fp, mp->ctm_type, name,
					mp->ctm_offset + off, mip) == 0)
					return (0);
				if (strcmp(ctf_strptr(fp, mp->ctm_name), name) == 0) {
					mip->ctm_type = mp->ctm_type;
					mip->ctm_offset = mp->ctm_offset + off;
					return (0);
				}
			}
		}
	} else {
		if (fp->ctf_version == CTF_VERSION_4) {
			const ctf_lmember_t *lmp = (const ctf_lmember_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				if (lmp->ctlm_name == 0 &&
					_ctf_member_info(fp, lmp->ctlm_name, name,
					(unsigned long)CTF_LMEM_OFFSET(lmp) + off, mip) == 0)
					return (0);
				if (strcmp(ctf_strptr(fp, lmp->ctlm_name), name) == 0) {
					mip->ctm_type = lmp->ctlm_type;
					mip->ctm_offset =
						(unsigned long)CTF_LMEM_OFFSET(lmp) + off;
					return (0);
				}
			}
		} else {
			const ctf_lmember_v1_t *lmp = (const ctf_lmember_v1_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				if (lmp->ctlm_name == 0 &&
					_ctf_member_info(fp, lmp->ctlm_name, name,
					(unsigned long)CTF_LMEM_OFFSET(lmp) + off, mip) == 0)
					return (0);
				if (strcmp(ctf_strptr(fp, lmp->ctlm_name), name) == 0) {
					mip->ctm_type = lmp->ctlm_type;
					mip->ctm_offset =
						(unsigned long)CTF_LMEM_OFFSET(lmp) + off;
					return (0);
				}
			}
		}
	}

	return (ctf_set_errno(ofp, ECTF_NOMEMBNAM));
}

/*
 * Return the type and offset for a given member of a STRUCT or UNION.
 */
int
ctf_member_info(ctf_file_t *fp, ctf_id_t type, const char *name,
    ctf_membinfo_t *mip)
{

	return (_ctf_member_info(fp, type, name, 0, mip));
}

/*
 * Return the array type, index, and size information for the specified ARRAY.
 */
int
ctf_array_info(ctf_file_t *fp, ctf_id_t type, ctf_arinfo_t *arp)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	ssize_t increment;

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

    if (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)) != CTF_K_ARRAY)
        return (ctf_set_errno(ofp, ECTF_NOTARRAY));

	(void) ctf_get_ctt_size(fp, tp, NULL, &increment);

	if (fp->ctf_version == CTF_VERSION_4) {
		const ctf_array_t *ap = (const ctf_array_t *)((uintptr_t)tp + increment);
		arp->ctr_contents = ap->cta_contents;
		arp->ctr_index = ap->cta_index;
		arp->ctr_nelems = ap->cta_nelems;
	} else {
		const ctf_array_v1_t *ap = (const ctf_array_v1_t *)((uintptr_t)tp + increment);
		arp->ctr_contents = ap->cta_contents;
		arp->ctr_index = ap->cta_index;
		arp->ctr_nelems = ap->cta_nelems;
	}

	return (0);
}

/*
 * Convert the specified value to the corresponding enum member name, if a
 * matching name can be found.  Otherwise NULL is returned.
 */
const char *
ctf_enum_name(ctf_file_t *fp, ctf_id_t type, int value)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	const ctf_enum_t *ep;
	ssize_t increment;
	uint32_t n;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (NULL); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (NULL); /* errno is set for us */

	if (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)) != CTF_K_ENUM) {
		(void) ctf_set_errno(ofp, ECTF_NOTENUM);
		return (NULL);
	}

	(void) ctf_get_ctt_size(fp, tp, NULL, &increment);

	ep = (const ctf_enum_t *)((uintptr_t)tp + increment);

	for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, ep++) {
		if (ep->cte_value == value)
			return (ctf_strptr(fp, ep->cte_name));
	}

	(void) ctf_set_errno(ofp, ECTF_NOENUMNAM);
	return (NULL);
}

/*
 * Convert the specified enum tag name to the corresponding value, if a
 * matching name can be found.  Otherwise CTF_ERR is returned.
 */
int
ctf_enum_value(ctf_file_t *fp, ctf_id_t type, const char *name, int *valp)
{
	ctf_file_t *ofp = fp;
	const void *tp;
	const ctf_enum_t *ep;
	ssize_t size, increment;
	uint32_t n;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (CTF_ERR); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	if (LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp)) != CTF_K_ENUM) {
		(void) ctf_set_errno(ofp, ECTF_NOTENUM);
		return (CTF_ERR);
	}

	(void) ctf_get_ctt_size(fp, tp, &size, &increment);

	ep = (const ctf_enum_t *)((uintptr_t)tp + increment);

	for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, ep++) {
		if (strcmp(ctf_strptr(fp, ep->cte_name), name) == 0) {
			if (valp != NULL)
				*valp = ep->cte_value;
			return (0);
		}
	}

	(void) ctf_set_errno(ofp, ECTF_NOENUMNAM);
	return (CTF_ERR);
}

/*
 * Recursively visit the members of any type.  This function is used as the
 * engine for ctf_type_visit, below.  We resolve the input type, recursively
 * invoke ourself for each type member if the type is a struct or union, and
 * then invoke the callback function on the current type.  If any callback
 * returns non-zero, we abort and percolate the error code back up to the top.
 */
static int
ctf_type_rvisit(ctf_file_t *fp, ctf_id_t type, ctf_visit_f *func, void *arg,
    const char *name, unsigned long offset, int depth)
{
	ctf_id_t otype = type;
	const void *tp;
	ssize_t size, increment;
	uint32_t kind, n;
	int rc;

	if ((type = ctf_type_resolve(fp, type)) == CTF_ERR)
		return (CTF_ERR); /* errno is set for us */

	if ((tp = ctf_lookup_by_id(&fp, type)) == NULL)
		return (CTF_ERR); /* errno is set for us */

	if ((rc = func(name, otype, offset, depth, arg)) != 0)
		return (rc);

	kind = LCTF_INFO_KIND(fp, get_type_ctt_info(fp, tp));

	if (kind != CTF_K_STRUCT && kind != CTF_K_UNION)
		return (0);

	(void) ctf_get_ctt_size(fp, tp, &size, &increment);

	if (fp->ctf_version == CTF_VERSION_1 || size < CTF_LSTRUCT_THRESH) {
        if (fp->ctf_version == CTF_VERSION_4) {
            const ctf_member_t *mp = (const ctf_member_t *)
                ((uintptr_t)tp + increment);

            for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
                if ((rc = ctf_type_rvisit(fp, mp->ctm_type,
                    func, arg, ctf_strptr(fp, mp->ctm_name),
                    offset + mp->ctm_offset, depth + 1)) != 0)
                    return (rc);
            }
        } else {
            const ctf_member_v1_t *mp = (const ctf_member_v1_t *)
                ((uintptr_t)tp + increment);

            for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, mp++) {
                if ((rc = ctf_type_rvisit(fp, mp->ctm_type,
                    func, arg, ctf_strptr(fp, mp->ctm_name),
                    offset + mp->ctm_offset, depth + 1)) != 0)
                    return (rc);
            }
        }
	} else {
		if (fp->ctf_version == CTF_VERSION_4) {
			const ctf_lmember_t *lmp = (const ctf_lmember_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				if ((rc = ctf_type_rvisit(fp, lmp->ctlm_type,
					func, arg, ctf_strptr(fp, lmp->ctlm_name),
					offset + (unsigned long)CTF_LMEM_OFFSET(lmp),
					depth + 1)) != 0)
					return (rc);
			}
		} else {
			const ctf_lmember_v1_t *lmp = (const ctf_lmember_v1_t *)
				((uintptr_t)tp + increment);

			for (n = LCTF_INFO_VLEN(fp, get_type_ctt_info(fp, tp)); n != 0; n--, lmp++) {
				if ((rc = ctf_type_rvisit(fp, lmp->ctlm_type,
					func, arg, ctf_strptr(fp, lmp->ctlm_name),
					offset + (unsigned long)CTF_LMEM_OFFSET(lmp),
					depth + 1)) != 0)
					return (rc);
			}
		}
	}

	return (0);
}

/*
 * Recursively visit the members of any type.  We pass the name, member
 * type, and offset of each member to the specified callback function.
 */
int
ctf_type_visit(ctf_file_t *fp, ctf_id_t type, ctf_visit_f *func, void *arg)
{
	return (ctf_type_rvisit(fp, type, func, arg, "", 0, 0));
}
