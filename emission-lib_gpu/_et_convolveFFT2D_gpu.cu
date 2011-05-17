
#include "_et_convolveFFT2D_gpu_kernels.cu"
#include "_et_common.h"

////////////////////////////////////////////////////////////////////////////////
// Data configuration
////////////////////////////////////////////////////////////////////////////////
int calculateFFTsize(int dataSize){
    int hiBit;
    unsigned int lowPOT, hiPOT;

    dataSize = iAlignUp(dataSize, 16);

    for(hiBit = 31; hiBit >= 0; hiBit--)
        if(dataSize & (1U << hiBit)) break;

    lowPOT = 1U << hiBit;
    if(lowPOT == dataSize)
        return dataSize;

    hiPOT = 1U << (hiBit + 1);
    if(hiPOT <= 1024)
        return hiPOT;
    else 
        return iAlignUp(dataSize, 512);
}



////////////////////////////////////////////////////////////////////////////////
// 2D Convolution
////////////////////////////////////////////////////////////////////////////////

int et_convolveFFT2D_gpu(float **d_data, int *data_size, float **d_kernel, int *kernel_size, float **d_result)
{
    int status = 1;
    const int dataH = data_size[0];
    const int dataW = data_size[1];
    const int kernelH = kernel_size[0];
    const int kernelW = kernel_size[1];

    const int kernelX = (kernelH-1)/2;
    const int kernelY = (kernelW-1)/2;

    const int n_slices = data_size[2];
    const int data_slice_size = dataH * dataW;
    const int kernel_slice_size = kernelH * kernelW;

    float *d_PaddedData, *d_PaddedKernel, *d_Data, *d_Kernel, *d_Result;
    fComplex *d_DataSpectrum, *d_KernelSpectrum;
    cufftHandle fftPlanFwd, fftPlanInv;

    //Derive FFT size from data and kernel dimensions
    const int fftW = calculateFFTsize(dataW + kernelW - 1);
    const int fftH = calculateFFTsize(dataH + kernelH - 1);

    //Allocate memory for zero-padded image and kernel and for their transforms
    fprintf_verbose("Allocating memory...\n");
    cutilSafeCall( cudaMalloc((void **)&d_PaddedKernel, fftH * fftW * sizeof(float)) );
    cutilSafeCall( cudaMalloc((void **)&d_PaddedData,   fftH * fftW * sizeof(float)) );

    cutilSafeCall( cudaMalloc((void **)&d_KernelSpectrum, fftH * (fftW / 2 + 1) * sizeof(fComplex)) );
    cutilSafeCall( cudaMalloc((void **)&d_DataSpectrum,   fftH * (fftW / 2 + 1) * sizeof(fComplex)) );

    //Create cuFFT plan
    fprintf_verbose("Creating FFT plan for %i x %i...\n", fftH, fftW);
    cufftSafeCall( cufftPlan2d(&fftPlanFwd, fftH, fftW, CUFFT_R2C) );
    cufftSafeCall( cufftPlan2d(&fftPlanInv, fftH, fftW, CUFFT_C2R) );

    //Convolve slices one by one
    for (int slice=0; slice<n_slices; slice++)
        {
        //Determine slice pointer
        d_Data = (*d_data) + slice * data_slice_size; 
        d_Kernel = (*d_kernel) + slice * kernel_slice_size;
        d_Result = (*d_result) + slice * data_slice_size;

        //Zero pad
        fprintf_verbose("Padding convolution kernel and input data...\n");
        cutilSafeCall( cudaMemset(d_PaddedKernel, 0, fftH * fftW * sizeof(float)) );
        cutilSafeCall( cudaMemset(d_PaddedData,   0, fftH * fftW * sizeof(float)) );
        padKernel(d_PaddedKernel,d_Kernel,fftH,fftW,kernelH,kernelW,kernelY,kernelX);
cutilSafeCall( cudaThreadSynchronize() );
	if (!d_PaddedData || !d_PaddedKernel) fprintf_verbose("NULL arguments!\n");
        fprintf_verbose( "%d %d %d %d %d %d %d %d %d %d\n", d_PaddedData,d_Data,fftH,fftW,dataH,dataW,kernelH,kernelW,kernelY,kernelX);
        padDataClampToBorder(d_PaddedData,d_Data,fftH,fftW,dataH,dataW,kernelH,kernelW,kernelY,kernelX);
cutilSafeCall( cudaThreadSynchronize() );
        //Convolve
        fprintf_verbose("Transforming convolution kernel...\n");
        cufftSafeCall( cufftExecR2C(fftPlanFwd, d_PaddedKernel, (cufftComplex *)d_KernelSpectrum) );

        fprintf_verbose("Running GPU FFT convolution...\n");
        cutilSafeCall( cudaThreadSynchronize() );
        cufftSafeCall( cufftExecR2C(fftPlanFwd, d_PaddedData, (cufftComplex *)d_DataSpectrum) );
        modulateAndNormalize(d_DataSpectrum, d_KernelSpectrum, fftH, fftW);
        cufftSafeCall( cufftExecC2R(fftPlanInv, (cufftComplex *)d_DataSpectrum, d_PaddedData) );
        cutilSafeCall( cudaThreadSynchronize() );
      

        //Crop result
        fprintf_verbose("Cropping result image...\n");
        //cutilSafeCall( cudaMemset(d_Result, 11, dataH * dataW * sizeof(float)) ); //FIXME do the real thing
        crop_image(d_Result,d_PaddedData,fftH,fftW,dataH,dataW,kernelH,kernelW);
        }

    //Destroy cuFFT plan and free memory
    fprintf_verbose("Shutting down...\n");
    cufftSafeCall( cufftDestroy(fftPlanInv) );
    cufftSafeCall( cufftDestroy(fftPlanFwd) );
    cutilSafeCall( cudaFree(d_DataSpectrum)   );
    cutilSafeCall( cudaFree(d_KernelSpectrum) );
    cutilSafeCall( cudaFree(d_PaddedData)   );
    cutilSafeCall( cudaFree(d_PaddedKernel) );

    status = 0;
    return status;
}



