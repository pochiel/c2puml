# c2puml
tranpile c source code to plant uml flow chart.

Cのソースコードからフローチャートを直接出力可能なソフトを目指します。
具体的には PlantUML 用のActivity図の .puml ファイルを出力します。

（Cのソースとしては破綻してますが）一応下記のようなCっぽいソースコードからフローチャートを作れます。

```
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

    /* 構文解析関数 yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
```

![image](https://user-images.githubusercontent.com/2684586/130328564-9f1da44e-1b22-4f67-9b05-f8ae23f19a82.png)
