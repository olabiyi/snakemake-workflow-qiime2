import os
import re
import zipfile
import argparse

#argparse
parser = argparse.ArgumentParser()

parser.add_argument("--input","-i",help="visualized collapsed taxa (qzv)")
parser.add_argument("--output","-o",help="name of krona output (better have .html)")
parser.add_argument("--exclude","-e",help="exclude sample list (add samples seperated by comma(,))")
parser.add_argument("--regex","-r",help="allow regex applied or not (default: True)")

args=parser.parse_args()

if args.input:
    input=args.input

if args.output:
    output=args.output

if args.exclude:
    excludelist=args.exclude.split(",")

if args.regex:
    regex=args.regex
else:
    regex=True

#extract metadata.tsv from collapsed taxa
def unzip(qzv_file):
    with zipfile.ZipFile(qzv_file) as zip:
        for zip_info in zip.infolist():
            if "data/metadata.tsv" in zip_info.filename:
                zip_info.filename=os.path.basename(zip_info.filename)
                zip.extract(zip_info)

#create tsv files which Krona likes
def make_tsv(name):
    tsv=open("krona-tsv/"+name+".tsv","w+")
    tsv.write(name)
    for i in range(0,len(new)):
        tsv.write("\n"+data_dict[name][i]+"\t"+new[i])
    tsv.close()

unzip(input)

#this folder will be deleted in the end of the process
if not os.path.exists("krona-tsv"):
    os.makedirs("krona-tsv")

file=open("metadata.tsv","r")

lines=file.readlines()

file.close()

#remove the file since we don't need it anymore
os.system("rm "+"metadata.tsv")

new=[]
sample_names=[]
data_dict={}

taxa=lines[0].split("\t")
taxa=taxa[1:]

lines.pop(0)
lines.pop(0)

for line in lines:
    line=line.strip().split("\t")
    data=[]
    if line[0] in excludelist:
        continue
    else:
        sample_names.append(line[0])
    for value in line:
        if any(i.isalpha() for i in value)==True:
            pass
        else:
            data.append(value)
    data_dict[line[0]]=data
    print(data_dict)

#Regex for SILVA and greengenes. I don't like to see the prefix they add.
for x in taxa:
    if regex==True:
        x=re.sub("D_\d__","",x)
        x=re.sub("\w__","",x)
    new.append(x.replace(";","\t"))

for sample in sample_names:
    make_tsv(sample)

#This part runs Krona and removes tsv files we created.
os.system("ktImportText krona-tsv/* -o "+output)
os.system("rm -r krona-tsv")
