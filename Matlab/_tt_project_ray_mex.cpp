
#include <mex.h>
#include "tt_project_ray_gpu.h"

#include <limits>
#include <string.h>
#include <math.h>
#include <cmath>


/*###############################################################################################*/
/* Matlab extensions */
/*###############################################################################################*/


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   // Check for proper number of arguments. 
   if (!(nrhs==8) ){
      mexErrMsgTxt("8 arguments required: attenuation, detector_pixels, source_position, volume_size, detector_scale, detector_translation, detector_rotation, t_step");
   }

   int status = 1;
   unsigned short *attenuation;
   u_int_3 voxels; 
   u_int n_projections; 
   u_int_2 detector_pixels;
   float_2 *detector_scale; 
   float_3 volume_size;
   float_3 *detector_translation;
   float_3 *detector_rotation;  
   float_3 *source_pos; 

   //check consistency of arguments
//   if ( mxGetClassID(prhs[0]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'attenuation' must be noncomplex  double.");
   if ( mxGetClassID(prhs[0]) != mxUINT16_CLASS ) mexErrMsgTxt("'attenuation' must be noncomplex ushort.");
//   if ( mxGetClassID(prhs[1]) != mxINT32_CLASS )    mexErrMsgTxt("'detector_pixels' must be noncomplex  double.");
   if ( mxGetClassID(prhs[2]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'source_position' must be noncomplex double.");
   if ( mxGetClassID(prhs[3]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'volume_size' must be noncomplex double.");
   if ( mxGetClassID(prhs[4]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'detector_scale' must be noncomplex double.");
   if ( mxGetClassID(prhs[5]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'detector_translation' must be noncomplex double.");
   if ( mxGetClassID(prhs[6]) != mxDOUBLE_CLASS ) mexErrMsgTxt("'detector_rotation' must be noncomplex double.");

   if ( mxGetNumberOfDimensions(prhs[0]) != 3 )   mexErrMsgTxt("'attenuation' must be a 3D matrix.");  
   if ( mxGetNumberOfDimensions(prhs[1]) != 2 )   mexErrMsgTxt("'detector_pixels' must be a 2D matrix.");  
   if ( mxGetNumberOfDimensions(prhs[2]) != 2 )   mexErrMsgTxt("'source_position' must be a 2D matrix."); 
   if ( mxGetNumberOfDimensions(prhs[3]) != 2 )   mexErrMsgTxt("'volume_size' must be a 2D matrix."); 
   if ( mxGetNumberOfDimensions(prhs[4]) != 2 )   mexErrMsgTxt("'detector_scale' must be a 2D matrix."); 
   if ( mxGetNumberOfDimensions(prhs[5]) != 2 )   mexErrMsgTxt("'detector_translation' must be a 2D matrix."); 
   if ( mxGetNumberOfDimensions(prhs[6]) != 2 )   mexErrMsgTxt("'detector_rotation' must be a 2D matrix."); 

   if ( mxGetDimensions(prhs[2])[0] != mxGetDimensions(prhs[4])[0] || mxGetDimensions(prhs[4])[0] != mxGetDimensions(prhs[5])[0] || mxGetDimensions(prhs[5])[0] != mxGetDimensions(prhs[6])[0])  
       mexErrMsgTxt("size of parameters 3,5,6,7 should be the same: [N_projections,3]"); 
   if ( mxGetDimensions(prhs[2])[1] != mxGetDimensions(prhs[5])[1] || mxGetDimensions(prhs[5])[1] != mxGetDimensions(prhs[6])[1] ||  mxGetDimensions(prhs[6])[1] != 3)  
       mexErrMsgTxt("size of parameters 3,6,7 should be the same: [N_projections,3]"); 
   if ( mxGetDimensions(prhs[4])[1] != 2 ) 
       mexErrMsgTxt("size of parameter 5 should be the same: [N_projections,2]");  
   if ( mxGetDimensions(prhs[3])[1] != 3 ) 
       mexErrMsgTxt("size of parameter 4 should be the same: [1,3]");  

   //extract pointers to Matlab arrays
//   double* a_double    = (double *) mxGetData(prhs[0]);
   double* sp_double   = (double *) mxGetData(prhs[2]);
   volume_size.x = ((double *)mxGetData(prhs[3]))[0];
   volume_size.y = ((double *)mxGetData(prhs[3]))[1];
   volume_size.z = ((double *)mxGetData(prhs[3]))[2];
   double* dscale_double = (double *) mxGetData(prhs[4]);
   double* dtranslation_double = (double *) mxGetData(prhs[5]);
   double* drotation_double = (double *) mxGetData(prhs[6]);
   detector_pixels.w = ((double *) (mxGetData(prhs[1])))[0];
   detector_pixels.h = ((double *) (mxGetData(prhs[1])))[1];
   voxels.x = mxGetDimensions(prhs[0])[0];
   voxels.y = mxGetDimensions(prhs[0])[1];
   voxels.z = mxGetDimensions(prhs[0])[2];
   n_projections = mxGetDimensions(prhs[2])[0];

   float t_step = (mxGetScalar(prhs[7])); 

   //convert to CUDA compatible types
//   attenuation = (unsigned short*) malloc(voxels.x*voxels.y*voxels.z*sizeof(unsigned short));
//   for(int i=0; i<voxels.x*voxels.y*voxels.z; i++)
//       attenuation[i] = a_double[i];
   attenuation = (unsigned short *) mxGetData(prhs[0]);

   source_pos           = (float_3 *) malloc(n_projections*sizeof(float_3));
   detector_scale       = (float_2 *) malloc(n_projections*sizeof(float_2));
   detector_translation = (float_3 *) malloc(n_projections*sizeof(float_3));
   detector_rotation    = (float_3 *) malloc(n_projections*sizeof(float_3));
   for(int i=0;i<n_projections;i++)
   {
       source_pos[i].x     = sp_double[i];   source_pos[i].y     = sp_double[i+n_projections];   source_pos[i].z     = sp_double[i+2*n_projections];
       detector_scale[i].x = dscale_double[i]; detector_scale[i].y = dscale_double[i+n_projections]; 
       detector_translation[i].x = dtranslation_double[i]; detector_translation[i].y = dtranslation_double[i+n_projections]; detector_translation[i].z = dtranslation_double[i+2*n_projections];
       detector_rotation[i].x = drotation_double[i]; detector_rotation[i].y = drotation_double[i+n_projections]; detector_rotation[i].z = drotation_double[i+2*n_projections];
   }

   //allocate memory for projections
//   float *out_projections_float = (float*) malloc(n_projections*detector_pixels.w*detector_pixels.h*sizeof(float));
   mwSize mw_out_size[3];
   mw_out_size[0] = (mwSize)detector_pixels.w;
   mw_out_size[1] = (mwSize)detector_pixels.h;
   mw_out_size[2] = (mwSize)n_projections;
//   plhs[0] =  mxCreateNumericArray(3, mw_out_size, mxDOUBLE_CLASS, mxREAL);
//   double *out_double = (double *)(mxGetData(plhs[0]));   
   plhs[0] =  mxCreateNumericArray(3, mw_out_size, mxSINGLE_CLASS, mxREAL);
   float *out_single = (float *)(mxGetData(plhs[0]));   

   // Project 
//   status = tt_project_ray_array(attenuation, voxels, out_projections_float, n_projections, detector_scale, detector_translation, detector_rotation, detector_pixels, source_pos, volume_size, t_step);
   status = tt_project_ray_array(attenuation, voxels, out_single, n_projections, detector_scale, detector_translation, detector_rotation, detector_pixels, source_pos, volume_size, t_step);


   // Convert to double 
//   for (int i=0; i<n_projections*detector_pixels.w*detector_pixels.h; i++)
//       out_double[i] = out_projections_float[i];

   // Shutdown 
//   free(attenuation);
   free(source_pos);
   free(detector_scale);
   free(detector_translation);
   free(detector_rotation);
//   free(out_projections_float);

   // Return 
   if (status != 0)
   	mexErrMsgTxt("Error while performing Affine Transform.");
   return;
}

