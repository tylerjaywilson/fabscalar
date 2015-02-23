/* This file is a part of the SimpleScalar tool suite written by
 * Todd M. Austin, University of Wisconsin - Madison, Computer Sciences
 * Department as a part of the Multiscalar Research Project.
 *  
 * The SimpleScalar x86 port was written by Steve Bennett.
 * 
 * The tool suite is currently maintained by Doug Burger.
 * 
 * Copyright (C) 1994, 1995, 1996 by Todd M. Austin
 *
 * This source file is distributed in the hope that it will be useful,
 * but without any warranty.  No author or distributor accepts
 * any responsibility for the consequences of its use.
 *
 * Everyone is granted permission to copy, modify and redistribute
 * this source file under the following conditions:
 *
 *    Permission is granted to anyone to make or distribute copies
 *    of this source code, either as received or modified, in any
 *    medium, provided that all copyright notices, permission and
 *    nonwarranty notices are preserved, and that the distributor
 *    grants the recipient permission for further redistribution as
 *    permitted by this document.
 *
 *    Permission is granted to distribute this file in compiled
 *    or executable form under the same conditions that apply for
 *    source code, provided that either:
 *
 *    A. it is accompanied by the corresponding machine-readable
 *       source code,
 *    B. it is accompanied by a written offer, with no time limit,
 *       to give anyone a machine-readable copy of the corresponding
 *       source code in return for reimbursement of the cost of
 *       distribution.  This written offer must permit verbatim
 *       duplication by anyone, or
 *    C. it is distributed by someone who received only the
 *       executable form, and is accompanied by a copy of the
 *       written offer of source code that they received concurrently.
 *
 * In other words, you are welcome to use, share and improve this
 * source file.  You are forbidden to forbid anyone else to use, share
 * and improve what you give them.
 *
 * INTERNET: dburger@cs.wisc.edu
 * US Mail:  1210 W. Dayton Street, Madison, WI 53706
 */

#include <stdio.h>
#include <stdlib.h>

/*#if defined(hpux) || defined(__hpux) || defined(__CYGWIN32__)
#include <strings.h>
#include <stdarg.h>
#else
#include <varargs.h>
#endif
*/
#include <stdarg.h>
#include <unistd.h>

//KAR: HP __builtin_va_args(code) missing fix
//for more goto: http://hpux.u-aizu.ac.jp/hppd/FAQ/8-5.html
#undef va_start
#define va_start(a,b) ((a)=(va_list)&(b))
#include <string.h>

#include "misc.h"

/* debug flag */
int verbose = FALSE;

static void (*hook_fn)(FILE *stream) = NULL;

void
fatal_hook(void (*fn)(FILE *stream))
{
  hook_fn = fn;
}

void
_fatal(char *file, const char *func, int line, char *fmt, ...)
{
  va_list v;
  va_start(v, fmt);

  fprintf(stderr, "fatal: ");
  vfprintf(stderr, fmt, v);
  if (verbose)
    fprintf(stderr, " [%s:%s, line %d]", func, file, line);
  fprintf(stderr, "\n");
  if (hook_fn)
    (*hook_fn)(stderr);
  exit(1);
}

void
_panic(char *file, const char *func, int line, char *fmt, ...)
{
  va_list v;
  va_start(v, fmt);

  fprintf(stderr, "panic: ");
  vfprintf(stderr, fmt, v);
  fprintf(stderr, " [%s:%s, line %d]\n", func, file, line);
  if (hook_fn)
    (*hook_fn)(stderr);
  abort();
}

void
_warn(char *file, const char *func, int line, char *fmt, ...)
{
  va_list v;
  va_start(v, fmt);

  fprintf(stderr, "warning: ");
  vfprintf(stderr, fmt, v);
  if (verbose)
    fprintf(stderr, " [%s:%s, line %d]", func, file, line);
  fprintf(stderr, "\n");
}

void
_info(char *file, const char *func, int line, char *fmt, ...)
{
    va_list v;
    va_start(v, fmt);

  vfprintf(stderr, fmt, v);
  if (verbose)
    fprintf(stderr, " [%s:%s, line %d]", func, file, line);
  fprintf(stderr, "\n");
}

#ifdef DEBUG
void
_debug(char *file, const char *func, int line, char *fmt, ...)
{
    va_list v;
    va_start(v, fmt);

    fprintf(stderr, "debug:");
    vfprintf(stderr, fmt, v);
    fprintf(stderr, " [%s:%s, line %d]\n", func, file, line);
}
#endif /* DEBUG */


/* copy a string to a new storage allocation */
char *
strdup(const char *s)
{
  char *buf;

  if (!(buf = (char *)malloc(strlen(s)+1)))
    return NULL;
  strcpy(buf, s);
  return buf;
}

