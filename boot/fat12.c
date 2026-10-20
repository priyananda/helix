#include "fat12.h"

void error_msg(const char * message);

#define KERNEL_FILE "KERNEL  BIN"

#define lin2hts(linear,h,t,s) s = linear % 18 + 1; h = (linear /18)%2;t = linear / 36

#define KERNEL_SEG 0x1000;
#define KERNEL_OFF 0x0;

#define ROOT_SEG 0xA00
#define ROOT_OFF ((uint)root_buff)

#define FAT_SEG 0xA00
#define FAT_OFF ((uint)fat_buffer)

static u16 error;
static u16 curr_seg;
static u16 curr_off;

uint init(){
	__asm__ __volatile__ (
		"int $0x13\n"
		: "=a"(error)
		: "a"(0), "d"(0)
		: "memory", "cc"
	);
	error >>= 8;
	return error;
}

uint read(uint linear){
	unsigned char h,t,s;

	if(error)init();
	while(error == 6)init();
	if(error)return error;

	lin2hts(linear,h,t,s);
	/* int 13h, ah=2: read one sector into curr_seg:curr_off */
	__asm__ __volatile__ (
		"pushw %%es\n"
		"mov %w1, %%es\n"
		"int $0x13\n"
		"popw %%es\n"
		: "=a"(error)
		: "r"(curr_seg), "a"(0x0201), "b"(curr_off),
		  "c"((t << 8) | s), "d"(h << 8)
		: "memory", "cc"
	);
	error >>= 8;
	return error;
}

static unsigned char fat_buffer[512 * 9];
static unsigned char root_buff[512];

int searchRoot(){
	int linear = ROOT_DIR_SECT;
	int nRead,i,j;
	char * name = KERNEL_FILE;
	Directory * d;
	curr_seg = ROOT_SEG;
	curr_off = ROOT_OFF;
	for(nRead = 0;nRead < NO_ROOT_DIR_SECT;nRead++){
		if(read(linear++) != 0){
			error_msg("root dir read error");
			return 0;
		}
		d = (Directory*)root_buff;
		for(i = 0; i < 512 / sizeof(Directory);i++){
			if(IS_USED(d[i]) && IS_FILE(d[i])){
				for(j = 0;j < 11 && name[j] == d[i].fname[j];j++);	//Sorry
				if(j == 11)return d[i].cluster;
			}
		}
	}
	return 0;
}

int getCluster(int LogicalCluster)
{
	int sector = 0;
	int FatIndex = (LogicalCluster * 3)/2;
	if (LogicalCluster % 2 == 0){
		//split FatIndex + 1 for 4 most sig bits
		sector = fat_buffer[FatIndex + 1] & 0x0f;
		sector = sector << 8;
		sector = sector | fat_buffer[FatIndex];
	}else{
		//split FatIndex for 4 least sig bits
		sector = fat_buffer[FatIndex+1];
		sector = (sector << 4);
		sector = sector | (( fat_buffer[FatIndex] & 0xf0) >> 4);
	}
	return sector;
}

void loadFat(){
	int i;
	curr_seg = FAT_SEG;
	curr_off = FAT_OFF;
	for(i = 0;i < 9;i++)
		if(read(i + FAT_START)){
			error_msg("fat load error");
		}else{
			curr_off += 512;
		}
}

#define CLUS_2_LIN( __c ) ( (__c) + 31 )

int initk(){
    int cluster = searchRoot();
    if(!cluster){
		error_msg("kernel.bin not found");
		return 0;
	}
	loadFat();
	curr_seg = KERNEL_SEG;
	curr_off = KERNEL_OFF;
    return cluster;
}

int next(int cluster){
   	int linear;
   	if(cluster && cluster < 0xff0){
		linear = CLUS_2_LIN(cluster);
		read(linear);
		cluster = getCluster(cluster);
		curr_seg += 512/16;	//To remove the 64 kb file size limit
	}
    if(cluster >= 0xff0)cluster = 0;
    return cluster;
}

void load_kernel(){
	int cluster;
	int linear;
	error = 1;	// Lets us initialise the drive once
	cluster = searchRoot();
	if(!cluster){
		error_msg("kernel.bin not found");
		return;
	}
	loadFat();
	curr_seg = KERNEL_SEG;
	curr_off = KERNEL_OFF;
    while(cluster && cluster < 0xff0){
		linear = CLUS_2_LIN(cluster);
		read(linear);
		cluster = getCluster(cluster);
		curr_seg += 512/16;	//To remove the 64 kb file size limit
	}
}

