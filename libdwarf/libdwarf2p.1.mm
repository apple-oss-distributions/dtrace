\." $Revision: 1.12 $
\." $Date: 2002/01/14 23:40:11 $
\."
\."
\." the following line may be removed if the ff ligature works on your machine
.lg 0
\." set up heading formats
.ds HF 3 3 3 3 3 2 2
.ds HP +2 +2 +1 +0 +0
.nr Hs 5
.nr Hb 5
\." ==============================================
\." Put current date in the following at each rev
.ds vE rev 1.18, 10 Jan 2002
\." ==============================================
\." ==============================================
.ds | |
.ds ~ ~
.ds ' '
.if t .ds Cw \&\f(CW
.if n .ds Cw \fB
.de Cf          \" Place every other arg in Cw font, beginning with first
.if \\n(.$=1 \&\*(Cw\\$1\fP
.if \\n(.$=2 \&\*(Cw\\$1\fP\\$2
.if \\n(.$=3 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP
.if \\n(.$=4 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4
.if \\n(.$=5 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4\*(Cw\\$5\fP
.if \\n(.$=6 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4\*(Cw\\$5\fP\\$6
.if \\n(.$=7 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4\*(Cw\\$5\fP\\$6\*(Cw\\$7\fP
.if \\n(.$=8 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4\*(Cw\\$5\fP\\$6\*(Cw\\$7\fP\\$8
.if \\n(.$=9 \&\*(Cw\\$1\fP\\$2\*(Cw\\$3\fP\\$4\*(Cw\\$5\fP\\$6\*(Cw\\$7\fP\\$8\
*(Cw
..
.nr Cl 3
.SA 1
.TL
A Producer Library Interface to DWARF
.AF ""
.AU "UNIX International Programming Languages Special Interest Group" 
.PF "'\*(vE '- \\\\nP -''"
.PM ""
.AS 1
This document describes an interface to a library of functions
.FS \(rg
UNIX is a registered trademark of UNIX System Laboratories, Inc.
in the United States and other countries.
.FE
to create DWARF debugging information entries and DWARF line number
information. It does not make recommendations as to how the functions
described in this document should be implemented nor does it
suggest possible optimizations. 
.P
The document is oriented to creating DWARF version 2.
It was intended be proposed to the PLSIG DWARF committee
but that committee is now dormant.
.P
The library interfaces documented 
in this document are subject to change.
.P
\*(vE 
.AE
.MT 4
.H 1 "INTRODUCTION"
This document describes the proposed interface to \f(CWlibdwarf\fP, a
library of functions to provide creation of DWARF debugging information
records, DWARF line number information, DWARF address range and
pubnames information, weak names information, and DWARF frame description 
information.

.H 2 "Purpose and Scope"
The purpose of this document is to propose a library of functions to 
create DWARF debugging information.  Reading (consuming) of such records 
is discussed in a separate document.

The functions in this document have been implemented at Silicon Graphics
and are being used by the code generator to provide debugging information.

.P
Additionally, the focus of this document is the functional interface,
and as such, implementation and optimization issues are
intentionally ignored.

.P
Error handling, error codes, and certain \f(CWLibdwarf\fP codes are discussed
in the "\fIProposed Interface to DWARF Consumer Library\fP", which should 
be read (or at least skimmed) before reading this document.

.H 2 "Definitions"
DWARF debugging information entries (DIEs) are the segments of information 
placed in the \f(CW.debug_info\fP  and related
sections by compilers, assemblers, and linkage 
editors that, in conjunction with line number entries, are necessary for 
symbolic source-level debugging.  
Refer to the document 
"\fIDWARF Debugging Information Format\fP" from UI PLSIG for a more complete 
description of these entries.

.P
This document adopts all the terms and definitions in
"\fIDWARF Debugging Information Format\fP" version 2.
and the "\fIProposed Interface to DWARF Consumer Library\fP".

.P
In addition, this document refers to Elf, the ATT/USL System V
Release 4 object format.
This is because the library was first developed for that object
format.
Hopefully the functions defined here can easily be
applied to other object formats.

.H 2 "Overview"
The remaining sections of this document describe a proposed producer 
(compiler or assembler) interface to \fILibdwarf\fP, first by describing 
the purpose of additional types defined by the interface, followed by 
descriptions of the available operations.  
This document assumes you 
are thoroughly familiar with the information contained in the 
\fIDWARF 
Debugging Information Format\fP document, and 
"\fIProposed Interface to DWARF Consumer Library\fP".

.P
The interface necessarily knows a little bit about the object format
(which is assumed to be Elf).  We make an attempt to make this knowledge 
as limited as possible.  For example, \fILibdwarf\fP does not do the 
writing of object data to the disk.  The producer program does that.

.H 2 "Revision History"
.VL 15
.LI "March 1993"
Work on dwarf2 sgi producer draft begins
.LI "March 1999"
Adding a function to allow any number of trips
thru the dwarf_get_section_bytes() call.
.LI "April 10 1999"
Added support for assembler text output of dwarf
(as when the output must pass thru an assembler).
Revamped internals for better performance and
simpler provision for differences in ABI.
.LI "Sep 1, 1999"
Added support for little- and cross- endian
debug info creation.
.LE

.H 1 "Type Definitions"

.H 2 "General Description"
The \fIlibdwarf.h\fP 
header file contains typedefs and preprocessor 
definitions of types and symbolic names 
used to reference objects of \fI Libdwarf \fP .  
The types defined by typedefs contained in \fI libdwarf.h\fP 
all use the convention of adding \fI Dwarf_ \fP 
as a prefix to
indicate that they refer to objects used by Libdwarf.  
The prefix \fI Dwarf_P_\fP is used for objects 
referenced by the \fI Libdwarf\fP 
Producer when there are similar but distinct 
objects used by the Consumer.

.H 2 "Namespace issues"
Application programs should avoid creating names
beginning with 
\f(CWDwarf_\fP
\f(CWdwarf_\fP
or 
\f(CWDW_\fP
as these are reserved to dwarf and libdwarf.

.H 1 "libdwarf and Elf and relocations"
Much of the description below presumes that Elf is the object
format in use.
The library is probably usable with other object formats
that allow arbitrary sections to be created.

.H 2 "binary or assembler output"
With 
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
(see below)
it is assumed that the calling app will simply
write the streams and relocations directly into
an Elf file, without going thru an assembler.

With 
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP 
the calling app must either 
A) generate binary relocation streams and write
the generated debug information streams and
the relocation streams direct to an elf file
or
B) generate assembler output text for an assembler
to read and produce an object file. 

With case B) the libdwarf-calling application must
use the relocation information to change
points of each binary stream into references to 
symbolic names.  
It is necessary for the assembler to be
willing to accept and generate relocations
for references from arbitrary byte boundaries.
For example:
.sp
.nf
.in +4
 .data 0a0bcc    #producing 3 bytes of data.
 .word mylabel   #producing a reference
 .word endlabel - startlable #producing absolute length
.in -4
.fi
.sp




.H 2 "libdwarf relationship to Elf"
When the documentation below refers to 'an elf section number'
it is really only dependent on getting (via the callback
function passed by the caller of
\f(CWdwarf_producer_init()\fP)
a sequence of integers back (with 1 as the lowest).

When the documentation below refers to 'an Elf symbol index'
it is really dependent on 
Elf symbol numbers
only if
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
are being generated (see below).
With 
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
the library is generating Elf relocations
and the section numbers in binary form so
the section numbers and symbol indices must really 
be Elf (or elf-like) numbers.


With
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP 
the values passed as symbol indexes can be any
integer set or even pointer set.
All that libdwarf assumes is that where values
are unique they get unique values.
Libdwarf does not generate any kind of symbol table
from the numbers and does not check their
uniqueness or lack thereof.

.H 2 "libdwarf and relocations"
With
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP 
libdwarf creates binary streams of debug information
and arrays of relocation information describing
the necessary relocation.
The Elf section numbers and symbol numbers appear
nowhere in the binary streams. Such appear
only in the relocation information and the passed-back
information from calls requesting the relocation information.
As a consequence, the 'symbol indices' can be
any pointer or integer value as the caller must
arrange that the output deal with relocations.

With 
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
all the relocations are directly created by libdwarf
as binary streams (libdwarf only creates the streams
in memory,
it does not write them to disk).

.H 2 "symbols, addresses, and offsets"
The following applies to calls that
pass in symbol indices, addresses, and offsets, such
as
\f(CWdwarf_add_AT_targ_address() \fP 
\f(CWdwarf_add_arange_b()\fP 
and
\f(CWdwarf_add_frame_fde_b()\fP.

With 
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
a passed in address is one of:
a) a section offset and the (non-global) symbol index of
a section symbol.
b) A symbol index (global symbol) and a zero offset.

With \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
the same approach can be used, or, instead,
a passed in address may be
c) a symbol handle and an offset.
In this case, since it is up to the calling app to
generate binary relocations (if appropriate)
or to turn the binary stream into 
a text stream (for input to an assembler, if appropriate)
the application has complete control of the interpretation
of the symbol handles.



.H 1 "Memory Management"

Several of the functions that comprise the \fILibdwarf\fP interface 
return values that have been dynamically allocated by the library.  
The dynamically allocated spaces 
can not be reclaimed except by \f(CWdwarf_producer_finish()\fP.  
This function is supposed to
reclaim all the space, and invalidate all descriptors 
returned from \f(CWLibdwarf\fP functions that add information to be 
object specified.  
After \f(CWdwarf_producer_finish()\fP is called, 
the \f(CWDwarf_P_Debug\fP descriptor specified is also invalid.

The present version of the producer library mostly
ignores memory management: it leaks memory a great deal.
For existing clients this is not a problem (they are
short lived) but is contrary to the intent, which was
that memory should be freed by \f(CWdwarf_producer_finish()\fP.

All data for a particular \f(CWDwarf_P_Debug\fP descriptor
is separate from the data for any other 
\f(CWDwarf_P_Debug\fP descriptor in use in the library-calling
application.

.H 2 "Read-only Properties"
All pointers returned by or as a result of a \fILibdwarf\fP call should 
be assumed to point to read-only memory.  
Except as defined by this document, the results are undefined for 
\fILibdwarf\fP clients that attempt to write to a region pointed to by a 
return value from a \fILibdwarf\fP call.

.H 2 "Storage Deallocation"
Calling \f(CWdwarf_producer_finish(dbg)\fP frees all the space, and 
invalidates all pointers returned from \f(CWLibdwarf\fP functions on 
or descended from \f(CWdbg\fP).

.H 1 "Functional Interface"
This section describes the functions available in the \fILibdwarf\fP
library.  Each function description includes its definition, followed 
by a paragraph describing the function's operation.

.P
The functions may be categorized into groups: 
\fIinitialization and termination operations\fP,
\fIdebugging information entry creation\fP,
\fIElf section callback function\fP,
\fIattribute creation\fP,
\fIexpression creation\fP, 
\fIline number creation\fP, 
\fIfast-access (aranges) creation\fP, 
\fIfast-access (pubnames) creation\fP, 
\fIfast-access (weak names) creation\fP,
\fImacro information creation\fP, 
\fIlow level (.debug_frame) creation\fP, 
and
\fIlocation list (.debug_loc) creation\fP. 

.P
The following sections describe these functions.

.H 2 "Initialization and Termination Operations"
These functions setup \f(CWLibdwarf\fP to accumulate debugging information
for an object, usually a compilation-unit, provided by the producer.
The actual addition of information is done by functions in the other
sections of this document.  Once all the information has been added,
functions from this section are used to transform the information to
appropriate byte streams, and help to write out the byte streams to
disk.

Typically then, a producer application 
would create a \f(CWDwarf_P_Debug\fP 
descriptor to gather debugging information for a particular
compilation-unit using \f(CWdwarf_producer_init()\fP.  
The producer application would 
use this \f(CWDwarf_P_Debug\fP descriptor to accumulate debugging 
information for this object using functions from other sections of 
this document.  
Once all the information had been added, it would 
call \f(CWdwarf_transform_to_disk_form()\fP to convert the accumulated 
information into byte streams in accordance with the \f(CWDWARF\fP 
standard.  
The application would then repeatedly call 
\f(CWdwarf_get_section_bytes()\fP 
for each of the \f(CW.debug_*\fP created.  
This gives the producer 
information about the data bytes to be written to disk.  
At this point, 
the producer would release all resource used by \f(CWLibdwarf\fP for 
this object by calling \f(CWdwarf_producer_finish()\fP.

It is also possible to create assembler-input character streams
from the byte streams created by this library.
This feature requires slightly different interfaces than
direct binary output.
The details are mentioned in the text.

.H 3 "dwarf_producer_init()"

.DS
\f(CWDwarf_P_Debug dwarf_producer_init(
        Dwarf_Unsigned flags,
        Dwarf_Callback_Func func,
        Dwarf_Handler errhand,
        Dwarf_Ptr errarg,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_producer_init() \fP returns a new 
\f(CWDwarf_P_Debug\fP descriptor that can be used to add \f(CWDwarf\fP 
information to the object.  
On error it returns \f(CWDW_DLV_BADADDR\fP.  
\f(CWflags\fP determine whether the target object is 64-bit or 32-bit.  
\f(CWfunc\fP is a pointer to a function called-back from \f(CWLibdwarf\fP 
whenever \f(CWLibdwarf\fP needs to create a new object section (as it will 
for each .debug_* section and related relocation section).  
\f(CWerrhand\fP 
is a pointer to a function that will be used for handling errors detected 
by \f(CWLibdwarf\fP.  \f(CWerrarg\fP is the default error argument used 
by the function pointed to by \f(CWerrhand\fP.
.P
The \f(CWflags\fP
values are as follows:
.in +4
\f(CWDW_DLC_WRITE\fP 
is required.
The values
\f(CWDW_DLC_READ\fP  
\f(CWDW_DLC_RDWR\fP
are not supported by the producer and must not be passed.

If 
\f(CWDW_DLC_SIZE_64\fP
is not OR'd into \f(CWflags\fP
then
\f(CWDW_DLC_SIZE_32\fP
is assumed.
Oring in both is an error.

If
\f(CWDW_DLC_ISA_IA64\fP
is not OR'd into \f(CWflags\fP
then 
\f(CWDW_DLC_ISA_MIPS\fP
is assumed.
Oring in both is an error.

If
\f(CWDW_DLC_TARGET_BIGENDIAN\fP
is not OR'd into \f(CWflags\fP
then 
endianness the same as the host is assumed.

If
\f(CWDW_DLC_TARGET_LITTLEENDIAN\fP
is not OR'd into \f(CWflags\fP
then 
endianness the same as the host is assumed.

If both 
\f(CWDW_DLC_TARGET_LITTLEENDIAN\fP
and
\f(CWDW_DLC_TARGET_BIGENDIAN\fP
are or-d in it is an error.



Either one of two output forms is specifiable:
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP .

The default is
\f(CWDW_DLC_STREAM_RELOCATIONS\fP . 
The
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
are relocations in a binary stream (as used
in a MIPS Elf object).

The
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
are the same relocations but expressed in an
array of structures defined by libdwarf,
which the caller of the relevant function
(see below) must deal with appropriately.
This method of expressing relocations allows 
the producer-application to easily produce
assembler text output of debugging information.


If
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
is OR'd into \f(CWflags\fP
then relocations are returned not as streams
but thru an array of structures.

.in -4
.P
The function \f(CWfunc\fP 
must be provided by the user of this library.
Its prototype is:
.DS
\f(CWtypedef int (*Dwarf_Callback_Func)(
    char* name,
    int                 size,
    Dwarf_Unsigned      type,
    Dwarf_Unsigned      flags,
    Dwarf_Unsigned      link,
    Dwarf_Unsigned      info,
    int*                sect_name_index,
    int*                error) \fP
.DE
For each section in the object file that \f(CWlibdwarf\fP
needs to create, it calls this function once, passing in
the section \f(CWname\fP, the section \f(CWtype\fP,
the section \f(CWflags\fP, the \f(CWlink\fP field, and
the \f(CWinfo\fP field.  
For an Elf object file these values
should be appropriate Elf section header values.
For example, for relocation callbacks, the \f(CWlink\fP
field is supposed to be set (by the app) to the index
of the symtab section (the link field passed thru the
callback must be ignored by the app).
And, for relocation callbacks, the \f(CWinfo\fP field
is passed as the elf section number of the section
the relocations apply to.

On success
the user function should return the Elf section number of the
newly created Elf section.
.P
On success, the function should also set the integer
pointed to by \f(CWsect_name_index\fP to the
Elf symbol number assigned in the Elf symbol table of the
new Elf section.
This symbol number is needed with relocations
dependent on the relocation of this new section.
Because "int *" is not guaranteed to work with elf 'symbols'
that are really pointers,
It is better to use the 
\f(CWdwarf_producer_init_b()\fP
interface.
.P
For example, the \f(CW.debug_line\fP section's third
data element (in a compilation unit) is the offset from the
beginning of the \f(CW.debug_info\fP section of the compilation
unit entry for this \f(CW.debug_line\fP set.
The relocation entry in \f(CW.rel.debug_line\fP
for this offset
must have the relocation symbol index of the 
symbol \f(CW.debug_info\fP  returned
by the callback of that section-creation through 
the pointer \f(CWsect_name_index\fP.
.P
On failure, the function should return -1 and set the \f(CWerror\fP
integer to an error code.
.P
Nothing in libdwarf actually depends on the section index
returned being a real Elf section.
The Elf section is simply useful for generating relocation
records.
Similarly, the Elf symbol table index returned thru 
the \f(CWsect_name_index\fP must simply be an index
that can be used in relocations against this section.
The application will probably want to note the
values passed to this function in some form, even if
no Elf file is being produced.

.H 3 "dwarf_producer_init_b()"

.DS
\f(CWDwarf_P_Debug dwarf_producer_init_b(
        Dwarf_Unsigned flags,
        Dwarf_Callback_Func_b func,
        Dwarf_Handler errhand,
        Dwarf_Ptr errarg,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_producer_init_b() \fP 
is the same as \f(CWdwarf_producer_init() \fP
except that the callback function uses
Dwarf_Unsigned rather than int as the
type of the symbol-index returned to libdwarf
thru the pointer argument (see below).
.P
The \f(CWflags\fP
values are as follows:
.in +4
\f(CWDW_DLC_WRITE\fP 
is required.
The values
\f(CWDW_DLC_READ\fP  
\f(CWDW_DLC_RDWR\fP
are not supported by the producer and must not be passed.

If 
\f(CWDW_DLC_SIZE_64\fP
is not OR'd into \f(CWflags\fP
then
\f(CWDW_DLC_SIZE_32\fP
is assumed.
Oring in both is an error.

If
\f(CWDW_DLC_ISA_IA64\fP
is not OR'd into \f(CWflags\fP
then 
\f(CWDW_DLC_ISA_MIPS\fP
is assumed.
Oring in both is an error.

Either one of two output forms are specifiable:
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP .
\f(CWdwarf_producer_init_b() \fP 
is usable with
either output form.

Either one of two output forms is specifiable:
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP .

The default is
\f(CWDW_DLC_STREAM_RELOCATIONS\fP .
The
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
are relocations in a binary stream (as used
in a MIPS Elf object).

\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
are OR'd into flags
to cause 
the same relocations to be expressed in an
array of structures defined by libdwarf,
which the caller of the relevant function
(see below) must deal with appropriately.
This method of expressing relocations allows
the producer-application to easily produce
assembler text output of debugging information.

.in -4
.P
The function \f(CWfunc\fP 
must be provided by the user of this library.
Its prototype is:
.DS
\f(CWtypedef int (*Dwarf_Callback_Func_b)(
    char* name,
    int                 size,
    Dwarf_Unsigned      type,
    Dwarf_Unsigned      flags,
    Dwarf_Unsigned      link,
    Dwarf_Unsigned      info,
    Dwarf_Unsigned*     sect_name_index,
    int*                error) \fP
.DE
For each section in the object file that \f(CWlibdwarf\fP
needs to create, it calls this function once, passing in
the section \f(CWname\fP, the section \f(CWtype\fP,
the section \f(CWflags\fP, the \f(CWlink\fP field, and
the \f(CWinfo\fP field.  For an Elf object file these values
should be appropriate Elf section header values.
For example, for relocation callbacks, the \f(CWlink\fP
field is supposed to be set (by the app) to the index
of the symtab section (the link field passed thru the
callback must be ignored by the app).
And, for relocation callbacks, the \f(CWinfo\fP field
is passed as the elf section number of the section
the relocations apply to.

On success
the user function should return the Elf section number of the
newly created Elf section.
.P
On success, the function should also set the integer
pointed to by \f(CWsect_name_index\fP to the
Elf symbol number assigned in the Elf symbol table of the
new Elf section.
This symbol number is needed with relocations
dependent on the relocation of this new section.
.P
For example, the \f(CW.debug_line\fP section's third
data element (in a compilation unit) is the offset from the
beginning of the \f(CW.debug_info\fP section of the compilation
unit entry for this \f(CW.debug_line\fP set.
The relocation entry in \f(CW.rel.debug_line\fP
for this offset
must have the relocation symbol index of the 
symbol \f(CW.debug_info\fP  returned
by the callback of that section-creation through 
the pointer \f(CWsect_name_index\fP.
.P
On failure, the function should return -1 and set the \f(CWerror\fP
integer to an error code.
.P
Nothing in libdwarf actually depends on the section index
returned being a real Elf section.
The Elf section is simply useful for generating relocation
records.
Similarly, the Elf symbol table index returned thru 
the \f(CWsect_name_index\fP must simply be an index
that can be used in relocations against this section.
The application will probably want to note the
values passed to this function in some form, even if
no Elf file is being produced.

Note that the \f(CWDwarf_Callback_Func_b() \fP form
passes back the sect_name_index as a Dwarf_Unsigned.
This is guaranteed large enough to hold a pointer.
(the other functional interfaces have versions with
the 'symbol index' as a Dwarf_Unsigned too. See below).

If \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
is in use, then the symbol index is simply an arbitrary
value (from the point of view of libdwarf) so the
caller can put anything in it:
a normal elf symbol index,
a pointer to a struct (with arbitrary contents)
(the caller must cast to/from Dwarf_Unsigned 
as appropriate), 
or some other kind of pointer or value.
The values show up in the 
output of \f(CWdwarf_get_relocation_info()\fP
(described below) and are not emitted anywhere else.

.H 3 "dwarf_transform_to_disk_form()"

.DS
\f(CWDwarf_Signed dwarf_transform_to_disk_form(
        Dwarf_P_Debug dbg,
        Dwarf_Error* error) \fP
.DE
The function \f(CWdwarf_transform_to_disk_form() \fP does the actual
conversion of the \f(CWDwarf\fP information provided so far, to the
form that is 
normally written out as \f(CWElf\fP sections.  
In other words, 
once all DWARF information has been passed to \f(CWLibdwarf\fP, call 
\f(CWdwarf_transform_to_disk_form() \fP to transform all the accumulated 
data into byte streams.  
This includes turning relocation information 
into byte streams (and possibly relocation arrays).  
This function does not write anything to disk.  If 
successful, it returns a count of the number of \f(CWElf\fP sections 
ready to be retrieved (and, normally, written to disk).
In case of error, it returns 
\f(CWDW_DLV_NOCOUNT\fP.


.H 3 "dwarf_get_section_bytes()"

.DS
\f(CWDwarf_Ptr dwarf_get_section_bytes(
        Dwarf_P_Debug dbg,
        Dwarf_Signed dwarf_section,
        Dwarf_Signed *elf_section_index, 
        Dwarf_Unsigned *length,
        Dwarf_Error* error)\fP
.DE
The function \f(CWdwarf_get_section_bytes() \fP must be called repetitively, 
with the index \f(CWdwarf_section\fP starting at 0 and continuing for the 
number of sections 
returned by \f(CWdwarf_transform_to_disk_form() \fP.
It returns \f(CWNULL\fP to indicate that there are no more sections of 
\f(CWDwarf\fP information.  
For each non-NULL return, the return value
points to \f(CW*length\fP bytes of data that are normally
added to the output 
object in \f(CWElf\fP section \f(CW*elf_section\fP by the producer application.
It is illegal to call these in any order other than 0 thru N-1 where
N is the number of dwarf sections
returned by \f(CWdwarf_transform_to_disk_form() \fP.
The \f(CWdwarf_section\fP
number is actually ignored: the data is returned as if the
caller passed in the correct dwarf_section numbers in the
required sequence.
The \f(CWerror\fP argument is not used.
.P
There is no requirement that the section bytes actually 
be written to an elf file.
For example, consider the .debug_info section and its
relocation section (the call back function would resulted in
assigning 'section' numbers and the link field to tie these
together (.rel.debug_info would have a link to .debug_info).
One could examine the relocations, split the .debug_info
data at relocation boundaries, emit byte streams (in hex)
as assembler output, and at each relocation point,
emit an assembler directive with a symbol name for the assembler.
Examining the relocations is awkward though. 
It is much better to use \f(CWdwarf_get_section_relocation_info() \fP
.P

The memory space of the section byte stream is freed
by the \f(CWdwarf_producer_finish() \fP call
(or would be if the \f(CWdwarf_producer_finish() \fP
was actually correct), along
with all the other space in use with that Dwarf_P_Debug.

.H 3 "dwarf_get_relocation_info_count()"
.DS
\f(CWint  dwarf_get_relocation_info_count(
        Dwarf_P_Debug dbg,
        Dwarf_Unsigned *count_of_relocation_sections ,
	int            *drd_buffer_version,
        Dwarf_Error* error)\fP
.DE
The function \f(CWdwarf_get_relocation_info() \fP
returns, thru  the pointer \f(CWcount_of_relocation_sections\fP, the
number of times that \f(CWdwarf_get_relocation_info() \fP
should be called.

The function \f(CWdwarf_get_relocation_info() \fP
returns DW_DLV_OK if the call was successful (the 
\f(CWcount_of_relocation_sections\fP is therefore meaningful,
though \f(CWcount_of_relocation_sections\fP
could be zero).

\f(CW*drd_buffer_version\fP
is the value 2.
If the structure pointed to by
the \f(CW*reldata_buffer\fP
changes this number will change.
The application should verify that the number is
the version it understands (that it matches
the value of DWARF_DRD_BUFFER_VERSION (from libdwarf.h)).
The value 1 version was never used in production 
MIPS libdwarf (version 1 did exist in source).

It returns DW_DLV_NO_ENTRY if 
\f(CWcount_of_relocation_sections\fP is not meaningful
because \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP was not
passed in the 
\f(CWdwarf_producer_init() \fP
(or
\f(CWdwarf_producer_init_b() \fP ) call.

It returns DW_DLV_ERROR if there was an error,
in which case
\f(CWcount_of_relocation_sections\fP is not meaningful.

.H 3 "dwarf_get_relocation_info()"
.DS
\f(CWint dwarf_get_relocation_info(
        Dwarf_P_Debug dbg,
        Dwarf_Signed *elf_section_index, 
	Dwarf_Signed *elf_section_index_link, 
        Dwarf_Unsigned *relocation_buffer_count,
	Dwarf_Relocation_Data *reldata_buffer,
        Dwarf_Error* error)\fP
.DE

The function \f(CWdwarf_get_relocation_info() \fP 
should normally be called repetitively, 
for the number of relocation sections that 
\f(CWdwarf_get_relocation_info_count() \fP
indicated exist.

It returns \f(CWDW_DLV_OK\fP to indicate that 
valid values are returned thru the pointer arguments.
The \f(CWerror\fP argument is not set.

It returns DW_DLV_NO_ENTRY if there are no entries
(the count of relocation arrays is zero.).
The \f(CWerror\fP argument is not set.

It returns \f(CWDW_DLV_ERROR\fP if there is an error.
Calling \f(CWdwarf_get_relocation_info() \fP
more than the number of times indicated by
\f(CWdwarf_get_relocation_info_count() \fP
(without an intervening call to
\f(CWdwarf_reset_section_bytes() \fP )
results in a return of \f(CWDW_DLV_ERROR\fP once past
the valid count.
The \f(CWerror\fP argument is set to indicate the error.

Now consider the returned-thru-pointer values for
\f(CWDW_DLV_OK\fP .

\f(CW*elf_section_index\fP
is the 'elf section index' of the section implied by
this group of relocations.


\f(CW*elf_section_index_link\fP
is the section index of the section that these
relocations apply to.

\f(CW*relocation_buffer_count\fP
is the number of array entries of relocation information
in the array pointed to by
\f(CW*reldata_buffer\fP .


\f(CW*reldata_buffer\fP
points to an array of 'struct Dwarf_Relocation_Data_s'
structures.

The version 2 array information is as follows:

.nf
enum Dwarf_Rel_Type {dwarf_drt_none,
                dwarf_drt_data_reloc,
                dwarf_drt_segment_rel,
                dwarf_drt_first_of_length_pair,
                dwarf_drt_second_of_length_pair
};
typedef struct Dwarf_Relocation_Data_s  * Dwarf_Relocation_Data;
struct Dwarf_Relocation_Data_s {
        unsigned char        drd_type;   /* contains Dwarf_Rel_Type */
	unsigned char        drd_length; /* typically 4 or 8 */
        Dwarf_Unsigned       drd_offset; /* where the data to reloc is */
        Dwarf_Unsigned       drd_symbol_index;
};

.fi

The \f(CWDwarf_Rel_Type\fP enum is encoded (via casts if necessary)
into the single unsigned char \f(CWdrd_type\fP field to control
the space used for this information (keep the space to 1 byte).

The unsigned char \f(CWdrd_length\fP field
holds the size in bytes of the field to be relocated.
So for elf32 object formats with 32 bit apps, \f(CWdrd_length\fP
will be 4.  For objects with MIPS -64 contents,
\f(CWdrd_length\fP will be 8.  
For some dwarf 64 bit environments, such as ia64, \f(CWdrd_length\fP
is 4 for some relocations (file offsets, for example) 
and 8 for others (run time
addresses, for example).

If \f(CWdrd_type\fP is \f(CWdwarf_drt_none\fP, this is an unused slot
and it should be ignored.

If \f(CWdrd_type\fP is \f(CWdwarf_drt_data_reloc\fP 
this is an ordinary relocation.
The relocation type means either
(R_MIPS_64) or (R_MIPS_32) (or the like for
the particular ABI.
f(CWdrd_length\fP gives the length of the field to be relocated.
\f(CWdrd_offset\fP is an offset (of the
value to be relocated) in
the section this relocation stuff is linked to.
\f(CWdrd_symbol_index\fP is the symbol index (if elf symbol
indices were provided) or the handle to arbitrary
information (if that is what the caller passed in 
to the relocation-creating dwarf calls) of the symbol
that the relocation is relative to.


When \f(CWdrd_type\fP is \f(CWdwarf_drt_first_of_length_pair\fP
the next data record will be \f(CWdrt_second_of_length_pair\fP
and the \f(CWdrd_offset\fP of the two data records will match.
The relevant 'offset' in the section this reloc applies to
should contain a symbolic pair like
.nf
.in +4
 .word    second_symbol - first_symbol
.in -4
.fi
to generate a length.
\f(CWdrd_length\fP gives the length of the field to be relocated.

\f(CWdrt_segment_rel\fP means (R_MIPS_SCN_DISP)
is the real relocation (R_MIPS_SCN_DISP applies to
exception tables and this part may need further work).
\f(CWdrd_length\fP gives the length of the field to be relocated.

.P
The memory space of the section byte stream is freed
by the \f(CWdwarf_producer_finish() \fP call
(or would be if the \f(CWdwarf_producer_finish() \fP
was actually correct), along
with all the other space in use with that Dwarf_P_Debug.

.H 3 "dwarf_reset_section_bytes()"

.DS
\f(CWvoid dwarf_reset_section_bytes(
        Dwarf_P_Debug dbg
        ) \fP
.DE
The function \f(CWdwarf_reset_section_bytes() \fP 
is used to reset the internal information so that
\f(CWdwarf_get_section_bytes() \fP will begin (on the next
call) at the initial dwarf section again.
It also resets so that calls to 
\f(CWdwarf_get_relocation_info() \fP
will begin again at the initial array of relocation information.

Some dwarf producers need to be able to run thru
the \f(CWdwarf_get_section_bytes()\fP
and/or
the \f(CWdwarf_get_relocation_info()\fP
calls more than once and this call makes additional 
passes possible.
The set of Dwarf_Ptr values returned is identical to the
set returned by the first pass.
It is acceptable to call this before finishing a pass
of \f(CWdwarf_get_section_bytes()\fP
or
\f(CWdwarf_get_relocation_info()\fP
calls.
No errors are possible as this just resets some
internal pointers.
It is unwise to call this before
\f(CWdwarf_transform_to_disk_form() \fP has been called.
.P

.H 3 "dwarf_producer_finish()"
.DS
\f(CWDwarf_Unsigned dwarf_producer_finish(
        Dwarf_P_Debug dbg,
        Dwarf_Error* error) \fP
.DE
The function \f(CWdwarf_producer_finish() \fP should be called after all 
the bytes of data have been copied somewhere
(normally the bytes are written to disk).  
It frees all dynamic space 
allocated for \f(CWdbg\fP, include space for the structure pointed to by
\f(CWdbg\fP.  
This should not be called till the data have been 
copied or written 
to disk or are no longer of interest.  
It returns non-zero if successful, and \f(CWDW_DLV_NOCOUNT\fP 
if there is an error.

.H 2 "Debugging Information Entry Creation"
The functions in this section add new \f(CWDIE\fPs to the object,
and also the relationships among the \f(CWDIE\fP to be specified
by linking them up as parents, children, left or right siblings
of each other.  
In addition, there is a function that marks the
root of the graph thus created.

.H 3 "dwarf_add_die_to_debug()"
.DS
\f(CWDwarf_Unsigned dwarf_add_die_to_debug(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die first_die,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_die_to_debug() \fP indicates to \f(CWLibdwarf\fP
the root \f(CWDIE\fP of the \f(CWDIE\fP graph that has been built so 
far.  
It is intended to mark the compilation-unit \f(CWDIE\fP for the 
object represented by \f(CWdbg\fP.  
The root \f(CWDIE\fP is specified 
by \f(CWfirst_die\fP.

It returns \f(CW0\fP on success, and \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_new_die()"
.DS
\f(CWDwarf_P_Die dwarf_new_die(
        Dwarf_P_Debug dbg, 
        Dwarf_Tag new_tag,
        Dwarf_P_Die parent,
        Dwarf_P_Die child,
        Dwarf_P_Die left_sibling, 
        Dwarf_P_Die right_sibling,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_new_die() \fP creates a new \f(CWDIE\fP with
its parent, child, left sibling, and right sibling \f(CWDIE\fPs
specified by \f(CWparent\fP, \f(CWchild\fP, \f(CWleft_sibling\fP,
and \f(CWright_sibling\fP, respectively.  
There is no requirement
that all of these \f(CWDIE\fPs be specified, i.e. any of these
descriptors may be \f(CWNULL\fP.  
If none is specified, this will
be an isolated \f(CWDIE\fP.  
A \f(CWDIE\fP is 
transformed to disk form by \f(CWdwarf_transform_to_disk_form() \fP 
only if there is a path from
the \f(CWDIE\fP specified by \f(CWdwarf_add_die_to_debug\fP to it.
This function returns \f(CWDW_DLV_BADADDR\fP on error.

\f(CWnew_tag\fP is the tag which is given to the new \f(CWDIE\fP.
\f(CWparent\fP, \f(CWchild\fP, \f(CWleft_sibling\fP, and
\f(CWright_sibling\fP are pointers to establish links to existing 
\f(CWDIE\fPs.  Only one of \f(CWparent\fP, \f(CWchild\fP, 
\f(CWleft_sibling\fP, and \f(CWright_sibling\fP may be non-NULL.
If \f(CWparent\fP (\f(CWchild\fP) is given, the \f(CWDIE\fP is 
linked into the list after (before) the \f(CWDIE\fP pointed to.  
If \f(CWleft_sibling\fP (\f(CWright_sibling\fP) is given, the 
\f(CWDIE\fP is linked into the list after (before) the \f(CWDIE\fP 
pointed to.

To add attributes to the new \f(CWDIE\fP, use the \f(CWAttribute Creation\fP 
functions defined in the next section.

.H 3 "dwarf_die_link()"
.DS
\f(CWDwarf_P_Die dwarf_die_link(
        Dwarf_P_Die die, 
        Dwarf_P_Die parent,
        Dwarf_P_Die child,
        Dwarf_P_Die left-sibling, 
        Dwarf_P_Die right_sibling,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_die_link() \fP links an existing \f(CWDIE\fP
described by the given \f(CWdie\fP to other existing \f(CWDIE\fPs.
The given \f(CWdie\fP can be linked to a parent \f(CWDIE\fP, a child
\f(CWDIE\fP, a left sibling \f(CWDIE\fP, or a right sibling \f(CWDIE\fP
by specifying non-NULL \f(CWparent\fP, \f(CWchild\fP, \f(CWleft_sibling\fP,
and \f(CWright_sibling\fP \f(CWDwarf_P_Die\fP descriptors.  
It returns
the given \f(CWDwarf_P_Die\fP descriptor, \f(CWdie\fP, on success,
and \f(CWDW_DLV_BADADDR\fP on error.

Only one of \f(CWparent\fP, \f(CWchild\fP, \f(CWleft_sibling\fP,
and \f(CWright_sibling\fP may be non-NULL.  
If \f(CWparent\fP
(\f(CWchild\fP) is given, the \f(CWDIE\fP is linked into the list 
after (before) the \f(CWDIE\fP pointed to.  
If \f(CWleft_sibling\fP
(\f(CWright_sibling\fP) is given, the \f(CWDIE\fP is linked into 
the list after (before) the \f(CWDIE\fP pointed to.  
Non-NULL links
overwrite the corresponding links the given \f(CWdie\fP may have
had before the call to \f(CWdwarf_die_link() \fP.

.H 2 "Attribute Creation"
The functions in this section add attributes to a \f(CWDIE\fP.
These functions return a \f(CWDwarf_P_Attribute\fP descriptor 
that represents the attribute added to the given \f(CWDIE\fP.  
In most cases the return value is only useful to determine if 
an error occurred.

Some of the attributes have values that are relocatable.  
They
need a symbol with respect to which the linker will perform
relocation.  
This symbol is specified by means of an index into
the Elf symbol table for the object
(of course, the symbol index can be more general than an index).

.H 3 "dwarf_add_AT_location_expr()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_location_expr(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_P_Expr loc_expr,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_location_expr() \fP adds the attribute
specified by \f(CWattr\fP to the \f(CWDIE\fP descriptor given by
\f(CWownerdie\fP.  The attribute should be one that has a location
expression as its value.  The location expression that is the value
is represented by the \f(CWDwarf_P_Expr\fP descriptor \f(CWloc_expr\fP.
It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
given, on success.  On error it returns \f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_name()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_name(
        Dwarf_P_Die ownerdie, 
        char *name,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_name() \fP adds the string specified
by \f(CWname\fP as the value of the \f(CWDW_AT_name\fP attribute
for the given \f(CWDIE\fP, \f(CWownerdie\fP.  It returns the 
\f(CWDwarf_P_attribute\fP descriptor for the \f(CWDW_AT_name\fP 
attribute on success.  On error, it returns \f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_comp_dir()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_comp_dir(
        Dwarf_P_Die ownerdie,
        char *current_working_directory,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_comp_dir() \fP adds the string given by
\f(CWcurrent_working_directory\fP as the value of the \f(CWDW_AT_comp_dir\fP
attribute for the \f(CWDIE\fP described by the given \f(CWownerdie\fP.  
It returns the \f(CWDwarf_P_Attribute\fP for this attribute on success.
On error, it returns \f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_producer()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_producer(
        Dwarf_P_Die ownerdie,
        char *producer_string,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_producer() \fP adds the string given by
\f(CWproducer_string\fP as the value of the \f(CWDW_AT_producer\fP
attribute for the \f(CWDIE\fP given by \f(CWownerdie\fP.  It returns
the \f(CWDwarf_P_Attribute\fP descriptor representing this attribute
on success.  On error, it returns \f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_const_value_signedint()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_const_value_signedint(
        Dwarf_P_Die ownerdie,
        Dwarf_Signed signed_value,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_const_value_signedint() \fP adds the
given \f(CWDwarf_Signed\fP value \f(CWsigned_value\fP as the value
of the \f(CWDW_AT_const_value\fP attribute for the \f(CWDIE\fP
described by the given \f(CWownerdie\fP.  It returns the 
\f(CWDwarf_P_Attribute\fP descriptor for this attribute on success.  
On error, it returns \f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_const_value_unsignedint()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_const_value_unsignedint(
        Dwarf_P_Die ownerdie,
        Dwarf_Unsigned unsigned_value,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_const_value_unsignedint() \fP adds the
given \f(CWDwarf_Unsigned\fP value \f(CWunsigned_value\fP as the value
of the \f(CWDW_AT_const_value\fP attribute for the \f(CWDIE\fP described 
by the given \f(CWownerdie\fP.  It returns the \f(CWDwarf_P_Attribute\fP
descriptor for this attribute on success.  On error, it returns
\f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_const_value_string()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_const_value_string(
        Dwarf_P_Die ownerdie,
        char *string_value,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_const_value_string() \fP adds the 
string value given by \f(CWstring_value\fP as the value of the 
\f(CWDW_AT_const_value\fP attribute for the \f(CWDIE\fP described 
by the given \f(CWownerdie\fP.  It returns the \f(CWDwarf_P_Attribute\fP
descriptor for this attribute on success.  On error, it returns
\f(CWDW_DLV_BADADDR\fP.

.H 3 "dwarf_add_AT_targ_address()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_targ_address(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_Unsigned pc_value,
        Dwarf_Signed sym_index,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_targ_address() \fP adds an attribute that
belongs to the "address" class to the die specified by \f(CWownerdie\fP.  
The attribute is specified by \f(CWattr\fP, and the object that the 
\f(CWDIE\fP belongs to is specified by \f(CWdbg\fP.  The relocatable 
address that is the value of the attribute is specified by \f(CWpc_value\fP. 
The symbol to be used for relocation is specified by the \f(CWsym_index\fP,
which is the index of the symbol in the Elf symbol table.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.


.H 3 "dwarf_add_AT_targ_address_b()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_targ_address_b(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_Unsigned pc_value,
        Dwarf_Unsigned sym_index,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_targ_address_b() \fP 
is identical to \f(CWdwarf_add_AT_targ_address_b() \fP
except that \f(CWsym_index() \fP is guaranteed to 
be large enough that it can contain a pointer to
arbitrary data (so the caller can pass in a real elf
symbol index, an arbitrary number, or a pointer
to arbitrary data).  
The ability to pass in a pointer thru \f(CWsym_index() \fP
is only usable with 
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP.

The \f(CWpc_value\fP
is put into the section stream output and
the \f(CWsym_index\fP is applied to the relocation
information.

.H 3 "dwarf_add_AT_unsigned_const()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_unsigned_const(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_Unsigned value,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_unsigned_const() \fP adds an attribute
with a \f(CWDwarf_Unsigned\fP value belonging to the "constant" class, 
to the \f(CWDIE\fP specified by \f(CWownerdie\fP.  The object that
the \f(CWDIE\fP belongs to is specified by \f(CWdbg\fP.  The attribute
is specified by \f(CWattr\fP, and its value is specified by \f(CWvalue\fP.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_AT_signed_const()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_signed_const(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_Signed value,
        Dwarf_Error *error) \fP
.DE
The function \f(CWdwarf_add_AT_signed_const() \fP adds an attribute
with a \f(CWDwarf_Signed\fP value belonging to the "constant" class,
to the \f(CWDIE\fP specified by \f(CWownerdie\fP.  The object that
the \f(CWDIE\fP belongs to is specified by \f(CWdbg\fP.  The attribute
is specified by \f(CWattr\fP, and its value is specified by \f(CWvalue\fP.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_AT_reference()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_reference(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_P_Die otherdie,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_AT_reference()\fP adds an attribute
with a value that is a reference to another \f(CWDIE\fP in the
same compilation-unit to the \f(CWDIE\fP specified by \f(CWownerdie\fP.  
The object that the \f(CWDIE\fP belongs to is specified by \f(CWdbg\fP.  
The attribute is specified by \f(CWattr\fP, and the other \f(CWDIE\fP
being referred to is specified by \f(CWotherdie\fP.

This cannot generate DW_FORM_ref_addr references to
\f(CWDIE\fPs in other compilation units.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_AT_flag()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_flag(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        Dwarf_Small flag,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_AT_flag()\fP adds an attribute with 
a \f(CWDwarf_Small\fP value belonging to the "flag" class, to the 
\f(CWDIE\fP specified by \f(CWownerdie\fP.  The object that the 
\f(CWDIE\fP belongs to is specified by \f(CWdbg\fP.  The attribute
is specified by \f(CWattr\fP, and its value is specified by \f(CWflag\fP.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_AT_string()"
.DS
\f(CWDwarf_P_Attribute dwarf_add_AT_string(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die ownerdie,
        Dwarf_Half attr,
        char *string,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_AT_string()\fP adds an attribute with a 
value that is a character string to the \f(CWDIE\fP specified by 
\f(CWownerdie\fP.  The object that the \f(CWDIE\fP belongs to is 
specified by \f(CWdbg\fP.  The attribute is specified by \f(CWattr\fP, 
and its value is pointed to by \f(CWstring\fP.

It returns the \f(CWDwarf_P_Attribute\fP descriptor for the attribute
on success, and \f(CWDW_DLV_BADADDR\fP on error.

.H 2 "Expression Creation"
The following functions are used to convert location expressions into
blocks so that attributes with values that are location expressions
can store their values as a \f(CWDW_FORM_blockn\fP value.  This is for 
both .debug_info and .debug_loc expression blocks.

To create an expression, first call \f(CWdwarf_new_expr()\fP to get 
a \f(CWDwarf_P_Expr\fP descriptor that can be used to build up the
block containing the location expression.  Then insert the parts of 
the expression in prefix order (exactly the order they would be 
interpreted in in an expression interpreter).  The bytes of the 
expression are then built-up as specified by the user.

.H 3 "dwarf_new_expr()"
.DS
\f(CWDwarf_Expr dwarf_new_expr(
        Dwarf_P_Debug dbg,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_new_expr()\fP creates a new expression area 
in which a location expression stream can be created.  It returns
a \f(CWDwarf_P_Expr\fP descriptor that can be used to add operators
to build up a location expression.  It returns \f(CWNULL\fP on error.

.H 3 "dwarf_add_expr_gen()"
.DS
\f(CWDwarf_Unsigned dwarf_add_expr_gen(
        Dwarf_P_Expr expr,
        Dwarf_Small opcode, 
        Dwarf_Unsigned val1,
        Dwarf_Unsigned val2,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_expr_gen()\fP takes an operator specified
by \f(CWopcode\fP, along with up to 2 operands specified by \f(CWval1\fP,
and \f(CWval2\fP, converts it into the \f(CWDwarf\fP representation and 
appends the bytes to the byte stream being assembled for the location
expression represented by \f(CWexpr\fP.  The first operand, if present,
to \f(CWopcode\fP is in \f(CWval1\fP, and the second operand, if present,
is in \f(CWval2\fP.  Both the operands may actually be signed or unsigned
depending on \f(CWopcode\fP.  It returns the number of bytes in the byte
stream for \f(CWexpr\fP currently generated, i.e. after the addition of
\f(CWopcode\fP.  It returns \f(CWDW_DLV_NOCOUNT\fP on error.

The function \f(CWdwarf_add_expr_gen()\fP works for all opcodes except
those that have a target address as an operand.  This is because it does
not set up a relocation record that is needed when target addresses are
involved.

.H 3 "dwarf_add_expr_addr()"
.DS
\f(CWDwarf_Unsigned dwarf_add_expr_addr(
        Dwarf_P_Expr expr,
        Dwarf_Unsigned address,
        Dwarf_Signed sym_index,
        Dwarf_Error *error)\fP 
.DE
The function \f(CWdwarf_add_expr_addr()\fP is used to add the
\f(CWDW_OP_addr\fP opcode to the location expression represented
by the given \f(CWDwarf_P_Expr\fP descriptor, \f(CWexpr\fP.  The
value of the relocatable address is given by \f(CWaddress\fP.  
The symbol to be used for relocation is given by \f(CWsym_index\fP,
which is the index of the symbol in the Elf symbol table.  It returns 
the number of bytes in the byte stream for \f(CWexpr\fP currently 
generated, i.e. after the addition of the \f(CWDW_OP_addr\fP operator.  
It returns \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_add_expr_addr_b()"
.DS
\f(CWDwarf_Unsigned dwarf_add_expr_addr_b(
        Dwarf_P_Expr expr,
        Dwarf_Unsigned address,
        Dwarf_Unsigned sym_index,
        Dwarf_Error *error)\fP 
.DE
The function \f(CWdwarf_add_expr_addr_f()\fP is
identical to \f(CWdwarf_add_expr_addr()\fP
except that \f(CWsym_index() \fP is guaranteed to
be large enough that it can contain a pointer to
arbitrary data (so the caller can pass in a real elf
symbol index, an arbitrary number, or a pointer
to arbitrary data).
The ability to pass in a pointer thru \f(CWsym_index() \fP
is only usable with
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP.



.H 3 "dwarf_expr_current_offset()"
.DS
\f(CWDwarf_Unsigned dwarf_expr_current_offset(
        Dwarf_P_Expr expr, 
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_expr_current_offset()\fP returns the number
of bytes currently in the byte stream for the location expression
represented by the given \fCW(Dwarf_P_Expr\fP descriptor, \f(CWexpr\fP.
It returns \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_expr_into_block()"
.DS
\f(CWDwarf_Addr dwarf_expr_into_block(
        Dwarf_P_Expr expr,
        Dwarf_Unsigned *length,
        Dwarf_Error *error)\fP 
.DE
The function \f(CWdwarf_expr_into_block()\fP returns the address
of the start of the byte stream generated for the location expression
represented by the given \f(CWDwarf_P_Expr\fP descriptor, \f(CWexpr\fP.
The length of the byte stream is returned in the location pointed to
by \f(CWlength\fP.  It returns \f(CWDW_DLV_BADADDR\fP on error.

.H 2 "Line Number Operations"
These are operations on the .debug_line section.  
They provide 
information about instructions in the program and the source 
lines the instruction come from.  
Typically, code is generated 
in contiguous blocks, which may then be relocated as contiguous 
blocks.  
To make the provision of relocation information more 
efficient, the information is recorded in such a manner that only
the address of the start of the block needs to be relocated.  
This is done by providing the address of the first instruction 
in a block using the function \f(CWdwarf_lne_set_address()\fP.  
Information about the instructions in the block are then added 
using the function \f(CWdwarf_add_line_entry()\fP, which specifies
offsets from the address of the first instruction.  
The end of 
a contiguous block is indicated by calling the function 
\f(CWdwarf_lne_end_sequence()\fP.
.P
Line number operations do not support
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP.

.H 3 "dwarf_add_line_entry()"
.DS
\f(CWDwarf_Unsigned dwarf_add_line_entry(
        Dwarf_P_Debug dbg,
        Dwarf_Unsigned file_index, 
        Dwarf_Addr code_offset,
        Dwarf_Unsigned lineno, 
        Dwarf_Signed column_number,
        Dwarf_Bool is_source_stmt_begin, 
        Dwarf_Bool is_basic_block_begin,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_line_entry()\fP adds an entry to the
section containing information about source lines.  
It specifies
in \f(CWcode_offset\fP, the offset from the address set using
\f(CWdwarfdwarf_lne_set_address()\fP, of the address of the first
instruction in a contiguous block.  
The source file that gave rise
to the instruction is specified by \f(CWfile_index\fP, the source
line number is specified by \f(CWlineno\fP, and the source column 
number is specified by \f(CWcolumn_number\fP
(column numbers begin at 1)
(if the source column is unknown, specify 0).  
\f(CWfile_index\fP 
is the index of the source file in a list of source files which is 
built up using the function \f(CWdwarf_add_file_decl()\fP. 

\f(CWis_source_stmt_begin\fP is a boolean flag that is true only if 
the instruction at \f(CWcode_address\fP is the first instruction in 
the sequence generated for the source line at \f(CWlineno\fP.  Similarly,
\f(CWis_basic_block_begin\fP is a boolean flag that is true only if
the instruction at \f(CWcode_address\fP is the first instruction of
a basic block.

It returns \f(CW0\fP on success, and \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_lne_set_address()"
.DS
\f(CWDwarf_Unsigned dwarf_lne_set_address(
        Dwarf_P_Debug dbg,
        Dwarf_Addr offs,
        Dwarf_Unsigned symidx,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_lne_set_address()\fP sets the target address
at which a contiguous block of instructions begin.  Information about
the instructions in the block is added to .debug_line using calls to
\f(CWdwarfdwarf_add_line_entry()\fP which specifies the offset of each
instruction in the block relative to the start of the block.  This is 
done so that a single relocation record can be used to obtain the final
target address of every instruction in the block.

The relocatable address of the start of the block of instructions is
specified by \f(CWoffs\fP.  The symbol used to relocate the address 
is given by \f(CWsymidx\fP, which is normally the index of the symbol in the
Elf symbol table. 

It returns \f(CW0\fP on success, and \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_lne_end_sequence()"
.DS
\f(CWDwarf_Unsigned dwarf_lne_end_sequence(
        Dwarf_P_Debug dbg,
	Dwarf_Addr    address;
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_lne_end_sequence()\fP indicates the end of a
contiguous block of instructions.  
\f(CWaddress()\fP 
should be just higher than the end of the last address in the 
sequence of instructions.
block of instructions, a call to \f(CWdwarf_lne_set_address()\fP will 
have to be made to set the address of the start of the target address
of the block, followed by calls to \f(CWdwarf_add_line_entry()\fP for
each of the instructions in the block.

It returns \f(CW0\fP on success, and \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_add_directory_decl()"
.DS
\f(CWDwarf_Unsigned dwarf_add_directory_decl(
        Dwarf_P_Debug dbg,
        char *name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_directory_decl()\fP adds the string 
specified by \f(CWname\fP to the list of include directories in 
the statement program prologue of the .debug_line section.  
The
string should therefore name a directory from which source files
have been used to create the present object.

It returns the index of the string just added, in the list of include 
directories for the object.  
This index is then used to refer to this 
string.  
It returns \f(CWDW_DLV_NOCOUNT\fP on error.

.H 3 "dwarf_add_file_decl()"
.DS
\f(CWDwarf_Unsigned dwarf_add_file_decl(
        Dwarf_P_Debug dbg,
        char *name,
        Dwarf_Unsigned dir_idx,
        Dwarf_Unsigned time_mod,
        Dwarf_Unsigned length,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_file_decl()\fP adds the name of a source
file that contributed to the present object.  
The name of the file is
specified by \f(CWname\fP (which must not be the empty string
or a null pointer, it must point to 
a string with length greater than 0).  
In case the name is not a fully-qualified
pathname, it is prefixed with the name of the directory specified by
\f(CWdir_idx\fP.  
\f(CWdir_idx\fP is the index of the directory to be
prefixed in the list builtup using \f(CWdwarf_add_directory_decl()\fP.

\f(CWtime_mod\fP gives the time at which the file was last modified,
and \f(CWlength\fP gives the length of the file in bytes.

It returns the index of the source file in the list built up so far
using this function, on success.  This index can then be used to 
refer to this source file in calls to \f(CWdwarf_add_line_entry()\fP.
On error, it returns \f(CWDW_DLV_NOCOUNT\fP.

.H 2 "Fast Access (aranges) Operations"
These functions operate on the .debug_aranges section.  

.H 3 "dwarf_add_arange()"
.DS
\f(CWDwarf_Unsigned dwarf_add_arange(
        Dwarf_P_Debug dbg,
        Dwarf_Addr begin_address,
        Dwarf_Unsigned length,
        Dwarf_Signed symbol_index,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_arange()\fP adds another address range 
to be added to the section 
containing address range information, .debug_aranges.  
The relocatable start address of the range is 
specified by \f(CWbegin_address\fP, and the length of the address 
range is specified by \f(CWlength\fP.  
The relocatable symbol to be 
used to relocate the start of the address range is specified by 
\f(CWsymbol_index\fP, which is normally 
the index of the symbol in the Elf
symbol table.

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 3 "dwarf_add_arange_b()"
.DS
\f(CWDwarf_Unsigned dwarf_add_arange_b(
        Dwarf_P_Debug dbg,
        Dwarf_Addr begin_address,
        Dwarf_Unsigned length,
        Dwarf_Unsigned symbol_index,
	Dwarf_Unsigned end_symbol_index,
	Dwarf_Addr     offset_from_end_symbol,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_arange_b()\fP adds another address range
to be added to the section containing 
address range information, .debug_aranges.  

If
\f(CWend_symbol_index is not zero\fP
we are using two symbols to create a length
(must be \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP to be useful)
.sp
.in +2
\f(CWbegin_address\fP
is the offset from the symbol specified by
\f(CWsymbol_index\fP .
\f(CWoffset_from_end_symbol\fP
is the offset from the symbol specified by
\f(CWend_symbol_index\fP.
\f(CWlength\fP is ignored.
This begin-end pair will be show up in the
relocation array returned by
\f(CWdwarf_get_relocation_info() \fP
as a
\f(CWdwarf_drt_first_of_length_pair\fP
and
\f(CWdwarf_drt_second_of_length_pair\fP
pair of relocation records.
The consuming application will turn that pair into
something conceptually identical to
.sp
.nf
.in +4
 .word end_symbol + offset_from_end - \\
   ( start_symbol + begin_address)
.in -4
.fi
.sp
The reason offsets are allowed on the begin and end symbols
is to allow the caller to re-use existing labels
when the labels are available
and the corresponding offset is known  
(economizing on the number of labels in use).
The  'offset_from_end - begin_address'
will actually be in the binary stream, not the relocation
record, so the app processing the relocation array
must read that stream value into (for example)
net_offset and actually emit something like
.sp
.nf
.in +4
 .word end_symbol - start_symbol + net_offset
.in -4
.fi
.sp
.in -2

If
\f(CWend_symbol_index\fP is zero
we must be given a length
(either
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
):
.sp
.in +2
The relocatable start address of the range is
specified by \f(CWbegin_address\fP, and the length of the address
range is specified by \f(CWlength\fP.  
The relocatable symbol to be
used to relocate the start of the address range is specified by
\f(CWsymbol_index\fP, which is normally
the index of the symbol in the Elf
symbol table.
The 
\f(CWoffset_from_end_symbol\fP
is ignored.
.in -2


It returns a non-zero value on success, and \f(CW0\fP on error.


.H 2 "Fast Access (pubnames) Operations"
These functions operate on the .debug_pubnames section.
.sp
.H 3 "dwarf_add_pubname()"
.DS
\f(CWDwarf_Unsigned dwarf_add_pubname(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die die,
        char *pubname_name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_pubname()\fP adds the pubname specified
by \f(CWpubname_name\fP to the section containing pubnames, i.e.
  .debug_pubnames.  The \f(CWDIE\fP that represents the function
being named is specified by \f(CWdie\fP.  

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 2 "Fast Access (weak names) Operations"
These functions operate on the .debug_weaknames section.

.H 3 "dwarf_add_weakname()"
.DS
\f(CWDwarf_Unsigned dwarf_add_weakname(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die die,
        char *weak_name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_weakname()\fP adds the weak name specified
by \f(CWweak_name\fP to the section containing weak names, i.e.  
 .debug_weaknames.  The \f(CWDIE\fP that represents the function
being named is specified by \f(CWdie\fP.  

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 2 "Static Function Names Operations"
The .debug_funcnames section contains the names of static function 
names defined in the object, and also the offsets of the \f(CWDIE\fPs
that represent the definitions of the functions in the .debug_info 
section.

.H 3 "dwarf_add_funcname()"
.DS
\f(CWDwarf_Unsigned dwarf_add_funcname(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die die,
        char *func_name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_funcname()\fP adds the name of a static
function specified by \f(CWfunc_name\fP to the section containing the
names of static functions defined in the object represented by \f(CWdbg\fP.
The \f(CWDIE\fP that represents the definition of the function is
specified by \f(CWdie\fP.

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 2 "File-scope User-defined Type Names Operations"
The .debug_typenames section contains the names of file-scope
user-defined types in the given object, and also the offsets 
of the \f(CWDIE\fPs that represent the definitions of the types 
in the .debug_info section.

.H 3 "dwarf_add_typename()"
.DS
\f(CWDwarf_Unsigned dwarf_add_typename(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die die,
        char *type_name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_typename()\fP adds the name of a file-scope
user-defined type specified by \f(CWtype_name\fP to the section that 
contains the names of file-scope user-defined type.  The object that 
this section belongs to is specified by \f(CWdbg\fP.  The \f(CWDIE\fP 
that represents the definition of the type is specified by \f(CWdie\fP.

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 2 "File-scope Static Variable Names Operations"
The .debug_varnames section contains the names of file-scope static
variables in the given object, and also the offsets of the \f(CWDIE\fPs
that represent the definition of the variables in the .debug_info
section.

.H 3 "dwarf_add_varname()"
.DS
\f(CWDwarf_Unsigned dwarf_add_varname(
        Dwarf_P_Debug dbg,
        Dwarf_P_Die die,
        char *var_name,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_varname()\fP adds the name of a file-scope
static variable specified by \f(CWvar_name\fP to the section that 
contains the names of file-scope static variables defined by the 
object represented by \f(CWdbg\fP.  The \f(CWDIE\fP that represents
the definition of the static variable is specified by \f(CWdie\fP.

It returns a non-zero value on success, and \f(CW0\fP on error.

.H 2 "Macro Information Creation"
All strings passed in by the caller are copied by these
functions, so the space in which the caller provides the strings
may be ephemeral (on the stack, or immediately reused or whatever)
without this causing any difficulty.

.H 3 "dwarf_def_macro()"
.DS
\f(CWint dwarf_def_macro(Dwarf_P_Debug dbg,
	Dwarf_Unsigned lineno,
	char *name
	char *value,
        Dwarf_Error *error);\fP
.DE
Adds a macro definition.
The \f(CWname\fP argument should include the parentheses
and parameter names if this is a function-like macro.
Neither string should contain extraneous whitespace.
\f(CWdwarf_def_macro()\fP adds the mandated space after the
name and before the value  in the
output DWARF section(but does not change the
strings pointed to by the arguments).
If this is a definition before any files are read,
\f(CWlineno\fP should be 0.
Returns \f(CWDW_DLV_ERROR\fP
and sets \f(CWerror\fP
if there is an error.
Returns \f(CWDW_DLV_OK\fP if the call was successful.


.H 3 "dwarf_undef_macro()"
.DS
\f(CWint dwarf_undef_macro(Dwarf_P_Debug dbg,
	Dwarf_Unsigned lineno,
	char *name,
        Dwarf_Error *error);\fP
.DE
Adds a macro un-definition note.
If this is a definition before any files are read,
\f(CWlineno\fP should be 0.
Returns \f(CWDW_DLV_ERROR\fP
and sets \f(CWerror\fP
if there is an error.
Returns \f(CWDW_DLV_OK\fP if the call was successful.


.H 3 "dwarf_start_macro_file()"
.DS
\f(CWint dwarf_start_macro_file(Dwarf_P_Debug dbg,
	Dwarf_Unsigned lineno,
        Dwarf_Unsigned fileindex,
        Dwarf_Error *error);\fP
.DE
\f(CWfileindex\fP is an index in the .debug_line header: 
the index of
the file name.
See the function \f(CWdwarf_add_file_decl()\fP.
The \f(CWlineno\fP should be 0 if this file is
the file of the compilation unit source itself
(which, of course, is not a #include in any
file).
Returns \f(CWDW_DLV_ERROR\fP
and sets \f(CWerror\fP
if there is an error.
Returns \f(CWDW_DLV_OK\fP if the call was successful.


.H 3 "dwarf_end_macro_file()"
.DS
\f(CWint dwarf_end_macro_file(Dwarf_P_Debug dbg,
        Dwarf_Error *error);\fP
.DE
Returns \f(CWDW_DLV_ERROR\fP
and sets \f(CWerror\fP
if there is an error.
Returns \f(CWDW_DLV_OK\fP if the call was successful.

.H 3 "dwarf_vendor_ext()"
.DS
\f(CWint dwarf_vendor_ext(Dwarf_P_Debug dbg,
    Dwarf_Unsigned constant,
    char *         string,
    Dwarf_Error*   error); \fP
.DE
The meaning of the \f(CWconstant\fP and the\f(CWstring\fP
in the macro info section
are undefined by DWARF itself, but the string must be
an ordinary null terminated string.
This call is not an extension to DWARF. 
It simply enables storing
macro information as specified in the DWARF document.
Returns \f(CWDW_DLV_ERROR\fP
and sets \f(CWerror\fP
if there is an error.
Returns \f(CWDW_DLV_OK\fP if the call was successful.


.H 2 "Low Level (.debug_frame) operations"
These functions operate on the .debug_frame section.  Refer to 
\f(CWlibdwarf.h\fP for the register names and register assignment 
mapping.  Both of these are necessarily machine dependent.

.H 3 "dwarf_new_fde()"
.DS
\f(CWDwarf_P_Fde dwarf_new_fde(
        Dwarf_P_Debug dbg, 
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_new_fde()\fP returns a new \f(CWDwarf_P_Fde\fP
descriptor that should be used to build a complete \f(CWFDE\fP.  
Subsequent calls to routines that build up the \f(CWFDE\fP should use
the same \f(CWDwarf_P_Fde\fP descriptor.

It returns a valid \f(CWDwarf_P_Fde\fP descriptor on success, and
\f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_frame_cie()"
.DS
\f(CWDwarf_Unsigned dwarf_add_frame_cie(
        Dwarf_P_Debug dbg,
        char *augmenter, 
        Dwarf_Small code_align,
        Dwarf_Small data_align, 
        Dwarf_Small ret_addr_reg, 
        Dwarf_Ptr init_bytes, 
        Dwarf_Unsigned init_bytes_len,
        Dwarf_Error *error);\fP
.DE
The function 
\f(CWdwarf_add_frame_cie()\fP 
creates a \f(CWCIE\fP,
and returns an index to it, that should be used to refer to this
\f(CWCIE\fP.  
\f(CWCIE\fPs are used by \f(CWFDE\fPs to setup
initial values for frames.  
The augmentation string for the \f(CWCIE\fP
is specified by \f(CWaugmenter\fP.  
The code alignment factor,
data alignment factor, and the return address register for the
\f(CWCIE\fP are specified by \f(CWcode_align\fP, \f(CWdata_align\fP,
and \f(CWret_addr_reg\fP respectively.  
\f(CWinit_bytes\fP points
to the bytes that represent the instructions for the \f(CWCIE\fP
being created, and \f(CWinit_bytes_len\fP specifies the number
of bytes of instructions.

There is no convenient way to generate the  \f(CWinit_bytes\fP
stream. 
One just
has to calculate it by hand or separately
generate something with the 
correct sequence and use dwarfdump -v and elfdump -h  and some
kind of hex dumper to see the bytes.
This is a serious inconvenience! 

It returns an index to the \f(CWCIE\fP just created on success.
On error it returns \f(CWDW_DLV_NOCOUNT\fP.

.H 3 "dwarf_add_frame_fde()"
.DS
\f(CWDwarf_Unsigned dwarf_add_frame_fde(
        Dwarf_P_Debug dbg,
        Dwarf_P_Fde fde,
        Dwarf_P_Die die,
        Dwarf_Unsigned cie,
        Dwarf_Addr virt_addr,
        Dwarf_Unsigned  code_len,
        Dwarf_Unsigned sym_idx,
        Dwarf_Error* error)\fP
.DE
The function \f(CWdwarf_add_frame_fde()\fP adds the \f(CWFDE\fP
specified by \f(CWfde\fP to the list of \f(CWFDE\fPs for the
object represented by the given \f(CWdbg\fP.  
\f(CWdie\fP specifies
the \f(CWDIE\fP that represents the function whose frame information
is specified by the given \f(CWfde\fP.  
\f(CWcie\fP specifies the
index of the \f(CWCIE\fP that should be used to setup the initial
conditions for the given frame.  


It returns an index to the given \f(CWfde\fP.


.H 3 "dwarf_add_frame_fde_b()"
.DS
\f(CWDwarf_Unsigned dwarf_add_frame_fde_b(
        Dwarf_P_Debug dbg,
        Dwarf_P_Fde fde,
        Dwarf_P_Die die,
        Dwarf_Unsigned cie,
        Dwarf_Addr virt_addr,
        Dwarf_Unsigned  code_len,
        Dwarf_Unsigned sym_idx,
	Dwarf_Unsigned sym_idx_of_end,
	Dwarf_Addr     offset_from_end_sym,
        Dwarf_Error* error)\fP
.DE
This function is like 
\f(CWdwarf_add_frame_fde()\fP 
except that 
\f(CWdwarf_add_frame_fde_b()\fP 
has new arguments to allow use
with
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP.

The function \f(CWdwarf_add_frame_fde_b()\fP 
adds the 
\f(CWFDE\fP
specified by \f(CWfde\fP to the list of \f(CWFDE\fPs for the
object represented by the given \f(CWdbg\fP.  
\f(CWdie\fP specifies
the \f(CWDIE\fP that represents the function whose frame information
is specified by the given \f(CWfde\fP.  
\f(CWcie\fP specifies the
index of the \f(CWCIE\fP that should be used to setup the initial
conditions for the given frame.  
\f(CWvirt_addr\fP represents the
relocatable address at which the code for the given function begins,
and \f(CWsym_idx\fP gives the index of the relocatable symbol to
be used to relocate this address (\f(CWvirt_addr\fP that is).
\f(CWcode_len\fP specifies the size in bytes of the machine instructions
for the given function.

If \f(CWsym_idx_of_end\fP is zero 
(may  be 
\f(CWDW_DLC_STREAM_RELOCATIONS\fP 
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP 
):
.sp
.in +2
\f(CWvirt_addr\fP represents the
relocatable address at which the code for the given function begins,
and \f(CWsym_idx\fP gives the index of the relocatable symbol to
be used to relocate this address (\f(CWvirt_addr\fP that is).
\f(CWcode_len\fP 
specifies the size in bytes of the machine instructions
for the given function.
\f(CWsym_idx_of_end\fP
and
\f(CWoffset_from_end_sym\fP
are unused.
.in -2
.sp


If \f(CWsym_idx_of_end\fP is non-zero 
(must be \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP to be useful):
.sp
.in +2
\f(CWvirt_addr\fP
is the offset from the symbol specified by
\f(CWsym_idx\fP .
\f(CWoffset_from_end_sym\fP
is the offset from the symbol specified by
\f(CWsym_idx_of_end\fP.
\f(CWcode_len\fP is ignored.
This begin-end pair will be show up in the
relocation array returned by
\f(CWdwarf_get_relocation_info() \fP
as a
\f(CWdwarf_drt_first_of_length_pair\fP
and
\f(CWdwarf_drt_second_of_length_pair\fP
pair of relocation records.
The consuming application will turn that pair into
something conceptually identical to
.sp
.nf
.in +4
 .word end_symbol + begin - \\
   ( start_symbol + offset_from_end)
.in -4
.fi
.sp
The reason offsets are allowed on the begin and end symbols
is to allow the caller to re-use existing labels
when the labels are available
and the corresponding offset is known
(economizing on the number of labels in use).
The  'offset_from_end - begin_address'
will actually be in the binary stream, not the relocation
record, so the app processing the relocation array
must read that stream value into (for example)
net_offset and actually emit something like
.sp
.nf
.in +4
 .word end_symbol - start_symbol + net_offset
.in -4
.fi
.sp
.in -2

It returns an index to the given \f(CWfde\fP.

On error, it returns \f(CWDW_DLV_NOCOUNT\fP.

.H 3 "dwarf_add_frame_info_b()"
.DS
\f(CWDwarf_Unsigned dwarf_add_frame_info_b(
        Dwarf_P_Debug   dbg,
        Dwarf_P_Fde     fde,
        Dwarf_P_Die     die,
        Dwarf_Unsigned  cie,
        Dwarf_Addr      virt_addr,
        Dwarf_Unsigned  code_len,
        Dwarf_Unsigned  sym_idx,
	Dwarf_Unsigned  end_symbol_index,
        Dwarf_Addr      offset_from_end_symbol,
	Dwarf_Signed    offset_into_exception_tables,
	Dwarf_Unsigned  exception_table_symbol,
        Dwarf_Error*    error)\fP
.DE
The function \f(CWdwarf_add_frame_fde()\fP adds the \f(CWFDE\fP
specified by \f(CWfde\fP to the list of \f(CWFDE\fPs for the
object represented by the given \f(CWdbg\fP.  
\f(CWdie\fP specifies
the \f(CWDIE\fP that represents the function whose frame information
is specified by the given \f(CWfde\fP.  
\f(CWcie\fP specifies the
index of the \f(CWCIE\fP that should be used to setup the initial
conditions for the given frame.  
\f(CWoffset_into_exception_tables\fP specifies the
offset into \f(CW.MIPS.eh_region\fP elf section where the exception tables 
for this function begins. 
\f(CWexception_table_symbol\fP  gives the index of 
the relocatable symbol to be used to relocate this offset.


If
\f(CWend_symbol_index is not zero\fP
we are using two symbols to create a length
(must be \f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP to be useful)
.sp
.in +2
\f(CWvirt_addr\fP
is the offset from the symbol specified by
\f(CWsym_idx\fP .
\f(CWoffset_from_end_symbol\fP
is the offset from the symbol specified by
\f(CWend_symbol_index\fP.
\f(CWcode_len\fP is ignored.
This begin-end pair will be show up in the
relocation array returned by
\f(CWdwarf_get_relocation_info() \fP
as a
\f(CWdwarf_drt_first_of_length_pair\fP
and
\f(CWdwarf_drt_second_of_length_pair\fP
pair of relocation records.
The consuming application will turn that pair into
something conceptually identical to
.sp
.nf
.in +4
 .word end_symbol + offset_from_end_symbol - \\
   ( start_symbol + virt_addr)
.in -4
.fi
.sp
The reason offsets are allowed on the begin and end symbols
is to allow the caller to re-use existing labels
when the labels are available
and the corresponding offset is known  
(economizing on the number of labels in use).
The  'offset_from_end - begin_address'
will actually be in the binary stream, not the relocation
record, so the app processing the relocation array
must read that stream value into (for example)
net_offset and actually emit something like
.sp
.nf
.in +4
 .word end_symbol - start_symbol + net_offset
.in -4
.fi
.sp
.in -2

If
\f(CWend_symbol_index\fP is zero
we must be given a code_len value
(either
\f(CWDW_DLC_STREAM_RELOCATIONS\fP
or
\f(CWDW_DLC_SYMBOLIC_RELOCATIONS\fP
):
.sp
.in +2
The relocatable start address of the range is
specified by \f(CWvirt_addr\fP, and the length of the address
range is specified by \f(CWcode_len\fP.  
The relocatable symbol to be
used to relocate the start of the address range is specified by
\f(CWsymbol_index\fP, which is normally
the index of the symbol in the Elf
symbol table.
The 
\f(CWoffset_from_end_symbol\fP
is ignored.
.in -2


It returns an index to the given \f(CWfde\fP.

On error, it returns \f(CWDW_DLV_NOCOUNT\fP.


.H 3 "dwarf_add_frame_info()"

.DS
\f(CWDwarf_Unsigned dwarf_add_frame_info(
        Dwarf_P_Debug dbg,
        Dwarf_P_Fde fde,
        Dwarf_P_Die die,
        Dwarf_Unsigned cie,
        Dwarf_Addr virt_addr,
        Dwarf_Unsigned  code_len,
        Dwarf_Unsigned sym_idx,
	Dwarf_Signed offset_into_exception_tables,
	Dwarf_Unsigned exception_table_symbol,
        Dwarf_Error* error)\fP
.DE
The function \f(CWdwarf_add_frame_fde()\fP adds the \f(CWFDE\fP
specified by \f(CWfde\fP to the list of \f(CWFDE\fPs for the
object represented by the given \f(CWdbg\fP.  \f(CWdie\fP specifies
the \f(CWDIE\fP that represents the function whose frame information
is specified by the given \f(CWfde\fP.  \f(CWcie\fP specifies the
index of the \f(CWCIE\fP that should be used to setup the initial
conditions for the given frame.  \f(CWvirt_addr\fP represents the
relocatable address at which the code for the given function begins,
and \f(CWsym_idx\fP gives the index of the relocatable symbol to
be used to relocate this address (\f(CWvirt_addr\fP that is).
\f(CWcode_len\fP specifies the size in bytes of the machine instructions
for the given function. \f(CWoffset_into_exception_tables\fP specifies the
offset into \f(CW.MIPS.eh_region\fP elf section where the exception tables 
for this function begins. \f(CWexception_table_symbol\fP  gives the index of 
the relocatable symbol to be used to relocate this offset.

It returns an index to the given \f(CWfde\fP.

.H 3 "dwarf_fde_cfa_offset()"
.DS
\f(CWDwarf_P_Fde dwarf_fde_cfa_offset(
        Dwarf_P_Fde fde,
        Dwarf_Unsigned reg,
        Dwarf_Signed offset,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_fde_cfa_offset()\fP appends a \f(CWDW_CFA_offset\fP
operation to the \f(CWFDE\fP, specified by \f(CWfde\fP,  being constructed.  
The first operand of the \f(CWDW_CFA_offset\fP operation is specified by 
\f(CWreg\P.  The register specified should not exceed 6 bits.  The second 
operand of the \f(CWDW_CFA_offset\fP operation is specified by \f(CWoffset\fP.

It returns the given \f(CWfde\fP on success.

It returns \f(CWDW_DLV_BADADDR\fP on error.

.H 3 "dwarf_add_fde_inst()"
.DS
\f(CWDwarf_P_Fde dwarf_add_fde_inst(
        Dwarf_P_Fde fde,
        Dwarf_Small op,
        Dwarf_Unsigned val1,
        Dwarf_Unsigned val2,
        Dwarf_Error *error)\fP
.DE
The function \f(CWdwarf_add_fde_inst()\fP adds the operation specified
by \f(CWop\fP to the \f(CWFDE\fP specified by \f(CWfde\fP.  Upto two
operands can be specified in \f(CWval1\fP, and \f(CWval2\fP.  Based on
the operand specified \f(CWLibdwarf\fP decides how many operands are
meaningful for the operand.  It also converts the operands to the 
appropriate datatypes (they are passed to \f(CWdwarf_add_fde_inst\fP
as \f(CWDwarf_Unsigned\fP).

It returns the given \f(CWfde\fP on success, and \f(CWDW_DLV_BADADDR\fP
on error.

.S
.TC 1 1 4
.CS
