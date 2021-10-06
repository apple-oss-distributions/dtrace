/*

  Copyright (C) 2000,2002,2004 Silicon Graphics, Inc.  All Rights Reserved.

  This program is free software; you can redistribute it and/or modify it
  under the terms of version 2.1 of the GNU Lesser General Public License 
  as published by the Free Software Foundation.

  This program is distributed in the hope that it would be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

  Further, this software is distributed without any warranty that it is
  free of the rightful claim of any third person regarding infringement 
  or the like.  Any license provided herein, whether implied or 
  otherwise, applies only to this software file.  Patent licenses, if
  any, provided herein do not apply to combinations of this program with 
  other software, or any other product whatsoever.  

  You should have received a copy of the GNU Lesser General Public 
  License along with this program; if not, write the Free Software 
  Foundation, Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, 
  USA.

  Contact information:  Silicon Graphics, Inc., 1500 Crittenden Lane,
  Mountain View, CA 94043, or:

  http://www.sgi.com

  For further information regarding this notice, see:

  http://oss.sgi.com/projects/GenInfo/NoticeExplan

*/


#ifdef HAVE_ELF_H
#include <elf.h>
#elif defined(HAVE_LIBELF_H) 
/* On one platform without elf.h this gets Elf32_Rel 
   type defined (a required type). */
#include <libelf.h>
#endif

/* The target address is given: the place in the source integer
   is to be determined.
*/
#ifdef WORDS_BIGENDIAN
#define WRITE_UNALIGNED(dbg,dest,source, srclength,len_out) \
    { \
      dbg->de_copy_word(dest, \
                        ((char *)source) +srclength-len_out,  \
			len_out) ; \
    }


#else /* LITTLE ENDIAN */

#define WRITE_UNALIGNED(dbg,dest,source, srclength,len_out) \
    { \
      dbg->de_copy_word( (dest) , \
                        ((char *)source) ,  \
			len_out) ; \
    }
#endif



#include "libdwarf.h"

#include "dwarf.h"
#include "pro_opaque.h"
#include "pro_error.h"
#include "pro_util.h"
#include "pro_encode_nm.h"
#include "pro_alloc.h"
