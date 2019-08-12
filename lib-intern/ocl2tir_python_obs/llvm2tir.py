# coding: utf-8

# In[11]:

# Waqar Nabi, Glasgow, 2019.02.11
# This is based on MSc student group project, fall 2018

import sys



################################################################################################## 
#the parse_file function is mainly used to 
#1.generate the first line and main body of kernel input, kernel compute(s) and kernel output
#2.generate the words_for_top lines used to parse the kernl top,as the input information of TOP function
##################################################################################################
import sys

def parse_file(filepath,filepath2):
    lines_out=[]
    lines_for_top=[] 
    file_write_obj = open(filepath2, 'w')
    my_function_name=[]
    
    with open(filepath,'r') as file_object:
        
        line_in_1 = file_object.readline()       
        while line_in_1:            
            words=line_in_1.replace('#0','pipe ').replace('*',' ').split()
            if not words:
                pass#print ("line is BLANK")
           
            elif (words[0]=="define" and words[1]=="void") :
                if (words[2].find("pipe")==-1):
                    my_function_name.append(words[2])#split the name
            line_in_1 = file_object.readline()
            
    with open(filepath,'r') as file_object_1:
        line_in_2 = file_object_1.readline()
        
        while line_in_2:
            Dictionary={}
            Dictrunk={}
            str_out = ""
            str_out_for_top = ""

            ADDlist=[]
            name=''
##################################################################################################
#Parse the first line of each kernel:kernel input, kernel compute and kernel output
##################################################################################################
            words=line_in_2.replace('#0','pipe ').replace('*',' ').replace(',',' ').split()
            line_in_2=line_in_2.replace('#0','pipe ').replace('*',' ')
            words_for_top=line_in_2.replace('#0','pipe ').split()
            if not words:
                pass#print ("inside parse_file, line is BLANK")    
            elif (len(words)>=3 and words[2] in my_function_name ):
                file_write_obj.writelines(line_in_2)
##################################################################################################
#parse the main body part of each kernel:kernel input, kernel compute and kernel output
##################################################################################################
                while  line_in_2 :
                    words=line_in_2.replace('#0','pipe ').replace('*',' ').replace(',',' ').split()
#---------------------------------------------------------------------------------------#
#establish a dictionary for each kernel
#---------------------------------------------------------------------------------------#
                    if(len(words)>6):
                        if(words[2]=='alloca' or words[0]=='define'):
                            pass#print("ignore these lines",words)
                        elif(words[2].find('trunc')>-1):
                            Dictrunk[words[0]]=words[4]
                        elif(words[2].find('write')>-1):
                            words=line_in_2.replace(',',' ').replace(')',' ').split()
                            Dictionary[words[4]]=words[6]
                        elif(words[2].find('read')>-1):
                            words=line_in_2.replace(',',' ').replace(')',' ').split()
                            Dictionary[words[6]]=words[4]
                        #original
                        elif(words[2].find('load')>-1):
                            Dictionary[words[0]]=words[5]
                        elif(words[0].find('store')>-1):
                            words=line_in_2.replace(',',' ').split()
                            Dictionary[words[4]]=words[2]    
                        else:
                            ADDlist.append(line_in_2)
                            name=words[2]                    
                    elif(words[0]=="ret"):
                        break
 
                    line_in_2 = file_object_1.readline()  
                    
                #WN
                print("")
                for keys,values in Dictionary.items():
                    print(keys, " --> ", values)
                print("&")
                for keys,values in Dictrunk.items():
                    print(keys, " --> ", values)
#---------------------------------------------------------------------------------------#
#eliminating the correspondence of each dictionary 
#---------------------------------------------------------------------------------------#
            for key in Dictrunk:
                if key in Dictionary:
                    Dictionary[Dictrunk[key]]=Dictionary.pop(key)
                else:
                    continue            
            for key in Dictrunk:
                for k in Dictionary:
                    if (key == Dictionary[k]):
                        Dictionary[k]=Dictrunk[key]
                    else:
                        continue

