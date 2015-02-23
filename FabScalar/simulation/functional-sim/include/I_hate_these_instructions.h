

/********************************************/
/* ER 09-14-04: Fixed lwl/lwr/swl/swr code. */
/* VKR: This version is similar to SS 3.0.  */
/********************************************/


#define WORDALIGN(addr)		((addr) & ~0x03)



#ifdef BYTES_LITTLE_ENDIAN


#define LWL_MACRO(addr, load_data, back_data)				\
(									\
((back_data                           ) &  WR_PROT_MASK1(addr)) |	\
((load_data << (8 * (WL_SIZE(addr)-1))) & ~WR_PROT_MASK1(addr))		\
)

#define LWR_MACRO(addr, load_data, back_data)				\
(									\
((back_data                           ) & ~WL_PROT_MASK2(addr)) |	\
((load_data >> (8 * (WR_SIZE(addr)-1))) &  WL_PROT_MASK2(addr))		\
)

#define SWL_MACRO(addr, store_data, back_data)				\
(									\
((store_data >> (8 * (4 - WR_SIZE(addr)))) &  WR_PROT_MASK2(addr)) |	\
((back_data                              ) & ~WR_PROT_MASK2(addr))	\
)

#define SWR_MACRO(addr, store_data, back_data)				\
(									\
((store_data << (8 * (4 - WL_SIZE(addr)))) & ~WL_PROT_MASK1(addr)) |	\
((back_data                              ) &  WL_PROT_MASK1(addr))	\
)


#else /*BIG ENDIAN*/


#define LWL_MACRO(addr, load_data, back_data)				\
(									\
((back_data                       ) &  WL_PROT_MASK1(addr)) |		\
((load_data << (8 * WL_SIZE(addr))) & ~WL_PROT_MASK1(addr))		\
)

#define LWR_MACRO(addr, load_data, back_data)				\
(									\
((back_data                             ) & ~WR_PROT_MASK1(addr)) |	\
((load_data >> (8 * (4 - WR_SIZE(addr)))) &  WR_PROT_MASK1(addr))	\
)

#define SWL_MACRO(addr, store_data, back_data)				\
(									\
((store_data >> (8 * WL_SIZE(addr))) &  WL_PROT_MASK2(addr)) |		\
((back_data                        ) & ~WL_PROT_MASK2(addr))		\
)

#define SWR_MACRO(addr, store_data, back_data)				\
(									\
((store_data << (8 * (4 - WR_SIZE(addr)))) & ~WR_PROT_MASK2(addr)) |	\
((back_data                              ) &  WR_PROT_MASK2(addr))	\
)


#endif
