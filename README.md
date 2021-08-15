# c2puml
tranpile c source code to plant uml flow chart.

Cのソースコードからフローチャートを直接出力可能なソフトを目指します。
具体的には PlantUML 用のActivity図の .puml ファイルを出力します。

（Cのソースとしては破綻してますが）一応下記のようなCっぽいソースコードからフローチャートを作れます。

```
int main(int argc char **argv) {
	/* abc if(123) defg */
	if((Xbc)+(123)){
		printf("avcd");
	}
	if((Xbc)+(123)){
		printf("ddddd");
	} else {
		printf("hgij");
	}

	for(x=0;x<100;x++)
		printf("bcdf");

	for(int x=0;x<100;x++) {
		for(int y=0;y<100;y++) {
			if(x<30)	proc(x, y);
		}
	}
}
```

![image](https://user-images.githubusercontent.com/2684586/129483571-11e08ac7-0855-44d0-ae05-a618329e55be.png)
