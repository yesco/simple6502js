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

