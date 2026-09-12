//
//  CT_OFMAP_VERIFICATION.c
//  C_HW
//
//  Created by 서정윤 on 3/25/25.
//

#include <stdio.h>
#include <stdlib.h>

#define IW              2
#define IH              2
//
#define FW              3
#define FH              3
//
#define IN_C            2
#define OUT_C           5
#define S               1
#define PAD             1
//
#define ORIG_OW     (FW + S*(IW-1))
#define ORIG_OH     (FH + S*(IH-1))
//
#define PADDED_OW   (FW + S*(IW-1) - 2*PAD)
#define PADDED_OH   (FH + S*(IH-1) - 2*PAD)
//
#define OW          (PAD ? PADDED_OW : ORIG_OW)
#define OH          (PAD ? PADDED_OH : ORIG_OH)

int main()
{
//    printf("%d", OH);
    srand(2);
    // === 동적 할당 ===
    int (*ifmap)[IH][IW] = malloc(sizeof(int) * IN_C * IH * IW);
    int (*kernel)[OUT_C][FH][FW] = malloc(sizeof(int) * IN_C * OUT_C * FH * FW);
    int (*ofmap)[ORIG_OH][ORIG_OW] = malloc(sizeof(int) * OUT_C * ORIG_OH * ORIG_OW);
    int (*intermediate)[FH][FW] = malloc(sizeof(int) * IW * IH * IN_C * OUT_C * FH * FW);

    if (!ifmap || !kernel || !ofmap || !intermediate)
    {
        printf("메모리 할당 실패\n");
        goto cleanup;
        return 1;
    }

    
    // ofmap 초기화 (중요!)
    for (int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        for (int j = 0; j < ORIG_OH; j++)
            for (int k = 0; k < ORIG_OW; k++)
                ofmap[OUT_C_IDX][j][k] = 0;
    
    
    // *-*-*-*-*-*- DATA INIT *-*-*-*-*-*-*-*-
    FILE *ifmap_fp;
    ifmap_fp = fopen("/Users/seojeongyun/Desktop/ConvTranspose2D/from_C/gold_ref/ifmap.txt", "w");
    if (ifmap_fp == NULL)
    {
        printf("파일 열기 실패\n");
        goto cleanup;
    }
    //
    for(int IN_C_IDX = 0; IN_C_IDX < IN_C; IN_C_IDX++)
    {
        for(int IH_IDX = 0; IH_IDX < IH; IH_IDX++)
        {
            for(int IW_IDX = 0; IW_IDX < IW; IW_IDX++)
            {
                int random = rand() % 256 - 127;
//                int random = rand() % 2+1;
                ifmap[IN_C_IDX][IH_IDX][IW_IDX] = random;
                fprintf(ifmap_fp, "%d\n", ifmap[IN_C_IDX][IH_IDX][IW_IDX]);
                printf("ifmap: (%d, %d, %d) : %d\n", IN_C_IDX, IH_IDX, IW_IDX, ifmap[IN_C_IDX][IH_IDX][IW_IDX]);
            }
        }
    }
    
    FILE *kernel_fp;
    kernel_fp = fopen("/Users/seojeongyun/Desktop/ConvTranspose2D/from_C/gold_ref/kernel.txt", "w");
        if (kernel_fp == NULL)
        {
            printf("파일 열기 실패\n");
            goto cleanup;
        }
    
    for(int IN_C_IDX = 0; IN_C_IDX < IN_C; IN_C_IDX++)
    {
        for(int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        {
            for(int FH_IDX = 0; FH_IDX < FH; FH_IDX++)
            {
                for(int FW_IDX = 0; FW_IDX < FW; FW_IDX++)
                {
                    int random = rand() % 256 - 127;
//                    int random = rand() % 2 + 1;
                    kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] = random;
                    fprintf(kernel_fp, "%d\n", kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX]);
                    printf("kernel: (%d, %d, %d, %d) : %d\n", IN_C_IDX, OUT_C_IDX, FH_IDX, FW_IDX, kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX]);
                }
            }
        }
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
    
    
    
    // *-*-*-*-*-*- intermediate FW*FH가 IW*IH개, 그게 IN_C개 있고 그게 또 OUT_C개 *-*-*-*-*-*-
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
//                            intermediate[OUT_C_IDX][IN_C_IDX][IW_IDX + IH * IH_IDX][FH_IDX][FW_IDX] = kernel[OUT_C_IDX][IN_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX];
                            
//                            printf("intermediate: (%d, %d, %d, %d, %d) : %d\n",OUT_C_IDX, IN_C_IDX, IW_IDX + IH * IH_IDX, FH_IDX, FW_IDX,kernel[OUT_C_IDX][IN_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX]);
                            
                            intermediate[IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX][FH_IDX][FW_IDX] = kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX];
                            
                            printf("intermediate: (%d, %d, %d, %d) : %d\n", OUT_C_IDX, IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX, FH_IDX, FW_IDX, kernel[IN_C_IDX][OUT_C_IDX][FH_IDX][FW_IDX] * ifmap[IN_C_IDX][IH_IDX][IW_IDX]);
                            
                            ofmap[OUT_C_IDX][FH_IDX + S * IH_IDX][FW_IDX + S * IW_IDX] += intermediate[IW_IDX + IH * IH_IDX + IW * IH * IN_C_IDX + IW * IH * IN_C * OUT_C_IDX][FH_IDX][FW_IDX];
                        }
                    }
                }
            }
        }
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
    
    
    FILE *output_fp;
    output_fp = fopen("/Users/seojeongyun/Desktop/ConvTranspose2D/from_C/gold_ref/output.txt", "w");
    if (!output_fp) { printf("output 파일 열기 실패\n"); goto cleanup; }

    
    
    // *-*-*-*-*-*- PAD *-*-*-*-*-*-
    if(PAD)
    {
        int (*padded_ofmap)[PADDED_OH][PADDED_OW] = malloc(sizeof(int) * OUT_C * PADDED_OH * PADDED_OW);
        if (!padded_ofmap) { printf("padded_ofmap 메모리 할당 실패\n"); fclose(output_fp); goto cleanup; }
        
        // padded_ofmap 초기화
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
                    fprintf(output_fp, "%d\n", padded_ofmap[OUT_C_IDX][i-PAD][j-PAD]);
                    printf("padded_ofmap: (%d, %d, %d): %d\n", OUT_C_IDX, i-PAD,j-PAD,padded_ofmap[OUT_C_IDX][i-PAD][j-PAD]);
                }
            }
        }
        free(padded_ofmap);
    }
    
    else
    {
        for(int OUT_C_IDX = 0; OUT_C_IDX < OUT_C; OUT_C_IDX++)
        {
            for(int j = 0; j < ORIG_OH; j++)
            {
                for(int k=0; k < ORIG_OW; k++)
                {
                    fprintf(output_fp, "%d\n", ofmap[OUT_C_IDX][j][k]);
                        printf("ofmap: (%d, %d, %d): %d\n",OUT_C_IDX, j, k, ofmap[OUT_C_IDX][j][k]);
                }
            }
        }
    }
    // *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
    
    
    // 파일 닫기
    fclose(ifmap_fp);
    fclose(kernel_fp);
    fclose(output_fp);
    
    printf("파일에 저장 완료!\n");
    goto cleanup;
    