/* allocate some core, this memory has overhead no larger than a page
   in size and it cannot be released. the storage is returned cleared */
void *
getcore(int nbytes)
{
#define PURIFY // MJD Fix?
#ifndef PURIFY
  void *p = sbrk(nbytes);

  if (p == (void *)-1)
    return NULL;

  /* this may be superfluous */
  bzero((char*)p, nbytes);
  return p;
#else
  return calloc(nbytes, 1);
#endif /* PURIFY */
}

/* return string describing elapsed time, passed in SEC in seconds */
char *
elapsed_time(long sec)
{
  static char tstr[256];
  char temp[256];

  if (sec <= 0)
    return "0s";

  tstr[0] = '\0';

  /* days */
  if (sec >= 86400)
    {
      sprintf(temp, "%ldD ", sec/86400);
      strcat(tstr, temp);
      sec = sec % 86400;
    }
  /* hours */
  if (sec >= 3600)
    {
      sprintf(temp, "%ldh ", sec/3600);
      strcat(tstr, temp);
      sec = sec % 3600;
    }
  /* mins */
  if (sec >= 60)
    {
      sprintf(temp, "%ldm ", sec/60);
      strcat(tstr, temp);
      sec = sec % 60;
    }
  /* secs */
  if (sec >= 1)
    {
      sprintf(temp, "%lds ", sec);
      strcat(tstr, temp);
    }
  tstr[strlen(tstr)-1] = '\0';
  return tstr;
}

int
log_base2(int n)
{
  int power = 0;

  if (n <= 0 || (n & (n-1)) != 0)
    panic("log2() only works for positive power of two values");

  while (n >>= 1)
    power++;

  return power;
}

/* get option letter from argument vector */
#define	BADCH	(int)'?'
#define	EMSG	""

/* if error message should be printed */
int	getopt_error = TRUE;

/* index into parent argv vector */
int	getopt_index = 1;

/* argument associated with option */
char *getopt_arg;

/* character checked for validity */
static int optopt1;

/* option letter processing */
static char *place = EMSG;

void
getopt_init(void)
{
  getopt_arg = NULL;
  getopt_error = FALSE;
  getopt_index = 0;
  optopt1 = 0;
  place = EMSG;
}

char
getopt_next(int nargc, char **nargv, char *ostr)
{
  char *oli;			/* option letter list index */
  char *p;

  if (!*place)
    {
      /* update scanning pointer */
      if (getopt_index >= nargc || *(place = nargv[getopt_index]) != '-')
	{
	  place = EMSG;
	  return (EOF);
	}
      if (place[1] && *++place == '-')
	{
	  /* found "--" */
	  ++getopt_index;
	  place = EMSG;
	  return (EOF);
	}
    }
  /* option letter okay? */
  if ((optopt1 = (int)*place++) == (int)':' || !(oli = strchr(ostr, optopt1)))
    {
      /* For backwards compatibility: don't treat '-' as an option letter
	 unless caller explicitly asked for it. */
      if (optopt1 == (int)'-')
	return (EOF);
      if (!*place)
	++getopt_index;
      if (getopt_error)
	{
	  if (!(p = strrchr(*nargv, '/')))
	    p = *nargv;
	  else
	    ++p;
	  fatal("%s: illegal option -- %c\n", p, optopt1);
	}
      return (BADCH);
    }
  if (*++oli != ':')
    {
      /* don't need argument */
      getopt_arg = NULL;
      if (!*place)
	++getopt_index;
    }
  else
    {
      /* need an argument */
      /* no white space */
      if (*place)
	getopt_arg = place;
      else if (nargc <= ++getopt_index)
	{
	  /* no arg */
	  place = EMSG;
	  if (!(p = strrchr(*nargv, '/')))
	    p = *nargv;
	  else
	    ++p;
	  if (getopt_error)
	    fatal("%s: option requires an argument -- %c\n", p, optopt1);
	  return (BADCH);
	}
      else
	{
	  /* white space */
	  getopt_arg = nargv[getopt_index];
	}
      place = EMSG;
      ++getopt_index;
    }
  /* dump back option letter */
  return (optopt1);
}

char *
getopt_combine_options(char *opt1, char *opt2)
{
  char *s;

  /* check for duplicates */
  for (s=opt1; *s; s++)
    if (*s != ':' && strchr(opt2, *s))
      fatal("duplicate option `%c'", *s);

  s = (char*)malloc(strlen(opt1)+strlen(opt2)+1);
  strcpy(s, opt1);
  strcat(s, opt2);
  return s;
}
