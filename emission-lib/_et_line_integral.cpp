
#include "_et_line_integral.h"

void et_line_integral(nifti_image *inputImage, nifti_image *sinoImage, int cam)
{
    float *sino_data = (float *) (sinoImage->data) + cam*inputImage->nx*inputImage->nz ;
    float *input_data = (float *) (inputImage->data);
    for(int z=0; z<inputImage->nz; z++)
        for(int x=0; x<inputImage->nx; x++)
            sino_data[x + z*inputImage->ny] = 0.0f;
    for(int z=0; z<inputImage->nz; z++) {
        for(int y=0; y<inputImage->ny; y++) {
            for(int x=0; x<inputImage->nx; x++) {
                sino_data[x + z*inputImage->ny] = sino_data[x + z*inputImage->ny] + input_data[x + y*inputImage->nx + z*inputImage->nx*inputImage->ny];
            }
        }
    }

}


