//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Matbi / Austin
//
// Create Date:
// Design Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description: test fc core
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"  // To measure of processing time
#include <stdlib.h>	  // To generate rand value
#include <assert.h>

#define DATA_GEN 1
#define SW_RUN 2
#define HW_RUN 3
#define CHECK 4

#define AXI_DATA_BYTE 4
#define NUM_CORE 4

#define IDLE 1
#define DONE 1 << 4

#define REG_IFMAP_BRAM_ADDR_RESET_TO_ZERO 0
#define REG_IFMAP_BRAM_DATA_WRITE 1
#define REG_WEIGHT_BRAM_ADDR_RESET_TO_ZERO 2
#define REG_WEIGHT_BRAM_DATA_WRITE 3
#define REG_STATE_CHECK 4
#define REG_OFMAP_BRAM_ADDR_RESET_TO_ZERO 5
#define GEN_IFMAP_BRAM_INIT_RUN 6
#define GEN_WEIGHT_BRAM_INIT_RUN 7
#define REG_OFMAP_BRAM_DATA_WRITE 8
#define GEN_I_RUN 9
#define GEN_OFMAP_BRAM_INIT_RUN 10
#define READ_OFMAP 11
#define REG_C_DEBUG 12
#define REG_D_DEBUG 13
#define REG_E_DEBUG 14
#define REG_F_DEBUG 15

//
#define FW 4
#define FH 4
//
#define IW 2
#define IH 2
//
#define S 1
#define PAD 1
#define IN_C 1
#define OUT_C 1
//
#define ORIG_OW (FW + S * (IW - 1))
#define ORIG_OH (FH + S * (IH - 1))
//
#define PADDED_OW (FW + S * (IW - 1) - 2 * PAD)
#define PADDED_OH (FH + S * (IH - 1) - 2 * PAD)
//
#define   IFMAP_AWIDTH        10              // if an image size is 1024, the MEM_DEPTH is 2^20.
#define   IFMAP_DWIDTH      SIGNED_BITS
#define   IFMAP_MEM_DEPTH   IW * IH * IN_C
//
#define   WEIGHT_AWIDTH      10              //
#define   WEIGHT_DWIDTH      FW * SIGNED_BITS
#define   WEIGHT_MEM_DEPTH   IN_C * OUT_C * FH
//
#define   OFMAP_AWIDTH      10
#define   OFMAP_DWIDTH      OFMAP_BITS

#if PAD
  #define OW (PADDED_OW)
  #define OH (PADDED_OH)
  #define OFMAP_MEM_DEPTH (PADDED_OW * PADDED_OH * OUT_C)
#else
  #define OW (ORIG_OW)
  #define OH (ORIG_OH)
  #define OFMAP_MEM_DEPTH (ORIG_OW * ORIG_OH * OUT_C)
#endif
//

