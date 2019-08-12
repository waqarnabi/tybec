chdir "lib" or die;
#system "rm *.aoco *.aoclib";
system "aocl library hdl-comp-pkg hdl_lib.xml -o hdl_lib.aoco";
system "aocl library create -name hdl_lib -vendor dmitry -version 15.1 hdl_lib.aoco";
system "cp hdl_lib.aoclib ..";
chdir ".." or die;


