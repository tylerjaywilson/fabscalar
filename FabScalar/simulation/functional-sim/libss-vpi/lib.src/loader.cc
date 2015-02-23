#include <stdio.h>
#include <stdlib.h>
#include "misc.h"
extern "C" {
#include "bfd.h"
}
#include "ss.h"
#include "regs.h"
#include "memory.h"
#include "sim.h"
#include "loader.h"

#include "Thread.h"
#include "ecoff.h"
//#define BFD_LOADER
int ld_target_big_endian;

/* copy args and environ into the simulator's MAIN MEMORY, the format in
   memory is:

   --> higher memory

   SS_STACK_BASE -> [unused]
                    [envp strings]
		    [argv strings]
		    [envp array,NULL]
                    [argv array,NULL]
   initial sp ->    [argc]

   --> lower memory
*/
void Thread::ld_load_prog(mem_access_fn mem_fn,
			  int argc, char **argv, char **envp,
			  int zero_bss_segs)
{
  
  SS_ADDR_TYPE sp, data_break = 0, null_ptr = 0, argv_addr, envp_addr;
  SS_WORD_TYPE temp;
  int i;
#ifdef BFD_LOADER

  bfd *abfd;
  asection *sect;
  /* set up a local stack pointer, this is where the argv and envp
     data is written into program memory */
  ld_stack_base = SS_STACK_BASE;
  sp = ROUND_DOWN(SS_STACK_BASE - SS_MAX_ENVIRON, sizeof(SS_DOUBLE_TYPE));
  ld_stack_size = ld_stack_base - sp;

  /* initial stack pointer value */
  ld_environ_base = sp;

  /* load the program into memory */
  if (!(abfd = bfd_openr(argv[0], "ss-coff-big")))
    if (!(abfd = bfd_openr(argv[0], "ss-coff-little")))
      fatal("cannot open executable `%s'", argv[0]);

  /* this call is mainly for its side effect of reading in the sections.
     we follow the traditional behavior of `strings' in that we don't
     complain if we don't recognize a file to be an object file.  */
  if (!bfd_check_format(abfd, bfd_object))
    {
      bfd_close(abfd);
      fatal("cannot open executable `%s'", argv[0]);
    }

  /* record endian of target */
  ld_target_big_endian = abfd->xvec->byteorder_big_p;

  debug("processing %d sections in `%s'...",
	bfd_count_sections(abfd), argv[0]);

  /* 10/5/96 ERIC_CHANGE */
  debug("\n[Eric] bfd error: %s\n", bfd_errmsg(bfd_get_error()) );

  for (sect=abfd->sections; sect; sect=sect->next)
    {
      char *p;

      debug("processing section `%s', %d bytes @ 0x%08x...",
	    bfd_section_name(abfd, sect), bfd_section_size(abfd, sect),
	    bfd_section_vma(abfd, sect));

      /* read the section data */
      if ((bfd_get_section_flags(abfd, sect) & SEC_ALLOC)
	  && (bfd_get_section_flags(abfd, sect) & SEC_LOAD)
	  && bfd_section_vma(abfd, sect)
	  && bfd_section_size(abfd, sect))
	{
	  if (!(p = (char*)calloc(bfd_section_size(abfd, sect), sizeof(char))))
	    fatal("cannot allocate %d bytes for section `%s'",
		  bfd_section_size(abfd, sect), bfd_section_name(abfd, sect));

	  if (!bfd_get_section_contents(abfd, sect, p, (file_ptr)0,
					bfd_section_size(abfd, sect)))
	    fatal("could not read entire `%s' section from executable",
		  bfd_section_name(abfd, sect));

	  /* copy it into simulator memory */
	  mem_bcopy(mem_fn, Write, bfd_section_vma(abfd, sect),
		    p, bfd_section_size(abfd, sect));
	  free(p);
	}
      else if (zero_bss_segs
	       && (bfd_get_section_flags(abfd, sect) & SEC_LOAD)
	       && bfd_section_vma(abfd, sect)
	       && bfd_section_size(abfd, sect))
	{
	  /* zero out the section region */
	  mem_bzero(mem_fn,
		    bfd_section_vma(abfd, sect), bfd_section_size(abfd, sect));
	}
      /* else: do nothing, is or will be init'ed to zero at page fault time */

      /* expected text section */
      if (!strcmp(bfd_section_name(abfd, sect), ".text"))
	{
	  /* .text section processing */
	  ld_text_size =
	    ((bfd_section_vma(abfd, sect) + bfd_section_size(abfd, sect))
	     - SS_TEXT_BASE) + /* for speculative fetches/decodes */128;
	}
      /* expected data sections */
      else if (!strcmp(bfd_section_name(abfd, sect), ".rdata")
	       || !strcmp(bfd_section_name(abfd, sect), ".data")
	       || !strcmp(bfd_section_name(abfd, sect), ".sdata")
	       || !strcmp(bfd_section_name(abfd, sect), ".bss")
	       || !strcmp(bfd_section_name(abfd, sect), ".sbss"))
	{
	  /* data section processing */
	  if (bfd_section_vma(abfd, sect) + bfd_section_size(abfd, sect) >
	      data_break)
	    data_break = (bfd_section_vma(abfd, sect) +
			  bfd_section_size(abfd, sect));
	}
      else
	fatal("encountered unknown section `%s', %d bytes @ 0x%08x",
	      bfd_section_name(abfd, sect), bfd_section_size(abfd, sect),
	      bfd_section_vma(abfd, sect));
    }

  /* compute data segment size from data break point */
  ld_text_base = SS_TEXT_BASE;
  ld_data_base = SS_DATA_BASE;
  ld_prog_entry = bfd_get_start_address(abfd);
  ld_data_size = data_break - ld_data_base;

  if (!bfd_close(abfd))
    fatal("could not close executable `%s'", argv[0]);
//PR update from SS2.0 
#else /* !BFD_LOADER, i.e., standalone loader */

  FILE *fobj;
  long floc;
  struct ecoff_filehdr fhdr;
  struct ecoff_aouthdr ahdr;
  struct ecoff_scnhdr shdr;

  /* set up a local stack pointer, this is where the argv and envp
     data is written into program memory */
  ld_stack_base = SS_STACK_BASE;
  sp = ROUND_DOWN(SS_STACK_BASE - SS_MAX_ENVIRON, sizeof(SS_DOUBLE_TYPE));
  ld_stack_size = ld_stack_base - sp;

  /* initial stack pointer value */
  ld_environ_base = sp;

  /* record profile file name */
  ld_prog_fname = argv[0];

  /* load the program into memory, try both endians */
#ifdef __CYGWIN32__
  fobj = fopen(argv[0], "rb");
#else
  fobj = fopen(argv[0], "r");
#endif
  if (!fobj)
    fatal("cannot open executable `%s'", argv[0]);

  if (fread(&fhdr, sizeof(struct ecoff_filehdr), 1, fobj) < 1)
    fatal("cannot read header from executable `%s'", argv[0]);

  /* record endian of target */
  if (fhdr.f_magic == ECOFF_EB_MAGIC)
    ld_target_big_endian = TRUE;
  else if (fhdr.f_magic == ECOFF_EL_MAGIC)
    ld_target_big_endian = FALSE;
  else
    fatal("bad magic number in executable `%s'", argv[0]);

  if (fread(&ahdr, sizeof(struct ecoff_aouthdr), 1, fobj) < 1)
    fatal("cannot read AOUT header from executable `%s'", argv[0]);

  data_break = SS_DATA_BASE + ahdr.dsize + ahdr.bsize;

#if 0
  Data_start = ahdr.data_start;
  Data_size = ahdr.dsize;
  Bss_size = ahdr.bsize;
  Bss_start = ahdr.bss_start;
  Gp_value = ahdr.gp_value;
  Text_entry = ahdr.entry;
#endif

  /* seek to the beginning of the first section header, the file header comes
     first, followed by the optional header (this is the aouthdr), the size
     of the aouthdr is given in Fdhr.f_opthdr */
  fseek(fobj, sizeof(struct ecoff_filehdr) + fhdr.f_opthdr, 0);

  debug("processing %d sections in ...", fhdr.f_nscns);

  /* loop through the section headers */
  floc = ftell(fobj);
  for (i = 0; i < fhdr.f_nscns; i++)
    {
      char *p;

      if (fseek(fobj, floc, 0) == -1)
	fatal("could not reset location in executable");
      if (fread(&shdr, sizeof(struct ecoff_scnhdr), 1, fobj) < 1)
	fatal("could not read section %d from executable", i);
      floc = ftell(fobj);

      switch (shdr.s_flags)
	{
	case ECOFF_STYP_TEXT:
	  ld_text_size = ((shdr.s_vaddr + shdr.s_size) - SS_TEXT_BASE) + 128;

	  p = (char*)calloc(shdr.s_size, sizeof(char));
	 // p = new char[shdr.s_size];
	  if (!p)
	    fatal("out of virtual memory");

	  if (fseek(fobj, shdr.s_scnptr, 0) == -1)
	    fatal("could not read `.text' from executable", i);
	  if (fread(p, shdr.s_size, 1, fobj) < 1)
	    fatal("could not read text section from executable");

	  /* copy program section it into simulator target memory */
	  mem_bcopy(mem_fn, Write, shdr.s_vaddr, p, shdr.s_size);

	  /* release the section buffer */
	  free(p);

#if 0
	  Text_seek = shdr.s_scnptr;
	  Text_start = shdr.s_vaddr;
	  Text_size = shdr.s_size / 4;
	  /* there is a null routine after the supposed end of text */
	  Text_size += 10;
	  Text_end = Text_start + Text_size * 4;
	  /* create_text_reloc(shdr.s_relptr, shdr.s_nreloc); */
#endif
	  break;

	case ECOFF_STYP_RDATA:
	  /* The .rdata section is sometimes placed before the text
	   * section instead of being contiguous with the .data section.
	   */
#if 0
	  Rdata_start = shdr.s_vaddr;
	  Rdata_size = shdr.s_size;
	  Rdata_seek = shdr.s_scnptr;
#endif
	  /* fall through */
	case ECOFF_STYP_DATA:
#if 0
	  Data_seek = shdr.s_scnptr;
#endif
	  /* fall through */
	case ECOFF_STYP_SDATA:
#if 0
	  Sdata_seek = shdr.s_scnptr;
#endif

	  p = (char*)calloc(shdr.s_size, sizeof(char));
	  //p = new char[shdr.s_size];
	  if (!p)
	    fatal("out of virtual memory");

	  if (fseek(fobj, shdr.s_scnptr, 0) == -1)
	    fatal("could not read `.text' from executable", i);
	  if (fread(p, shdr.s_size, 1, fobj) < 1)
	    fatal("could not read text section from executable");

	  /* copy program section it into simulator target memory */
	  mem_bcopy(mem_fn, Write, shdr.s_vaddr, p, shdr.s_size);

	  /* release the section buffer */
	  free(p);

	  break;

	case ECOFF_STYP_BSS:
	  break;

	case ECOFF_STYP_SBSS:
	  break;
        }
    }

  /* compute data segment size from data break point */
  ld_text_base = SS_TEXT_BASE;
  ld_data_base = SS_DATA_BASE;
  ld_prog_entry = ahdr.entry;
  ld_data_size = data_break - ld_data_base;

  /* done with the executable, close it */
  if (fclose(fobj))
    fatal("could not close executable `%s'", argv[0]);

#endif /* BFD_LOADER */
/* perform sanity checks on segment ranges */
  if (!ld_text_base || !ld_text_size)
    fatal("executable is missing a `.text' section");
  if (!ld_data_base || !ld_data_size)
    fatal("executable is missing a `.data' section");
  if (!ld_prog_entry)
    fatal("program entry point not specified");

  /* determine byte/words swapping required to execute on this host */
  sim_swap_bytes = (endian_host_byte_order() != endian_target_byte_order());
  if (sim_swap_bytes)
    fprintf(stderr, "sim: *WARNING*: swapping bytes to match host...\n");
  sim_swap_words = (endian_host_word_order() != endian_target_word_order());
  if (sim_swap_words)
    fprintf(stderr, "sim: *WARNING*: swapping words to match host...\n");

  /* write [argc] */
  temp = SWAP_WORD(argc);
  (this->*mem_fn)(Write, sp, &temp, sizeof(SS_WORD_TYPE));
  sp += sizeof(SS_WORD_TYPE);

  /* skip past argv array and NULL */
  argv_addr = sp;
  sp = sp + (argc + 1) * sizeof(SS_PTR_TYPE);

  /* save space for envp array and NULL */
  envp_addr = sp;
  for (i=0; envp[i]; i++)
    sp += sizeof(SS_PTR_TYPE);
  sp += sizeof(SS_PTR_TYPE);

  /* fill in the argv pointer array and data */
  for (i=0; i<argc; i++)
    {
      /* write the argv pointer array entry */
      temp = SWAP_WORD(sp);
      (this->*mem_fn)(Write, argv_addr + i*sizeof(SS_PTR_TYPE),
	     &temp, sizeof(SS_PTR_TYPE));
      /* and the data */
      sp += mem_strcpy(mem_fn, Write, sp, argv[i]);
    }
  /* terminate argv array */
  (this->*mem_fn)(Write, argv_addr + i*sizeof(SS_PTR_TYPE),
	 &null_ptr, sizeof(SS_PTR_TYPE));

  /* write envp pointer array and data */
  for (i = 0; envp[i]; i++)
    {
      /* write the envp pointer array entry */
      temp = SWAP_WORD(sp);
      (this->*mem_fn)(Write, envp_addr + i*sizeof(SS_PTR_TYPE),
	     &temp, sizeof(SS_PTR_TYPE));
      /* and the data */
      sp += mem_strcpy(mem_fn, Write, sp, envp[i]);
    }
  /* terminate the envp array */
  (this->*mem_fn)(Write, envp_addr + i*sizeof(SS_PTR_TYPE),
	       &null_ptr, sizeof(SS_PTR_TYPE));

  if (sp > ld_stack_base)
    fatal("environment overflow, increase SS_MAX_ENVIRON");

  debug("ld_text_base: 0x%08x  ld_text_size: 0x%08x",
	ld_text_base, ld_text_size);
  debug("ld_data_base: 0x%08x  ld_data_size: 0x%08x",
	ld_data_base, ld_data_size);
  debug("ld_stack_base: 0x%08x  ld_stack_size: 0x%08x",
	ld_stack_base, ld_stack_size);
  debug("ld_prog_entry: 0x%08x", ld_prog_entry);

}