void* SW_RUN_CONVTRANSPOSE2D(int seed)
{
    srand(seed);
    // === ?? ?? ===
    int (*ifmap)[IH][IW] = malloc(sizeof(int) * IN_C * IH * IW);
    int (*kernel)[OUT_C][FH][FW] = malloc(sizeof(int) * IN_C * OUT_C * FH * FW);
    int (*ofmap)[ORIG_OH][ORIG_OW] = malloc(sizeof(int) * OUT_C * ORIG_OH * ORIG_OW);
    int (*intermediate)[FH][FW] = malloc(sizeof(int) * IW * IH * IN_C * OUT_C * FH * FW);
    int (*padded_ofmap)[PADDED_OH][PADDED_OW] = malloc(sizeof(int) * OUT_C * PADDED_OH * PADDED_OW);

    if (!ifmap || !kernel || !ofmap || !intermediate || !padded_ofmap)
    {
        // printf("??? ?? ??\n");
        free(ifmap);
        free(kernel);
        free(intermediate);
        free(ofmap);
        free(padded_ofmap);
        return 1;
    }


    // ofmap ??? (??!)
    for (int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        for (int j = 0; j < ORIG_OH; j++)
            for (int k = 0; k < ORIG_OW; k++)
                ofmap[OUT_C_IDX][j][k] = 0;


    for(int IN_C_IDX = 0; IN_C_IDX < IN_C; IN_C_IDX++)
    {
        for(int IH_IDX = 0; IH_IDX < IH; IH_IDX++)
        {
            for(int IW_IDX = 0; IW_IDX < IW; IW_IDX++)
            {
                int random = (rand() % 256) - 128;
                ifmap[IN_C_IDX][IH_IDX][IW_IDX] = random;
                // printf("ifmap: (%d, %d, %d) : %d\n", IN_C_IDX, IH_IDX, IW_IDX, ifmap[IN_C_IDX][IH_IDX][IW_IDX]);
            }
        }
    }

    for(int IN_C_IDX = 0; IN_C_IDX < IN_C; IN_C_IDX++)
    {
        for(int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        {
            for(int FH_IDX = 0; FH_IDX < FH; FH_IDX++)
            {
                for(int FW_IDX = 0; FW_IDX < FW; FW_IDX++)
                {
                     int random = (rand() % 256) - 128;
                    kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] = random;
                    // printf("kernel: (%d, %d, %d, %d) : %d\n", IN_C_IDX, OUT_C_IDX, FH_IDX, FW_IDX, kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX]);
                }
            }
        }
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-



    // *-*-*-*-*-*- intermediate FW*FH? IW*IH?, ?? IN_C? ?? ?? ? OUT_C? *-*-*-*-*-*-
    for(int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
    {
        for(int IN_C_IDX = 0; IN_C_IDX < IN_C; IN_C_IDX++)
        {
            for(int IH_IDX = 0; IH_IDX <IH; IH_IDX++)                  // i
            {
                for(int IW_IDX = 0; IW_IDX < IW; IW_IDX++)             // j
                {
                    for(int FH_IDX = 0; FH_IDX < FH; FH_IDX++)         // k
                    {
                        for(int FW_IDX = 0; FW_IDX < FW; FW_IDX++)     // z
                        {
                            intermediate[IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX][FH_IDX][FW_IDX] = kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX];

                            // printf("intermediate: (%d, %d, %d, %d) : %d\n", OUT_C_IDX, IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX, FH_IDX, FW_IDX, kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX]);

                            ofmap[OUT_C_IDX][FH_IDX + S * IH_IDX][FW_IDX + S * IW_IDX] += intermediate[IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX][FH_IDX][FW_IDX];
                        }
                    }
                }
            }
        }
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-


    // *-*-*-*-*-*- PAD *-*-*-*-*-*-
    if(PAD)
    {
        // padded_ofmap ???
        for (int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
            for (int i = 0; i < PADDED_OH; i++)
                for (int j = 0; j < PADDED_OW; j++)
                    padded_ofmap[OUT_C_IDX][i][j] = 0;

        for(int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        {
            for(int i=PAD; i<PAD+PADDED_OH; i++)
            {
                for(int j=PAD; j<PAD+PADDED_OW; j++)
                {
                    padded_ofmap[OUT_C_IDX][i-PAD][j-PAD] = ofmap[OUT_C_IDX][i][j];
                    // printf("padded_ofmap: (%d, %d, %d): %d\n", OUT_C_IDX, i-PAD,j-PAD,padded_ofmap[OUT_C_IDX][i-PAD][j-PAD]);
                }
            }
        }

        free(ifmap);
        printf("free ifmap\n");
        free(kernel);
        printf("free kernel\n");
        free(intermediate);
        printf("free itmd\n");
        free(ofmap);
        printf("free ofmap\n");
        printf("PADDED OFMAP RETURN, SUCCESS\n");
        return padded_ofmap;
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

    else
    {
        free(ifmap);
        printf("free ifmap\n");
        free(kernel);
        printf("free kernel\n");
        free(intermediate);
        printf("free itmd\n");
        free(padded_ofmap);
        printf("free padded_ofmap\n");
        printf("OFMAP RETURN, SUCCESS\n");
    	return ofmap;
    }
}

// }

// void* SW_RUN_CONVTRANSPOSE2D(int seed)
// {
//     srand(seed);

//     int (*ifmap)[IH][IW] = malloc(sizeof(int) * IN_C * IH * IW);
//     int (*kernel)[OUT_C][FH][FW] = malloc(sizeof(int) * IN_C * OUT_C * FH * FW);
//     int (*ofmap)[ORIG_OH][ORIG_OW] = calloc(OUT_C, sizeof(int) * ORIG_OH * ORIG_OW);  // calloc으로 0 초기화
//     int (*padded_ofmap)[PADDED_OH][PADDED_OW] = malloc(sizeof(int) * OUT_C * PADDED_OH * PADDED_OW);

//     if (!ifmap || !kernel || !ofmap || !padded_ofmap) {
//         printf("메모리 할당 실패\n");
//         free(ifmap); free(kernel); free(ofmap); free(padded_ofmap);
//         return NULL;
//     }

//     // ifmap, kernel 초기화
//     for(int c = 0; c < IN_C; c++)
//         for(int i = 0; i < IH; i++)
//             for(int j = 0; j < IW; j++)
//                 ifmap[c][i][j] = (rand() % 256) - 128;

//     for(int c = 0; c < IN_C; c++)
//         for(int oc = 0; oc < OUT_C; oc++)
//             for(int i = 0; i < FH; i++)
//                 for(int j = 0; j < FW; j++)
//                     kernel[c][oc][i][j] = (rand() % 256) - 128;

//     // ConvTranspose2D 연산 (intermediate 생략, 바로 누적)
//     for(int oc = 0; oc < OUT_C; oc++) {
//         for(int ic = 0; ic < IN_C; ic++) {
//             for(int ih = 0; ih < IH; ih++) {
//                 for(int iw = 0; iw < IW; iw++) {
//                     int val = ifmap[ic][ih][iw];
//                     for(int fh = 0; fh < FH; fh++) {
//                         for(int fw = 0; fw < FW; fw++) {
//                             int oh = fh + S * ih;
//                             int ow = fw + S * iw;
//                             ofmap[oc][oh][ow] += val * kernel[ic][oc][fh][fw];
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     // padding 처리
//     if (PAD) {
//         for (int oc = 0; oc < OUT_C; oc++)
//             for (int i = 0; i < PADDED_OH; i++)
//                 for (int j = 0; j < PADDED_OW; j++)
//                     padded_ofmap[oc][i][j] = 0;

//         for (int oc = 0; oc < OUT_C; oc++)
//             for (int i = 0; i < ORIG_OH; i++)
//                 for (int j = 0; j < ORIG_OW; j++)
//                     padded_ofmap[oc][i + PAD][j + PAD] = ofmap[oc][i][j];

//         free(ifmap); free(kernel); free(ofmap);
//         return padded_ofmap;
//     } else {
//         free(ifmap); free(kernel); free(padded_ofmap);
//         return ofmap;
//     }
// }

int main()
{
	int seed;
    int case_num;
    int read_data;
    XTime tStart, tEnd;
	volatile int i, core;

	// char *write_buf_ifmap; // 8bit signed
	// write_buf_ifmap = (char *) malloc(sizeof(char) * IFMAP_MEM_DEPTH);

	int *write_buf_ifmap; // 8bit signed
	write_buf_ifmap = (int *) malloc(sizeof(int) * IFMAP_MEM_DEPTH);

	int *write_buf_weight; // 32bit = 8bit signed * 4?
	write_buf_weight = (int *) malloc(sizeof(int) * WEIGHT_MEM_DEPTH);

	int *ofmap; // 32bit = 8bit signed * 4?
	ofmap = (int *) malloc(sizeof(int) * OFMAP_MEM_DEPTH);

	int* ofmap_gold_ref;

	int IN_WEGT[NUM_CORE]; // 8b

    while (1)
	{
    	printf("plz input run mode\n");
    	printf("1. RAND_DATA_GEN \n");
    	printf("2. SW RUN \n");
    	printf("3. HW RUN \n");
    	printf("4. CHECK SW vs HW result\n");

    	scanf("%d",&case_num);

    	if (case_num == DATA_GEN)
		{
			printf("plz input rand seed value\n");
			scanf("%d", &seed);

    		srand(seed);

    		for(i=0; i< IFMAP_MEM_DEPTH ; i++)
			{
    			 write_buf_ifmap[i] = (rand() % 256) - 128; // signed 8bit
    		}

			for(i=0; i< WEIGHT_MEM_DEPTH ; i++)
			{
    			write_buf_weight[i] = 0; // init
        		for (core = 0; core < FW; core++)
				{
        			 IN_WEGT[core] = (rand() % 256) - 128; // signed 8bit
        		}

        	    write_buf_weight[i] = ((IN_WEGT[3] & 0xFF) << 24) |
        	                          ((IN_WEGT[2] & 0xFF) << 16) |
        	                          ((IN_WEGT[1] & 0xFF) << 8 ) |
        	                          ((IN_WEGT[0] & 0xFF));
        	    
				printf("i=%d: IN_WEGT = {%d, %d, %d, %d} => packed = %d (0x%08X)\n",
        	           i, IN_WEGT[0], IN_WEGT[1], IN_WEGT[2], IN_WEGT[3],
        	           write_buf_weight[i], write_buf_weight[i]);
    		}
    		printf("Success. Input gen \n");
    	}
		//
		else if(case_num == SW_RUN)
		{
    		XTime_GetTime(&tStart);
			ofmap_gold_ref = (int*)SW_RUN_CONVTRANSPOSE2D(seed);
			printf("SW_RUN, SUCCESS\n");
    		XTime_GetTime(&tEnd);
    		printf("ConvTranspose2D calc SW Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
    	}
		//
		else if(case_num == HW_RUN)
		{
    		double hw_processing_time =0.0;
    		//
			//
			//

			// BRAM INITIALIZATION
			XTime_GetTime(&tStart);
			//
			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_IFMAP_BRAM_ADDR_RESET_TO_ZERO * AXI_DATA_BYTE), (u32)(0x00000000)); // ifmap bram addr set to zero
			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (GEN_IFMAP_BRAM_INIT_RUN * AXI_DATA_BYTE), 1);	// generate ifmap bram init run signal
			for(i=0; i< IFMAP_MEM_DEPTH ; i++)
			{
				Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_IFMAP_BRAM_DATA_WRITE * AXI_DATA_BYTE), write_buf_ifmap[i]); // write_buf_ifmap send to ifmap bram for initialization
			}
			//
			XTime_GetTime(&tEnd);
			//
			printf("IFMAP BRAM Write Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
			hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);
			//
			//
			//
			XTime_GetTime(&tStart);
    		Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_WEIGHT_BRAM_ADDR_RESET_TO_ZERO * AXI_DATA_BYTE), (u32)(0x00000000)); // weight bram addr set to zero
			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (GEN_WEIGHT_BRAM_INIT_RUN * AXI_DATA_BYTE), 1);	// generate weight bram init run signal

			for(i=0; i< WEIGHT_MEM_DEPTH ; i++)
			{
    			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_WEIGHT_BRAM_DATA_WRITE * AXI_DATA_BYTE), write_buf_weight[i]);	// write_buf_weight send to weight bram for initialization
    		}
			//
			XTime_GetTime(&tEnd);
			//
			printf("WEIGHT BRAM Write Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
			hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);
			//
			//
			//
			XTime_GetTime(&tStart);
    		Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_OFMAP_BRAM_ADDR_RESET_TO_ZERO * AXI_DATA_BYTE), (u32)(0x00000000)); // ofmap bram addr set to zero
			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (GEN_OFMAP_BRAM_INIT_RUN * AXI_DATA_BYTE), 1);	// generate ofmap bram init run signal
			//
    		for(i=0; i< OFMAP_MEM_DEPTH ; i++)
    		{
    			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (REG_OFMAP_BRAM_DATA_WRITE * AXI_DATA_BYTE), 0);	// zero value send to ofmap bram for initialization
    		}
			//
			XTime_GetTime(&tEnd);
			//
			printf("OFMAP BRAM CLEAR Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
			hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);

			//
			//
			//

			// START OPERATION OF CT MODULE
			XTime_GetTime(&tStart);
			do
			{
    			read_data = Xil_In32((XPAR_CT_IP_0_BASEADDR) + (REG_STATE_CHECK*AXI_DATA_BYTE));
    		} while( (read_data & IDLE) != IDLE);	// wait until IDLE
			//
			Xil_Out32((XPAR_CT_IP_0_BASEADDR) + (GEN_I_RUN * AXI_DATA_BYTE), 1);	// generate i_run signal to operate convtranspose2d module
			//
			do
			{
				read_data = Xil_In32((XPAR_CT_IP_0_BASEADDR) + (4 *AXI_DATA_BYTE));
			} while((read_data & DONE) != DONE);	// wait until DONE == end of CT module operation
			//
    		XTime_GetTime(&tEnd);
			//
    		printf("ConvTranspose2D Calculation Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
    		hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);

			//
			//
			//

    		// READ_OFMAP
    		XTime_GetTime(&tStart);
			for(int i = 0; i < OFMAP_MEM_DEPTH; i++)
			{
				ofmap[i] = Xil_In32((XPAR_CT_IP_0_BASEADDR) + (READ_OFMAP * AXI_DATA_BYTE));	// read ofmap from ofmap bram
			}
			//
			XTime_GetTime(&tEnd);
    		printf("ConvTranspose2D ofmap read Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
    		hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);
    		//
			//
			//
			printf("Total HW Run time %.2f us.\n",hw_processing_time);
    	}
		else if(case_num == CHECK)
		{
			int mismatch_cnt = 0;
			for(i=0; i< OFMAP_MEM_DEPTH; i++)
			{
				printf("idx : %d, ofmap_gold_ref : %d, ofmap : %d\n", i, ofmap_gold_ref[i], ofmap[i]);
				if(ofmap_gold_ref[i] != ofmap[i])
				{  // Check Result
					printf("Mismatch!! plz contact me. idx : %d, ofmap_gold_ref : %d, ofmap : %d\n", i, ofmap_gold_ref[i], ofmap[i]);
					mismatch_cnt++;
				}
			}
			if(mismatch_cnt == 0)
			{
				printf("Success. Match Result\n");
			}
    	}

		else
		{
    		// no operation, exit
    		//break;
    	}
    }
    free(write_buf_ifmap);
    free(write_buf_weight);
	free(ofmap_gold_ref);
	free(ofmap);
    return 0;
}
