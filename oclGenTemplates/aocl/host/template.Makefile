AOCL_COMPILE_CONFIG=$(shell aocl compile-config)
AOCL_LINK_CONFIG=$(shell aocl link-config)

host : src/ACLHostUtils.cpp  src/ACLThreadUtils.cpp  src/main.cpp  src/timer.cpp 
	/usr/bin/g++ -o host src/ACLHostUtils.cpp  src/ACLThreadUtils.cpp  src/main.cpp  src/timer.cpp $(AOCL_COMPILE_CONFIG) $(AOCL_LINK_CONFIG) -Iinc -DLINUX -pthread

