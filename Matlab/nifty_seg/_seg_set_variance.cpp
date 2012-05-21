
#include <mex.h>
#include "_seg_array_interface.h"

#include <limits>
#include <string.h>
#include <math.h>
#include <cmath>

/*###############################################################################################*/
/* Matlab extensions */
/*###############################################################################################*/


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   int status;

   /* Check for proper number of arguments. */
   if (!(nrhs==1))
      mexErrMsgTxt("1 input required: variance");

   /* Check for correct size and type */
   const int dim_in = mxGetNumberOfDimensions(prhs[0]); 
   if (!(dim_in==2 || dim_in==3))
      mexErrMsgTxt("Input image must be of size (N_dimensions x N_dimensions x N_classes) or (N_classes) in the mono-spectral case.");

   if (!(mxGetClassID(prhs[0]) == mxSINGLE_CLASS || mxGetClassID(prhs[0]) == mxDOUBLE_CLASS))
       mexErrMsgTxt("Input type must be single or double.");

   int size_x, size_y, size_z;
   int n_images_in = 1;
   int n_classes_in = 1;
   int n_images = 1;
   int n_classes = 1;

   if (dim_in==2)
       {
       n_images_in = 1;
       n_classes_in = mxGetDimensions(prhs[0])[1];
       }
   else
       {
       if (mxGetDimensions(prhs[0])[0] != mxGetDimensions(prhs[0])[1])
           mexErrMsgTxt("Input image must be of size (N_dimensions x N_dimensions x N_classes)");
       n_images_in = mxGetDimensions(prhs[0])[0];
       n_classes_in = mxGetDimensions(prhs[0])[2];
       }

   status = seg_array_get_image_size(&size_x,&size_y,&size_z,&n_images);
   status = seg_array_get_segmentation_size(&size_x,&size_y,&size_z,&n_classes);

   fprintf(stderr,"n_images_in: %d  n_classes_in: %d \n", n_images_in, n_classes_in);
   fprintf(stderr,"n_images: %d  n_classes: %d \n", n_images, n_classes);

   if (n_images!=n_images_in || n_classes!=n_classes_in)
       mexErrMsgTxt("N_images and N_classes must match the initialisation.");

   /* Extract input matrix */
   float *data_ptr;
   if (mxGetClassID(prhs[0]) == mxSINGLE_CLASS)
       {
       data_ptr = (float*) mxGetData(prhs[0]); 
       }
   else
       {
       double *data_ptr_d = (double*) mxGetData(prhs[0]);
       data_ptr = (float*) malloc(n_classes*n_images*n_images*sizeof(float));
       for (int i=0; i<n_classes*n_images*n_images; i++)
           data_ptr[i] = data_ptr_d[i];
       }

   /* Call NiftySeg function */
   status = seg_array_set_variance(data_ptr);

   /* Return */
   if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS)
       free(data_ptr);
   if (status != 0)
   	mexErrMsgTxt("NiftySeg: error while setting the variance.");
   return;
}