#---------------------------------------------------------------------------------------#
#parsing the main body part for kernel input and kernel output
#---------------------------------------------------------------------------------------#
                        
            if len(ADDlist)==0:
                k=''
                dic={}
                for key in Dictionary:                 
                    for K in Dictionary:
                        if (key==Dictionary[K]):
                            k=K
                            if Dictionary[K] in dic:
                                dic[K]=dic.pop(Dictionary[K])
                            Dictionary[K]=Dictionary[key] 
                            dic[K]=Dictionary[K]
                for k in dic:
                    str_out=' i32 '+ k+ ' = '+ 'load ' +'i32 '     
                    str_out+=dic[k]+' '
                    str_out+='\n' 
                    file_write_obj.writelines(str_out)
                    str_out=""
                    str_out+=" ret void"             
                    str_out+='\n'
                    str_out+="}"
                    str_out+='\n'
                file_write_obj.writelines(str_out)
#---------------------------------------------------------------------------------------#
#parsing the main body part for kernel compute
#---------------------------------------------------------------------------------------#                           

            else:
                for Sentence in ADDlist:
                    Chunk=Sentence.replace(',',' ').split()                   
                    variable=[]               
                    for i in range(5,len(Chunk)):
                        if (Chunk[i] not in variable):
                            variable.append(Chunk[i])
                    if(Chunk[0] not in Dictionary.values() ):
                        str_out='i32 '+Chunk[0]
                    else:
                        while (k in Dictionary.values()):
                            
                            k=list (Dictionary.keys()) [list (Dictionary.values()).index (k)]
                        str_out='i32 '+ k      
                    str_out+=' '+'='+ name+' i32 '
                    for v in variable:
                        while (v in Dictionary.keys()):
                            v=Dictionary[v]
                        str_out+=v+', '
                    str_out+='\n'
                    file_write_obj.writelines(str_out)
                str_out=" ret void"             
                str_out+='\n'
                str_out+="}"
                str_out+='\n'
                file_write_obj.writelines(str_out)
                                
                            
################################################################################################## 
   
#generate the words_for_top lines used to parse the kernl top,as the input information of TOP function
##################################################################################################
                
            if not words_for_top:
                pass#print ("inside parse_file, line is BLANK")
            
            elif (words_for_top[0]=="define" and words_for_top[1]=="void") :
                   
                my_function_name_for = words_for_top[2]#split the name 
                if (words_for_top[2].find("@read_pipe") and words_for_top[2].find("@write_pipe")): 
                    for chunk in words_for_top:
                        if (chunk!="noalias"and chunk!="nocapture"):
                            str_out_for_top+= chunk+' '
                    lines_for_top.append(str_out_for_top)
                    
            elif(words_for_top[0]=="ret" and words_for_top[1]=="void"):                   
                for chunk in words_for_top:
                    str_out_for_top+=chunk+' '
                str_out_for_top+="}"
                str_out_for_top+='\n'
                lines_for_top.append(str_out_for_top)
      
            line_in_2 = file_object_1.readline()  
          

        file_write_obj.writelines(lines_out)
        file_write_obj.write('\n')       
        file_write_obj.close()

                     

    return lines_for_top

################################################################################################## 
    #the main function of Top function is :
    #1. take the result of parse_file function: words_for_top
    #1.generate the first line and main body of kernel top
##################################################################################################

def genTop(data,filepath2):
    lines_out=[]
    Out_file=[]
    dic_top={}
    list_variable=[]
    file_write_obj = open(filepath2, 'a')  
    file_write_obj.write(';---------------\n')
    file_write_obj.write(';-- KernelTop\n')
    file_write_obj.write(';---------------\n')    
