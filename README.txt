#Environment Variables:
#----------------------

#root directory for TyBEC
export TyBECROOTDIR=<this-directory>


#Perl libraries used, internal and external we provide all external libraries with the package 
#for code portability
export PERL5LIB="$TyBECROOTDIR/lib-intern:$TyBECROOTDIR/lib-extern"