cleanup:
    free(ifmap);
    free(kernel);
    free(ofmap);
    free(intermediate);
    
    return 0;
}



// BK
// *-*-*-*-*-*- intermediate FW*FH가 IW*IH개 *-*-*-*-*-*-
//for(int IH_IDX = 0; IH_IDX <IH; IH_IDX++)    // i
//{
//    for(int IW_IDX = 0; IH_IDX < IW; IH_IDX++)             // j
//    {
//        for(int FH_IDX = 0; FH_IDX < FH; FH_IDX++)         // k
//        {
//            for(int FW_IDX = 0; FW_IDX < FW; FW_IDX++)     // z
//            {
//                intermediate[j + IH*i][k][z] = kernel[k][z] * ifmap[i][j];
//                printf("intermediate: (%d,%d,%d) : %d\n",j + IH*i, k, z, kernel[k][z] * ifmap[i][j]);
//            }
//        }
//    }
//}
//// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
//
//
//// *-*-*-*-*-*- ACCUM *-*-*-*-*-*-
//for(int u = 0; u<IH; u++)
//{
//    for(int i = 0; i<IW; i++)
//    {
//        for(int j = 0; j < FH; j++)
//        {
//            for(int k=0; k < FW; k++)
//            {
//                ofmap[j+S*u][i*S+k] += intermediate[i+IH*u][j][k];
////                    printf("MEM_ADDR : %d\n", (j+S*u) * ORIG_OW + i*S+k);
//            }
//        }
//    }
//}
//// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-



// *-*-*-*-*-*- PAD *-*-*-*-*-*-
//if(PAD)
//{
//    int padded_ofmap[PADDED_OH][PADDED_OW] = {0};
//    
//    for(int i=PAD; i<PAD+PADDED_OH; i++)
//    {
//        for(int j=PAD; j<PAD+PADDED_OW; j++)
//        {
//            padded_ofmap[i-PAD][j-PAD] = ofmap[i][j];
//            fprintf(output_fp, "%d\n", padded_ofmap[i-PAD][j-PAD]);
//            printf("padded_ofmap: (%d, %d): %d\n",i-PAD,j-PAD,padded_ofmap[i-PAD][j-PAD]);
//        }
//    }
//}
//
//else
//{
//    for(int j = 0; j < ORIG_OH; j++)
//    {
//        for(int k=0; k < ORIG_OW; k++)
//        {
//            fprintf(output_fp, "%d\n", ofmap[j][k]);
//            printf("ofmap: (%d, %d): %d\n",j,k,ofmap[j][k]);
//        }
//    }
//}




