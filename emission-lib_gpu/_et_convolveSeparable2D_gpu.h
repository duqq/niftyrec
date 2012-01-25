
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cufft.h>
#include <cutil_inline.h>
#include "nifti1_io.h"

#define MAX_SEPARABLE_KERNEL_RADIUS 32

extern "C" void convolutionRowsGPU(float *d_Dst,float *d_Src,int imageW,int imageH,int kernelRadius);
extern "C" void convolutionColumnsGPU(float *d_Dst,float *d_Src,int imageW,int imageH,int kernelRadius);

int et_convolveSeparable2D_gpu(float **d_data, int *data_size, float **d_kernel, int *kernel_size, float **d_result);


