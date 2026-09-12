//
//  WEGT_MEM_VERIFICATION.c
//  C_HW
//
//  Created by 서정윤 on 3/13/25.
//

// WEGT_MEM_WRITE_VERIFICATION
#include <stdio.h>
#include <stdlib.h>

#define FW  3
#define FH  3
#define C   3

int main()
{
   int kernel[C][FH][FW];
   int WEGT_MEM[C * FH][FW];
   int FLATTEN_WEGT[FW * FH * C];
   int PREDICT[FW * FH * C];
   int concat[FW];
   
   srand(1); // 난수 초기화
   
   printf("Flattened Weight \n");
   for (int n = 0; n < FW * FH * C; n++)
   {
       int random = rand() % 256;
//        FLATTEN_WEGT[n] = random;
       FLATTEN_WEGT[n] = n;
       printf("index: %d, value: %d\n", n, FLATTEN_WEGT[n]);
   }
   
   printf("\nWeight MEM\n");
   for (int i = 0; i< C; i++)
   {
       for (int j = 0; j < FH; j++)
       {
           for (int k = 0; k < FW; k++)
           {
               concat[k] = FLATTEN_WEGT[k+FH*j+FW*FH*i];
           }
           for (int z = 0; z < 3; z++)
           {
               WEGT_MEM[j+C*i][z] = concat[z];
               printf("row: %d, col: %d, value: %d\n", j+C*i, z, WEGT_MEM[j+C*i][z]);
               PREDICT[z+FH*j+FW*FH*i] = WEGT_MEM[j+C*i][z];
           }
       }
       
   }
   
   int count = 0;
   for (int i=0; i < FW * FH * C; i++)
   {
       if(PREDICT[i] == FLATTEN_WEGT[i])
           count += 1;
   }
   
   if(count == FW * FH * C)
       printf("WEGT_MEM_VERIFICATION SUCCESS\n");
   else
       printf("WEGT_MEM_VERIFICATION FAILED");
   
   return 0;
}
