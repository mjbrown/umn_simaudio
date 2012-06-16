/*  
Author: Micah Hakala
Project: Simultaneous Audio Recording Interface (UMN Senior Design Project)
This code implements a command line recorder for the audio interface designed in the project.  The program accepts one argument or less; you can specify how many bytes to retrieve or not specify and use the default retrieval of 1,920,000 bytes.  The duration of the recording is determined by the byte retrieval quota/limit, the sample rate, and number of channels.  Byte data is pulled from the audio interface and stored in tempRecord.  tempRecord can be imported into Audacity or inspected with a hex editor.

The Digilent Adept SDK was used for USB transfers and device handling.  dpcdecl.h, dmgr.h, and dstm.h are the three includes from the Adept SDK used here.
*/

#define	_CRT_SECURE_NO_WARNINGS
#if defined(WIN32)
	#include <windows.h>	
#else
#endif
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include "dpcdecl.h"
#include "dmgr.h"
#include "dstm.h"

char szDvc[128] = "Basys1";   // Device name
struct timeval tv;
struct timeval tv2;

const int cbTx = 8192;
unsigned int limit = 1920000;
HIF hif;

BYTE rgbIn[cbTx];
BOOL fFail = fFalse;

void ErrorExit();

int main(int argc, char *argv[]) {
	int ibTx;
	
	// DMGR API Call: DmgrOpen
	if(!DmgrOpen(&hif, szDvc)) {
		printf("Error: Could not open device %s\n", szDvc);
		ErrorExit();
	}

	// DSTM API Call: DstmEnable
	if(!DstmEnableEx(hif,0)) {
		printf("Error: DstmEnable failed\n");
		ErrorExit();
	}
	FILE *fp;
	fp = fopen("tempRecord","wb");
	unsigned int sum = 0;
	unsigned int bytesUsed = 0;
	unsigned int newbytesize = 0;
	int ii = 0;
	int jj = 0;
	printf("Recording 16-bit 4-channel...\n");
	time_t time1 = time(NULL);
	gettimeofday(&tv, 0);
	if (argc > 1) {
		limit = atoi(argv[1]);
		printf("Byte limit = %d\n",limit);
	}
	while(bytesUsed<limit) {
		if(!DstmIOEx(hif, NULL, 0, rgbIn, cbTx, fFalse)) {
			printf("Error: DstmIO failed\n");
			ErrorExit();
		}
		newbytesize = 256*(unsigned int)rgbIn[0]+(unsigned int)rgbIn[1];
		if (newbytesize > cbTx) printf("Warning(>cbTx): %d newbytes, writing at %d (decimal)\n",newbytesize,bytesUsed);

		if(newbytesize%10 != 0) { //Cut off an unfinished frame, audio interface should retransmit the incomplete interleaved sample at next read.  %10 because 8 bytes are for the 4 16-bit channels, and another two bytes of a zero channel (for alignment)
			printf("Cul %dB\n", newbytesize%10);
			newbytesize -= newbytesize%10;
		}
		sum += newbytesize;
		int i;
		unsigned int sum2 = 0;
		for (i = 0; i < newbytesize; i++) {
			if (i+2< cbTx) {
				fprintf(fp,"%c",rgbIn[i+2]);
				bytesUsed++;
			}
		}
		ii++;
		Sleep(0); //Optional sleep in case USB transfers are saturating from being called too often
	}
	time_t time2 = time(NULL);
	gettimeofday(&tv2, 0);
	printf("\nFinished: Number of bytes read as \"new\" = %d\nBytes written to 'tempRecord.csv' = %d\nNumber of DstmIO calls = %d\nAverage new bytes per DstmIO call = %f\nRecording lasted %f seconds\ncbTx was %d\nActual sample rate was %f\n", sum, bytesUsed, ii,(sum+0.001)/ii,(tv2.tv_sec-tv.tv_sec)+((0.001+tv2.tv_usec-tv.tv_usec)/1000000),cbTx,bytesUsed/(2*((tv2.tv_sec-tv.tv_sec)+((0.001+tv2.tv_usec-tv.tv_usec)/1000000))));
	
	printf("Success!\n");
	
	if(!DstmDisable(hif)) {
		printf("Error: DstmDisable failed\n");
		ErrorExit();
	}
	
	if(!DmgrClose(hif)) {
		printf("Error: DmgrClose failed\n");
		ErrorExit();
	}
	return 0;
}

void ErrorExit() {
	if(hif != hifInvalid) {
		DstmDisable(hif);
		DmgrClose(hif);
	}
	exit(1);
}
