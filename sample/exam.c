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

    for(i = 1; i < argc; ++i){
        if(*argv[i] == '-'){
            opt = *(argv[i]+1);
            switch(opt){
                case 'o':
                    strncpy(output_filne_name, argv[i+1], C_OUTPUT_FILE_MAX);
                    break;
                case 'a':
                case 'b':
                    strncpy(a+b);
                    break;
                case 'c':
                case 'd':
                case 'e':
                default:
                    printf("Undefined Option.\n");
                    break;
            }
            i++;
        } else {
            sprintf(input_filne_name, "%s", argv[i]);
        }
    }

    /* test while */
    i = 0;
    while(i<456) {
        i++;
        if(i%10 == 0) while_test_10(i);
        if(i%20 == 0) while_test_20(i);
        if(i%50 == 0)
            while_test_50(i);
        else
            while_test_else(i);
    }

    /* test do~while */
    i = 0;
    do {
        i+=2;
        do_while_test(i);
    } while(i<123);

    /* input filename error check */
    if(strlen(input_filne_name) == 0) {
        printf("input filename error.\n");
        exit(1);
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

    /* yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
