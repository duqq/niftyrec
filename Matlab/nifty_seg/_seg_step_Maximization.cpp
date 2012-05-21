
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
   status = seg_array_step_Maximization();

   /* Return */
   if (status != 0)
   	mexErrMsgTxt("Error while performing NiftySeg Maximisation step.");
   return;
}

