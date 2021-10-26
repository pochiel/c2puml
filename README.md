# c2puml

## これは何？
transpile c source code to plant uml flow chart.

Cのソースコードからフローチャートを直接出力可能なソフトを目指します。

具体的には PlantUML 用のActivity図の .puml ファイルを出力します。

（Cのソースとしては破綻してますが）一応下記のようなCっぽいソースコードからフローチャートを作れます。

github を眺めて、そんなに長くないCのコードをいくつか変換してみましたが、そこそこいい感じに動くようになってきたっぽいです。

やりたかったことが割とできるようになってきたので、更新ペースが落ちるかもです。

何か問題があったら issue に報告ください。

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

![image](https://user-images.githubusercontent.com/2684586/138925914-e464ebc3-c696-43ee-9c44-f8f97639f66c.png)


## 使い方
1.bison/flex をインストールします。（Windows環境なら、WSL Ubuntu上に apt-get install するのが吉）

2.plantumlをインストールします。（java/graphviz も一緒に必要です。場合によっては plantuml web server を利用するのも吉）

http://www.plantuml.com/

3.本リポジトリを clone し、make。

4.下記コマンドで puml ファイルに変換します。

./c2puml -o [出力ファイル名] [入力ファイル名]

（ -o を指定しなければ、出力ファイルのデフォルト名は out.puml になります。）

5.出力ファイルの plantumlコードをレンダリングします。

