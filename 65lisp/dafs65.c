// DAFS65 - DAta FileSystem for 6502
//
// (C) 2025 Jonas S Karlsson, jsk@yesco.org
//

// This is meant as a simple Bigtable:ish flexible filesystem
// for ORIC ATMOS using DSK-files.
// 
// Technically, it doesn't implement a traditional fileystem
// instead provides and Bigtable/HBase-style interface to
// methods that can access data stored with a row-name
// (path/file) and additionally lightweight data items identified
// by a key (column-name). Each column-name is in a column-family
// (group).
//
// Smaller data items (<64 B?) are stored inline, and bigger items
// stored in their own sectors.
//
// As this is designed in 2025, we dispel the idea and limitations
// of physical media, assuming any sector/track/side is equally
// fast to access in any order. Of course, using real floppies
// or harddrives this isn't true. On the other hand, in year 2025
// even older homecomputers from the middle of 1980s are using
// virtualized storage: flash-drives where the physical limitations
// have been rendered basically irrelevant.
//
// However, to cooperate and be compatible with existing ORIC
// ATMOS drives; allowing for booting and have a read/write-
// data storage, we adopt and use the "loader.asm" functionality
// of the OSDK FloppyBuilding DSK-interface. This is supported not
// my multitues of PC-host softare but also works on actual legacy
// devices such as MicroDisk/Jasmin-drive/SEDORIC (assummed?), as
// well as newer virtualized devices like LOCI; twilight-board (?)
// etc.

// LOGIC
//
// The OKVS (Ordered Key Value Store) logically stores data
// like this:
//
// inline:
//
//   %RLEN %CLEN $ROWKEY %FAMILY $COLNAME %%VER %LEN $DATA \n
//
// outline: 
//
//   %LEN %CLEN $ROWKEY %FAMILY $COLNAME %%VER <DATAREF> \n
//
// % means one byte, %% indicates two bytes, %3FOO = 3 bytes,
// $ means "binary string" (can have \0 inside)
// \0 means a 0 byte, 4 = 0x04 one byte value, 0x1234 2 bytes
// # indicates varint:ish encoding, but BINARY sortable!
// (0=#0 11=#1 210=#10 3420=#420)
// 
// The zero bytes are redundant but may simplify handling data
// (or not?)
//
// $DATA of a %LEN < 64 bytes (configurable?) is stored inline.
// For larger data it's stored "outline" in it's own full sectors.
// The sectors are specified using a *logical row* each, using
// a <DATAREF> as folows:
//
// Version numbers are decreasing, putting latest row first
//
// 
// Examples:
//
//   LEN  |------------------- BINARY SORTED -------------------->
//   12 0 '/jsk/file1.c'    0 0x6941   38 'word main(){ printf("Hello World!\n");'
//   12 0 '/jsk/file1.c'    0 0x6942   38 'word main(){ printf("Hello world!\n");'
//   14 0 '/jsk/file1.exe'  0 0x6942   17 'KDFKSMKFHKFJDFKA'
//
// TODO: version number for sector updates doesn't order
//   good as version interferes with offset sector mapping?
//
// Probably should be
//

// deleted:
// (not store empty value/string== NULL? hmmm, not good)
// (maybe need to do this per ROW for every OUTLINE map row?)
//
//   %RLEN %CLEN $ROW %FAM $COL #0 %3VER 0x00

// NULL:
//   %RLEN %CLEN $ROW %FAM $COL #0 %3VER 0x01

// inline:
//   %RLEN %CLEN $ROW %FAM $COL #0 %3VER 0x02 %LEN $DATA

// OUTLINE length in bytes:
//   %RLEN %CLEN $ROW %FAM $COL #0 %3VER 0x03 %4LEN
//
// OUTLINE:
// (mmm)
//   %RLEN %CLEN $ROW %FAM $COL #OFFSET %3VER 0xff %3OFFSET %%VER %%%SECTOR
// (this isn't well ordered)
//   %RLEN %CLEN $ROW %FAM $COL %3VER 0xff %3OFFSET %%VER %%%SECTOR


//   15 0 '/jsk/file1.data' 0 0x6941 0xff 0x000001 0x001235 \n
//   15 0 '/jsk/file1.data' 0 0x6942 0xff 0x000000 0x001234 \n
//   15 0 '/jsk/file1.data' 0 0x6942 0xff 0x000001 0x001235 \n
//   15 0 '/jsk/file1.data' 0 0x6942 0xff 0x000003 0x003523 \n


// Physically these are stored with (two) prefix-compression:
//
//   %RLEN %CLEN %prefixlen
//
//   12  0 12 '/jsk/file1.c' 0 0 0x6941 38 'word main(){ printf("Hello World!\n");' \n
//   12  0 15                      0x42 38 'word main(){ printf("Hello world!\n");' \n
//   14 11 'exe' 4 6942 17 'KDFKSMKFHKFJDFKA' \n



// FILE SYSTEM SIZE
//
// Fundamentally, a DSK (filesystem in an file) seems to be
// governed by:
//
//   DSK-GEOMETRY(sides: 1-2, tracks: 0-255?, sectors: 0-255?)
//
// With a sector-size of 256-bytes, this potentially can address
// (/ (* 2 256 256 256) 1024 1024) = 32 MB of data.
//
// If sides could be more (256?) we potentially could address 4 GB.
//

//
//
// Operations:
//   dafs_setfamily(char family)
//   dafs_setkey(char* path, char* key)
//   dafs_put(char* data)->intlen (NULL: delete, otherwise update)
//   dafs_get(char* data, long offset, uint len)->uintnread
//   dafs_next()
//   dafs_path()->char*
//   dafs_key()->char*
//   dafs_family()->char
//   dafs_len()->longlen


