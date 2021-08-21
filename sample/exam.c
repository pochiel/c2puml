#include <stdio.h>

#define C_OUTPUT_FILE_MAX    (256)
int main(int argc, char *argv[])
{
    FILE * fptr_r = NULL;
    FILE * fptr_w = NULL;
    int i;
    char opt;
    char output_filne_name[C_OUTPUT_FILE_MAX] = {0};
    char input_filne_name[C_OUTPUT_FILE_MAX] = {0};

    /* default name. */
    strncpy(output_filne_name, "out.puml", C_OUTPUT_FILE_MAX);

    for(i = 0; i < argc; ++i){
        if(*argv[i] == '-'){
            opt = *(argv[i]+1);
            switch(opt){
                case 'o':
                    strncpy(output_filne_name, argv[i+1], C_OUTPUT_FILE_MAX);
                    break;
                default:
                    printf("Undefined Option.\n");
                    break;
            }
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

    /* \•¶‰ðÍŠÖ” yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
