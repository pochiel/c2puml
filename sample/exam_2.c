#include <stdio.h>

#define C_OUTPUT_FILE_MAX    (256)
int main(int argc, char *argv[])
{
    for(i = 0; i < argc; ++i){
        if(*argv[i] == '-'){
            i++;
        } else {
            sprintf(input_filne_name, "./%s", argv[i]);
        }
    }
    /* Read file pointer */
    if ((fptr_r = fopen(input_filne_name, "r"))==NULL) {
        printf("file open failed.\n");
        exit(1);
    }
    
    /* write file pointer */
    if ((fptr_w = fopen(output_filne_name, "w"))==NULL) {
        printf("output file open failed.\n");
        exit(1);
    }
	return 0;
}
