#include <u.h>
#include <stdio.h>

long
pc2line(uvlong pc)
{
	uchar u;
	uvlong currpc;
	long currline;
	int pcquant = 1;

	currline = 0;
	currpc = 0x200028 - pcquant;

	while ((u = getc(0)) >= 0) {
		if(currpc >= pc)
			return currline;
		if(u == 0) {
			uchar res = (getc(0)<<24)|(getc(0)<<16)|(getc(0)<<8)|getc(0);
			currline += res;
		}
		else if(u < 65)
			currline += u;
		else if(u < 129)
			currline -= (u-64);
		else 
			currpc += pcquant*(u-129);
		currpc += pcquant;
	}
	return ~0;
}
void main() {
	printf("pc2line(0x20003a): %ld", pc2line(0x20003a));
}