//#include <stdio.h>
//
//int main()
//{
//    int ifmap_addr;
//    int orig_ofmap_row;
//    int orig_ofmap_col;
//    int pad_ofmap_row;
//    int pad_ofmap_col;
//    
//    // *-*-*-*-*-*- MEM_ADDR: PAD *-*-*-*-*-*-
//    for(int captured_ifmap_row = 0; captured_ifmap_row < IH; captured_ifmap_row++)
//    {
//        for(int captured_ifmap_col = 0; captured_ifmap_col < IW; captured_ifmap_col++)
//        {
//            ifmap_addr = captured_ifmap_col + IH * captured_ifmap_row;
//            
//            for(int intermediate_row_idx = 0; intermediate_row_idx < FH; intermediate_row_idx++)
//            {
//                if(PAD)
//                    orig_ofmap_row = intermediate_row_idx + S * captured_ifmap_row;
//                
//                for(int intermediate_col_idx = 0; intermediate_col_idx < FW; intermediate_col_idx++)
//                {
//                    if(PAD)
//                    {
//                        orig_ofmap_col = intermediate_col_idx + S * captured_ifmap_col;
//                        printf("NO PAD : %d,%d,%d\n",ifmap_addr, orig_ofmap_row, orig_ofmap_col);
//                        
//                        if(orig_ofmap_col >= PAD && PAD + PADDED_OW -1 >= orig_ofmap_col)
//                            pad_ofmap_col = orig_ofmap_col - PAD;
//                        
//                        if(orig_ofmap_row >= PAD && PAD + PADDED_OH -1 >= orig_ofmap_row)
//                            pad_ofmap_row = orig_ofmap_row - PAD;
//                        
//                        if (orig_ofmap_row >= PAD && orig_ofmap_row <= PAD + PADDED_OH -1 && orig_ofmap_col >= PAD && orig_ofmap_col <= PAD + PADDED_OW -1)
//                        {
//                            printf("PAD : %d,%d,%d\n",ifmap_addr, pad_ofmap_row, pad_ofmap_col);
//                            printf("MEM_ADDR (%d,%d,%d): %d\n", ifmap_addr, pad_ofmap_row, pad_ofmap_col, (pad_ofmap_row * PADDED_OH + pad_ofmap_col));
//                        }
//                    }
////
//                    else if(!PAD)
//                        printf("MEM_ADDR (%d,%d,%d): %d\n", ifmap_addr, intermediate_row_idx, intermediate_col_idx, (intermediate_row_idx + S * captured_ifmap_row) * ORIG_OW + (intermediate_col_idx + S * captured_ifmap_col));
//                }
//            }
//            printf("-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
//        }
//    }
//    
////    // *-*-*-*-*-*- MEM_ADDR: PAD *-*-*-*-*-*-
////    int ofmap_col_idx_;
////    int ofmap_row_idx_;
////    for(int captured_ifmap_row = 0; captured_ifmap_row < IH; captured_ifmap_row++)
////    {
////        for(int captured_ifmap_col = 0; captured_ifmap_col < IW; captured_ifmap_col++)
////        {
////            for(int ofmap_row_idx = 0; ofmap_row_idx < ORIG_OH; ofmap_row_idx++)
////            {
////                ofmap_row_idx_ = ofmap_row_idx;
////                for(int ofmap_col_idx = 0; ofmap_col_idx < ORIG_OW; ofmap_col_idx++)
////                {
////                    ofmap_col_idx_ = ofmap_col_idx;
////                    
////                    if(ofmap_col_idx >= PAD || PAD + PADDED_OW -1 >= ofmap_col_idx)
////                        ofmap_col_idx_ = ofmap_col_idx - PAD;
////                    
////                    if(ofmap_row_idx >= PAD || PAD + PADDED_OH -1 >= ofmap_row_idx)
////                        ofmap_row_idx_ = ofmap_row_idx - PAD;
////                    
////                    if (ofmap_row_idx_ >= PAD && ofmap_col_idx_ >= PAD)
////                    {
////                        printf("MEM_ADDR (%d,%d,%d): %d\n", captured_ifmap_col + IH * captured_ifmap_row, ofmap_row_idx_, ofmap_col_idx_, (ofmap_row_idx_ * ORIG_OH + ofmap_col_idx_));
////                    }
////                }
////            }
////        }
////    }
//    return 0;
//}
