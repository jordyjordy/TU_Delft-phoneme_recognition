import jieba 
import sys
with open(sys.argv[2],'w',encoding='utf-8') as target:
    with open(sys.argv[1], encoding='utf-8') as file:
        for line in file:
            var = line.split()
            string = var[0]
            for x in range(1,len(var)):
                string += " " +" ".join(jieba.cut(var[x]))
            target.write(string + "\n")
