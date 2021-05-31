import os
import re
import zipfile

#extract level-7.csv from taxa barplots
def unzip(qzv_file):
    with zipfile.ZipFile(qzv_file) as zip:
        for zip_info in zip.infolist():
            if "level-7.csv" in zip_info.filename:
                zip_info.filename=os.path.basename(zip_info.filename)
                zip.extract(zip_info)

#create tsv files which Krona likes
def make_tsv(name):
    tsv=open("krona-tsv/"+name+".tsv","w+")
    tsv.write(name+"\n")
    for i in range(0,len(new)):
        tsv.write(data_dict[name][i]+"\t"+new[i]+"\n")
    tsv.close()

#this is my base output. you can change it to anything you wish.
unzip("taxa-bar-plots.qzv")

#this folder will be deleted in the end of the process
if not os.path.exists("krona-tsv"):
    os.makedirs("krona-tsv")

#this folder will have the last output
if not os.path.exists("Krona"):
    os.makedirs("Krona")

file=open("level-7.csv","r")

lines=file.readlines()

file.close()

#remove the file since we don't need it anymore
os.system("rm "+"level-7.csv")

taxa=[]
new=[]
sample_names=[]
data_dict={}
for line in lines:
    line=line.strip().split(",")
    if line[0]=="index":
        for i in line:
            if ";" in i:
                taxa.append(i)
            elif i.startswith("Unassigned"):
                taxa.append("Unassigned")

    else:
        data=[]
        sample_names.append(line[0])
        for value in line:
            if any(i.isalpha() for i in value)==True:
                pass
            else:
                value=value.split(".")
                data.append(value[0])
        data_dict[line[0]]=data

#Regex for SILVA and greengenes. I don't like to see the prefix they add.
#There is no harm with other databases. If you want to leave them be, just remove first two lines after "for" loop.
for x in taxa:
    x=re.sub("D_\d__","",x)
    x=re.sub("\w__","",x)
    new.append(x.replace(";","\t"))

for sample in sample_names:
    make_tsv(sample)

#This part runs Krona and removes tsv files we created.
#You can change the output as you wish.
os.system("ktImportText krona-tsv/* -o Krona/krona.html")
os.system("rm -r krona-tsv")