##################################################################################################
#parse the first line of kernel top: by establishing a dictionary and counting the no. of keys
##################################################################################################
    for line_in in data:
        words1=line_in.replace(',',' ').replace(')',' ').replace('(',' ').split()
        for i in range(len(words1)-1):
            if (words1[i]=='i32' and words1[i+1] not in dic_top):          
                dic_top[words1[i+1]]=0
        if (words1[0]=="define"):
            for w in words1:
                if (w in dic_top):
                    dic_top[w]=dic_top[w]+1
    file_write_obj.write('define void @kernelTop (')
    for key in dic_top:
        if (dic_top[key]==1):
            file_write_obj.writelines("i32 "+ key+", ")    
    file_write_obj.write(' )'+"pipe "+"{")  
    file_write_obj.write('\n') 

##################################################################################################
#parse the mian body of kernel top
##################################################################################################
    for line_in in data:    
        list=[]
        str_out=""
           
        words=line_in.split()
        for words in words:            
            if (words!="}"and words!="{" and words!="ret" and words!="void" and words!="pipe" and words!="define"):
                str_out+=words 
        if (str_out!='\n'and str_out!="" ):

            list="call "+str_out
            file_write_obj.writelines(list)
            file_write_obj.write('\n') 
    
    file_write_obj.write("ret void")
    file_write_obj.write('\n')
    file_write_obj.write("}")
    file_write_obj.close()

    return dic_top

            
################################################################################################## 
#WN ADDED, Feb 2019
#   + create the main function in TIRL
#################################################################################################

def genMain(dic_top,filepath2):
    lines_out=[]
    Out_file=[]
    list_variable=[]
    file_write_obj = open(filepath2, 'a')  
    
    #initialize strings to be written to file
    str_init   = "\n\n"
    str_alloca = "\n"
    str_stream = "\n"
    str_callkt = "\n  call @kernelTop (\n"

    #all streams for now have same metadata
    str_streamMetaData = " "*22 + ", !tir.stream.type   !stream1d\n" \
                       + " "*22 + ", !tir.stream.size   !NLinear\n"  \
                       + " "*22 + ", !tir.stream.saddr  !0\n"        \
                       + " "*22 + ", !tir.stream.stride !1\n"



    str_init += ";---------------\n"
    str_init += ";-- Main\n"
    str_init += ";---------------\n"
    #This is a hack; at least use __attribute__ like I do in my c2llvm2tir
    str_init += "#define NLinear 1024\n"

    str_init += "define void @main (){\n"

    #loop through memory streams and gen code
    for key in dic_top:
        if dic_top[key] == 1:
            #alloca instruction is same for input or output
            str_alloca+= "  "+key+" = alloca [NLinear x i32], addrspace(1)\n"
            
            #if output
            #NOTE:this is currently an (ugly) hack to identify output
            #memory streams, i.e.
            #the last 3 characters of their identifier MUST be "out" (case insensitive)
            if key[-3:].lower() == "out":
                str_stream  += "  streamwrite i32 "+key+"_stream_store, i32* "+key+"\n" \
                            + str_streamMetaData
                str_callkt  += "    i32 "+key+"_stream_store,\n"
            #input
            else:
                str_stream  += "  "+key+"_stream_load = streamread i32, i32* "+ key+"\n" \
                            + str_streamMetaData
                str_callkt  += "    i32 "+key+"_stream_load,\n"

    #close call to kernelTop
    str_callkt += "  )\n"

    #write strings to file
    file_write_obj.write(str_init) 
    file_write_obj.write(str_alloca) 
    file_write_obj.write(str_stream) 
    file_write_obj.write(str_callkt) 
    file_write_obj.write("  ret void\n}") 
    file_write_obj.close()
    
################################################################################################## 
#take llvm file as input
# call all the paring functions
# outout the tirl format file.
##################################################################################################

if __name__ == '__main__':
    #filepath = 'kernels_channels.ll'
    #filepath2='kernels_channels.txt'
    filepath=sys.argv[1]
    filepath2=sys.argv[2] + ".tir"
    data = parse_file(filepath,filepath2)

    #genTop() creates a top level dictiornary that will be reused for genMain
    dic_top = genTop(data,filepath2)
    genMain(dic_top,filepath2)
    