# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2015.01.13
# Project Name : TyTra
#
# Dependencies : 
#
# Revision     : 
# Revision 0.01. File Created
# 
# Conventions  : 
# =============================================================================
#
# =============================================================================
# General Description and Notes:
#  Limitations and Constraints:
#  ===========================
#  See TybeTirlParser.pl
# =============================================================================                        

package TirGrammarMod;
use strict;
use warnings;

use Cost;             #read costs from Cost.pm

use Exporter qw( import );
our @EXPORT = qw( $grammar );

use List::Util 'max';
use File::Slurp;
use Tree::DAG_Node;     #for generating call trees
use Term::ANSIColor qw(:constants);

my $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};

# ============================================================================
# Utility routines
# ============================================================================

# --------------------------------------------------------------------------
# MAX and MIN
# --------------------------------------------------------------------------
sub mymax ($$) { $_[$_[0] < $_[1]] }
sub mymin ($$) { $_[$_[0] > $_[1]] }


# --------------------------------------------------------------------------
# BUILD GRAPH HELPERs(Add nodes and edges, both to abstract DFG and DOT graph)
# --------------------------------------------------------------------------
sub addGraphNode {
  my $narg  = @_;
  my $func  = shift(@_);
  my $symbol= shift(@_); #for accessing hash)
  my $node  = shift(@_); #for setting node identifier)
  my $name  = shift(@_); #name property)
  my $shape = shift(@_); #if($narg>3);
  my $color = shift(@_); #if($narg>3);

  #perf
  my $lat = '';
  my $afi = '';  
  my $lfi = '';  
  my $efi = '';  
  my $fpo = '';
  my $sd  = '';     

  #cost
  my $dsps      = '';    
  my $propDelay = '';
  my $regs      = '';
  my $aluts     = '';
  
#Since I do not have cost of all symbols calc yet, so I need to check if it exists first before setting
  if (exists $main::CODE{$func}{symbols}{$symbol}{performance}) {
    $lat = $main::CODE{$func}{symbols}{$symbol}{performance}{lat};
    $afi = $main::CODE{$func}{symbols}{$symbol}{performance}{afi};
    $lfi = $main::CODE{$func}{symbols}{$symbol}{performance}{lfi};
    $efi = $main::CODE{$func}{symbols}{$symbol}{performance}{efi};
    $fpo = $main::CODE{$func}{symbols}{$symbol}{performance}{fpo};
    $sd  = $main::CODE{$func}{symbols}{$symbol}{performance}{sd };
  }
  
  if (exists $main::CODE{$func}{symbols}{$symbol}{resource}) {
    $dsps      = $main::CODE{$func}{symbols}{$symbol}{resource}{dsps}     ;
    $propDelay = $main::CODE{$func}{symbols}{$symbol}{resource}{propDelay}; 
    $regs      = $main::CODE{$func}{symbols}{$symbol}{resource}{regs}     ;
    $aluts     = $main::CODE{$func}{symbols}{$symbol}{resource}{aluts}    ;
  }
 
  #$node =~ s/(%|@)//; #remove %/@

  #$main::dfGraph->add_vertex($node);
  #print RED; print "::addGraphNode:: adding graph node $node in $func \n"; print RESET;
  $main::dfGraph    ->set_vertex_attribute ($node, name       => $name);
  $main::dfGraph    ->set_vertex_attribute ($node, parentFunc => $func);
  $main::dfGraph    ->set_vertex_attribute ($node, symbol     => $symbol);
  
  #perf
  #$main::dfGraph    ->set_vertex_attribute ($node, lat  => $lat );
  #$main::dfGraph    ->set_vertex_attribute ($node, afi  => $afi );
  #$main::dfGraph    ->set_vertex_attribute ($node, lfi  => $lfi );
  #$main::dfGraph    ->set_vertex_attribute ($node, efi  => $efi );
  #$main::dfGraph    ->set_vertex_attribute ($node, fpo  => $fpo );
  #$main::dfGraph    ->set_vertex_attribute ($node, sd   => $sd  );
  #
  ##cost
  #$main::dfGraph    ->set_vertex_attribute ($node, dsps      => $dsps      );
  #$main::dfGraph    ->set_vertex_attribute ($node, propDelay => $propDelay );
  #$main::dfGraph    ->set_vertex_attribute ($node, regs      => $regs      );
  #$main::dfGraph    ->set_vertex_attribute ($node, aluts     => $aluts     );
  #        
  my $xlabel;
  if ($main::VERBOSE_DFG_ANNOT == 1){$xlabel = "($lat, $afi, $lfi, $efi, $fpo, $sd)";}
  else                              {$xlabel = "($lat, $lfi)";}
  
    
  $main::dfGraphDot ->add_node ( $node
#                               , label   => $label
                               , xlabel  => $xlabel
                               , shape   => $shape
                               , cluster => $func
                               , color   => $color
                               #, lat     => $lat
                               #, afi     => $afi
                               #, lfi     => $lfi
                               #, efi     => $efi
                               #, fpo     => $fpo
                               #, sd      => $sd
                               );
}

sub addGraphEdge {
my  ($pnode          
    ,$cnode          
    ,$label          
    ,$connection
    ,$pnode_cat     
    ,$pnode_local
    ,$pnode_pos
    ,$cnode_cat     
    ,$cnode_local
    ,$cnode_pos   
    ,$color      
    ,$pass        
    ,$edgeDataType)  = @_;
  
  #remove %/@
  $label =~ s/(%|@)//g; 
  $pnode_local =~ s/(%|@)//g; 
  $cnode_local =~ s/(%|@)//g; 
  
  #add prefix to connection name 
  #$connection = "conn_".$connection;
  #$connection  =~ s/(%|@)//g; 

#first pass, build abstract DFG only
#the local scheduler will make updates to it before the second pass
#if($pass == 1) {  
  my $id = $main::dfGraph ->add_edge_get_id ( $pnode, $cnode);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'latency'      ,1);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'connection'   ,$connection);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'pnode_pos'    ,$pnode_pos);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'cnode_pos'    ,$cnode_pos);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'pnode_local'  ,$pnode_local);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'cnode_local'  ,$cnode_local);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'pnode_cat'    ,$pnode_cat);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'cnode_cat'    ,$cnode_cat);
  $main::dfGraph ->set_edge_attribute_by_id ( $pnode, $cnode, $id, 'edgeDataType' ,$edgeDataType);
#}
  #print GREEN; print "::addGraphEdge:: adding $pnode --> $cnode edge, with pnode_local = $pnode_local, cnode_local = $cnode_local \n"; print RESET;
  
#second pass: this time create the DOT for updated DFG  
if($pass == 2) {  
  #IF the producer node is a buffer, then get the offset value in the buffer for this consumer, and add it to this
  #edge's property as well as label)
  my $offset;
  my $offset_label = '';
  if($pnode_cat eq 'fifobuffer') {
#    (my $offset = $connection) =~ m/(_\d+)$/;
    if ($connection =~ /(_)(\d+)$/){
      $offset = $2;
      $offset_label = "::off_".$offset;
      #print YELLOW; print "Found a buffer PNODE with connection = $connection, offset = $offset\n"; print RESET;
    }
    else {die "TyBEC: Error. Unable to offset from $pnode buffer for $cnode\n"};
  }
  
  
  
  $main::dfGraphDot ->add_edge ($pnode => $cnode
                               , label => $label.$offset_label."::".$edgeDataType
                               , color => $color
                               , offset=> $offset
                               );
}
                               
}

# --------------------------------------------------------------------------
# Set argument direction if parsing an instruction gives info (convenience func)
# --------------------------------------------------------------------------
#iterate through all arguments of the caller function, and check
#if it should be set to output or input based on if it matches a LHS operand
#and set their direction
  
sub setArgDir {
  my $narg = @_;
  my $func = shift(@_);
  my $myoperD = shift(@_);
  my $myoper1 = shift(@_);
  my $myoper2 = shift(@_);
  my $myoper3 = 'null';
 $myoper3     = shift(@_)  if ($narg>4);
  
  #looks like I need to have the separate ARG hash (in addition to its entry in SYMBOLS) for now
  #in order to be able to list them position-wise(i.e. key is numbers, not name)
   foreach my $key ( keys %{$main::CODE{$func}{args}} )
   {
     my $argName = $main::CODE{$func}{args}{$key}{name};
     # first check tp confirm if the argument has not already been set by a previous
     # parse over another instruction. 
     if ($main::CODE{$func}{args}{$key}{dir} eq 'null') 
     {
       # if argument matches destination operand of this instruction
       # then set direction, and also update the node type to indicate this
       # is a "functional argument"
       if ($argName eq $myoperD)  { 
        $main::CODE{$func}{args}{$key}{dir}         = 'output';
        $main::CODE{$func}{symbols}{$argName}{dir}  = 'output';
        $main::CODE{$func}{symbols}{$myoperD}{cat}  = "func-arg";
       }
       # if argument matches a source operand of this instruction
       elsif (   ($argName eq $myoper1) 
             ||  ($argName eq $myoper2) 
             ||  ($argName eq $myoper3) ) { 
           $main::CODE{$func}{args}{$key}{dir}    = 'input';
           $main::CODE{$func}{symbols}{$argName}{dir} = 'input';
           #also update "produces" entry in the symbol table, as that would be empty,
           #and this is an input argument
           @{$main::CODE {$func}{symbols}{$argName}{produces}}= ($argName);
         }
       else { 
        $main::CODE{$func}{args}{$key}{dir} = 'null';
        $main::CODE{$func}{symbols}{$argName}{dir} = 'null';
       }
     }#if
   }#foreach
}#sub

# --------------------------------------------------------------------------
# Create DFG for a given function (called for both main and non-main functions
# --------------------------------------------------------------------------

sub createDFG {
  my $narg = @_;
  my $func = shift(@_);
  my $pass = shift(@_);
  
  my $hash = $main::CODE{$func}; 
  
  my $shape; 
  my $color; 
  my $node; 
  
#  #attributes for the node to allow synchronization
#  my $lat=1; 
#    #how long does it take for an input to propagate to the output. 
#  my $lfi=1;
#    #firing interval as defined by internal constraints of this node
#  my $efi=1;
#    #firing interval as defined by external constraints (i.e. predecessors) of this node
#  my $afi=1;  
#    # ACTUAL firing (initiation) interval; max (lfi, efi)
#    #i.e. how many cycles pass between subsequent "firing" of this node
#    #note that this firing ONLY determines how often input streams are sampled
#    #the frequency of output streams are determined by the next atrribute
#  my $fpo=1;
#    #how many times does the node fire to emit one output (most cases would be 1)
#  my $sd=0;
#    #when do I start operating on the context of this SD (syncrhonouse domain)
 
#add nodes only on the first pass
#any additional buffer nodes are added by localScheduler, so no need to run it again 
if($pass eq 1) { 
  #create nodes, if NOT a stream
  foreach my $key ( keys %{$hash->{symbols}} ) {
    $node = $func.".".$key;
    $shape = 'ellipse'; #default shape
    $color = 'black';   #default color
    if( ($hash->{symbols}{$key}{cat} ne 'streamread') 
      &&($hash->{symbols}{$key}{cat} ne 'streamwrite') ) {
        if ($hash->{symbols}{$key}{cat} eq 'funcall')     {$shape = 'box3d'        ;}  
        if ($hash->{symbols}{$key}{cat} eq 'alloca')      {$shape = 'box'          ; $color = 'cyan'}  
#        if ($hash->{symbols}{$key}{cat} eq 'arg')        { $shape = 'invtriangle' ;}  
        if ($hash->{symbols}{$key}{cat} eq 'arg')         {$shape = 'cds'          ; $color = 'blue';}  
        if ($hash->{symbols}{$key}{cat} eq 'func-arg')    {$shape = 'invhouse'     ; $color = 'blue';}  
        if ($hash->{symbols}{$key}{cat} eq 'autoindex')   {$shape = 'hexagon'      ; $color = 'green';}  
        if ($hash->{symbols}{$key}{cat} eq 'smache')      {$shape = 'doubleoctagon'; $color = 'burlywood';}  
        if ($hash->{symbols}{$key}{cat} eq 'split')       {$shape = 'trapezium'    ; $color = 'magenta';} 
        if ($hash->{symbols}{$key}{cat} eq 'merge')       {$shape = 'invtrapezium' ; $color = 'magenta';} 
        if ($hash->{symbols}{$key}{cat} eq 'impscalSplit'){$shape = 'ellipse'      ; $color = 'magenta';} 
        
        TirGrammarMod::addGraphNode(  $func
                                    , $key   #symbol (for accessing hash)
                                    , $node  #node (for setting node identifier)
                                    , $node  #name (name property)
                                    , $shape
                                    , $color
                                    );
    }#if
  }#foreach
}#if($pass == 1)

#Edges are created on both passes:
  #FIRST PASS:  The abstract DFG edge connections are made 
  #SECOND PASS: DOT connections are made
  
  #connect with edges 
  #loop over all symbols
  #for each, loop over all it "produces"
  #then check against "consumes" of ALL symbols (so another loop)
  #if match, then  connect
  my $pnode;
  my $cnode;
  my $pnode_cat;
  my $cnode_cat;
  my $label;
  
  #Connection by name: If node 1/2 is a function call instruction, what is the name of the corresponding port
  #in that function's local space
  my $pnode_local;
  my $cnode_local;
  
  #Connection by position:
  #If node 1/2 is an impscal or func-arg, what is the position of the edge's connection
  my $pnode_pos;
  my $cnode_pos;

  foreach my $keyP ( keys %{$hash->{symbols}} ) {
    #since all streams are PRODUCED by something else anyway (i.e. memories)
    #so no need to consider them as well when matching producers with consumers
#    if (1) {
    #if ( ($hash->{symbols}{$keyP}{cat} ne 'streamread') 
    #   && ($hash->{symbols}{$keyP}{cat} ne 'streamwrite') ) {

      #(only loop over "produces")
      # and all "consumes" should automatically be cared for
      
      $pnode_pos = 0;
      foreach my $produces (@{$hash->{symbols}{$keyP}{produces}}) {
        $pnode_pos        = $pnode_pos + 1;
        my $edgeDataType = 'undef';
        
        #again loop over all symbols, 
        foreach my $keyC ( keys %{$hash->{symbols}} ) {
          my $cnode_pos = 0;
          #now loop over each of its "CONSUMES"
          foreach my $consumes (@{$hash->{symbols}{$keyC}{consumes}}) {
            $cnode_pos = $cnode_pos + 1;
            
            #pick up the relevant dfgnode identifier, other props, and create edge-label for later use
            $pnode          = $hash->{symbols}{$keyP}{dfgnode}; 
            $pnode_cat      = $hash->{symbols}{$keyP}{cat};
            #if node is not function call, data type is directly available
            $edgeDataType = $hash->{symbols}{$keyP}{dtype} if ($pnode_cat ne 'funcall');
            
            #the name of pnode local 
            #------------------------
            #(that is, data output signal's name locally in the child module)
            #depends on category of that nod      
      
            #if this is a smache node, the local name of the port is what is being produced itself
            if      ($pnode_cat eq 'smache') {
              $pnode_local = $produces ;
            }
            #if this is an autoindex, then we have standard output signal name
            elsif   ($pnode_cat eq 'autoindex') {
              $pnode_local = 'counter_value' ;
            }
            #if node is funcall though, pick up name of child port (local name) by cycling through all args2child. Also, the data type of edge is now the type of the argument
            elsif   ($pnode_cat eq 'funcall') {
              foreach my $key (keys %{$hash->{symbols}{$keyP}{args2child}}) {
                if ($hash->{symbols}{$keyP}{args2child}{$key}{name} eq $produces) {
                  $pnode_local    = $hash->{symbols}{$keyP}{args2child}{$key}{nameChildPort};
                  $edgeDataType   = $hash->{symbols}{$keyP}{args2child}{$key}{type};
                }
              }
            }
            #by default, the 'local' name of a port is just out_POSITION (applies to impscals)
            else {
              $pnode_local = "out".$pnode_pos; 
            }
                        
            #the name of cnode local 
            #------------------------
            $cnode          = $hash->{symbols}{$keyC}{dfgnode}; 
            $cnode_cat      = $hash->{symbols}{$keyC}{cat};
            if ($cnode_cat eq 'funcall') {
              foreach my $key (keys %{$hash->{symbols}{$keyC}{args2child}}) {
                
                if ($hash->{symbols}{$keyC}{args2child}{$key}{name} eq $consumes) {
                  $cnode_local    = $hash->{symbols}{$keyC}{args2child}{$key}{nameChildPort};
                }
              }
            }
            else {
              $cnode_local    = "in".$cnode_pos; 
            }
            
            $label = $keyP.".".$pnode_pos.">".$keyC.".".$cnode_pos; #label should retain key identifers so we can spot the name of stream where app'
  
            #$main::dfGraph -> add_edge($node1, $node2);
            
            #produces and consumer match?
            if($produces eq $consumes) {
            ## // RETHINK THE FOLLOWING LOGIC; it was not working for output ports in hierarchical functions // 
            #if the relevant DFG nodes are the SAME  (alloca/impscal), but the
            #symbols(keyP and keyC) are different, it means that we do not need to create an edge-label
            #because the only way a node connects to itself is if the it is explicitly
            #connected through identical streams on both sides (produce and consume)
            #in a reduction operation
            #  if  (!( ($node1 eq $node2) 
            #          &&($keyP ne $keyC)  )) {
            
              #Connect only if source/dest not the same node...
              #OR  (if same), it is a reduction operation, identified by existence of a specific hash field
              if  ( ($pnode ne $cnode)                                        
                  ||(defined $main::CODE{$func}{symbols}{$keyP}{reductionOp}) 
                  )
              {
              #OR, it is a reduction operation #<---- IDENTIFY :: TODO
              #print YELLOW; print "Pass= $pass :: Adding an edge between $pnode and $cnode, for $produces \n"; print RESET;
                  #print "$func, $keyP, $keyC, edgeDataType = $edgeDataType\n";
                  #OR if node1 == node2, but this is a reduction...
                  TirGrammarMod::addGraphEdge(  $func.".".$pnode
                                              , $func.".".$cnode
                                              , $label
                                              , $produces    #This is the "connection"
                                              , $pnode_cat     
                                              , $pnode_local
                                              , $pnode_pos
                                              , $cnode_cat     
                                              , $cnode_local
                                              , $cnode_pos
                                              , 'black'
                                              , $pass
                                              , $edgeDataType
                                              ); 
              }#if
            }#if (prod eq cons)
          }#foreach
        }#foreach
      }#foreach
    #}#if (not stream)
  }#foreach my $keyP ( keys %{$hash->{symbols}} )
  
}#sub

# --------------------------------------------------------------------------
# Update cost of symbol, both in the HASH and the DFG
# --------------------------------------------------------------------------
sub setCostValue {
  my $func      = shift(@_);
  my $symbol    = shift(@_);
  my $typeofCost= shift(@_);
  my $key       = shift(@_);
  my $val       = shift(@_);
 
  #re-create the node name in the dfgraph
  my $node = $func.".".$symbol;
  #$node =~ s/(%|@)//; #remove %/@
    
  #update hash
  $main::CODE{$func}{symbols}{$symbol}{$typeofCost}{$key} = $val;
  
  #if the symbol is a function-call, then that child functions hash needs to be updated as well...
  if ($main::CODE{$func}{symbols}{$symbol}{cat} eq 'funcall') {
    #get function name with symbol (which would funcName.N format), and set value
    (my $childFuncName = $symbol) =~ s/\.\d+//;
    $main::CODE{$childFuncName}{$typeofCost}{$key} = $val;
  }
  
  #update DFG
  #$main::dfGraph -> set_vertex_attribute ($node, $key  => $val );
  my ($lat,$afi,$lfi,$efi,$fpo,$sd );
  my $perhash = $main::CODE{$func}{symbols}{$symbol}{performance};
  #update DFG-dot xlabel (since we dont know what was updated, so udpate all
  #This is what requires all values to be initialized before calling this function
  #print "::setCostValue:: $func and $symbol\n";
  if (defined $perhash->{lat}) {$lat = $perhash->{lat};} else {$lat=-1;}
  if (defined $perhash->{afi}) {$afi = $perhash->{afi};} else {$afi=-1;}
  if (defined $perhash->{lfi}) {$lfi = $perhash->{lfi};} else {$lfi=-1;}
  if (defined $perhash->{efi}) {$efi = $perhash->{efi};} else {$efi=-1;}
  if (defined $perhash->{fpo}) {$fpo = $perhash->{fpo};} else {$fpo=-1;}
  if (defined $perhash->{sd }) {$sd  = $perhash->{sd };} else {$sd =-1;}
  #$lat = $main::CODE{$func}{symbols}{$symbol}{performance}{lat};
  #$afi = $main::CODE{$func}{symbols}{$symbol}{performance}{afi};
  #$lfi = $main::CODE{$func}{symbols}{$symbol}{performance}{lfi};
  #$efi = $main::CODE{$func}{symbols}{$symbol}{performance}{efi};
  #$fpo = $main::CODE{$func}{symbols}{$symbol}{performance}{fpo};
  #$sd  = $main::CODE{$func}{symbols}{$symbol}{performance}{sd };
  #print "Setting xlabel for $func, $symbol\n";
  #no need to do this for main?
  if ($func ne 'main') {
    my $xlabel;
    if ($main::VERBOSE_DFG_ANNOT == 1){$xlabel = "($lat, $afi, $lfi, $efi, $fpo, $sd)";}
    else                              {$xlabel = "($lat, $lfi)";}

    $main::dfGraphDot ->add_node ( $node
                                , xlabel  => $xlabel
                                );
  }                                  
}

# --------------------------------------------------------------------------
# Create a local schedule for a function
# --------------------------------------------------------------------------

sub localScheduler {
  my $narg = @_;
  my $func = shift(@_);
  
  my $hash = $main::CODE{$func}; 
  my $node;
  my $sd;
  my $efi;
  my $lfi;
  my $afi;
  my $lat;
  my $fpo;
    
  #---------------------------------------------------------
  #First pass :: Loop through all and schedule input ports
  #---------------------------------------------------------
  foreach my $key ( keys %{$hash->{symbols}} ) {
    #re-create the node name in the dfgraph
    $node = $func.".".$key;
    
    #For main, the first pass sets parameters for alloca variables referring to global arrays
    #--------
    if($func eq 'main') {
      #INPUT/OUTPUT args only::source and sink vertices are input/output arguments
      #NOTE: (For now) I assume ALL  IOs point to arrays in global memory as this is main
      if  (  ($main::dfGraph->is_source_vertex($node)) 
          || ($main::dfGraph->is_sink_vertex($node))  ) {
          # see scheduling document in ../../doc for details
          $lat = 0;
          $lfi = 1;
          $efi = 1;
          $afi = 1;
          $fpo = 1;
          $sd  = 0;
          
          #update calcualted costs
          setCostValue($func,$key,'performance','sd'  ,$sd);
          setCostValue($func,$key,'performance','efi' ,$efi);
          setCostValue($func,$key,'performance','afi' ,$afi);
          setCostValue($func,$key,'performance','lat' ,$lat);
          setCostValue($func,$key,'performance','lfi' ,$lfi);
          setCostValue($func,$key,'performance','fpo' ,$fpo);
      }    
    }#main
    #For Non-Main: The first pass sets parameters for input arguments. Note that this is still "local" scheduling
    #------------
    else {
      #INPUT args only::source vertices are input arguments
      if ($main::dfGraph->is_source_vertex($node)) {
          #all input ports have their SD set to 0
          $sd = 0;
          
          #TODO/NOTE: The EFI is assumed to 1 for now, but in reality it will
          #depend on EFI of predecessor entity(s)
          $efi = 1;
          
          #lfi is already known
          $lfi = $hash->{symbols}{$key}{performance}{lfi};
          
          #AFI is max of the two
          $afi = max ($lfi, $efi);
          
          #update calcualted costs
          setCostValue($func,$key,'performance','sd'  ,$sd);
          setCostValue($func,$key,'performance','efi' ,$efi);
          setCostValue($func,$key,'performance','afi' ,$afi);
      }
    }#not-main
  }#foreach my $key

  #---------------------------------------------------------
  #Second pass :: Schedule all nodes in the function
  #---------------------------------------------------------
  #for each node other than input arguments, if all predecessors have been scheduled, then schedule
  #this as well, until all nodes have been scheduled
  #A non-negative value of SD is used as an indication that a node has been scheduled
  my $done = 0; #have all nodes been scheduled?
  my @predecs;    #all predecessors of a node under consideration
  
  #running value of maxumim SD at the output nodes.
  #which is then used to calculate maximum OPD at the output nodes
  #All output nodes are later made to match this OPD
  #set to this value
  my $sd_max_at_output = 0;
  my $opd_max_at_output = 0;
  
  #loop through all nodes until done
  #for (my $i=0; $i <= 100; $i++) {
  while(!($done)) {
    #pick a node, and if all predecs scheduled, then schedule it too
    foreach my $key ( keys %{$hash->{symbols}} ) {
      #print GREEN; print "in the scheduling loop for $key\n"; print RESET;
      $node = $func.".".$key;
      
      #The predicate determining which nodes require scheduling is different in main and non-main
      #-------------
      my $cond;
      #For main, schedule if NOT a global memory variable (source or sink), and not yet scheduled
      if($func eq 'main') {$cond = (  ($hash->{symbols}{$key}{performance}{sd} < 0) 
                                   && (!(  ($main::dfGraph->is_source_vertex($node)) 
                                        || ($main::dfGraph->is_sink_vertex($node)  ) 
                                        )
                                      )   
                                   ); }
      #For others, schedule if NOT an input port, and not yet scheduled
      else                {$cond = (  ($hash->{symbols}{$key}{performance}{sd} < 0) 
                                   && (!($main::dfGraph->is_source_vertex($node)))   ); }
      
      if($cond) {
        #find all pre-decessors
        #@predecs = $main::dfGraph->all_predecessors($node);
        @predecs = $main::dfGraph->predecessors($node);
        
        #are all predecessors scheduled? (is their SD >=0 ?)
        my $predecsok = 1;
        
        #if any preds is not scheduled, negate flag
        foreach (@predecs) {
          my (undef, $psymbol) = split('\.', $_,2); #get 2nd part (symbol) from node-name
          $predecsok = 0 if(  ($hash->{symbols}{$psymbol}{performance}{sd} < 0)  #pred not been scheduled
                           && ($psymbol ne $key)); #not my own predec (i.e. not a reduction)
          #$hash->{symbols}{$psymbol}{performance}{sd} = 100;
        }
        
        #scedule this node as all predecs have been scheduled
        if ($predecsok == 1) {
          #print YELLOW; print "predecsok for $key\n"; print RESET;
          my $sd_max  = 0;
          my $efi_max = 0;
          my $afi_max = 0;
          my $lat_me  = $hash->{symbols}{$key}{performance}{lat};
          
          #loop through each predec, calc SD and EFI due to it, and set if higher than prev calc.
          foreach (@predecs) {
            my (undef, $psymbol) = split('\.', $_,2); #get 2nd part (symbol) from node-name
            my $sd_p  = $hash->{symbols}{$psymbol}{performance}{sd};
            my $lat_p = $hash->{symbols}{$psymbol}{performance}{lat};
            my $afi_p = $hash->{symbols}{$psymbol}{performance}{afi};
            my $fpo_p = $hash->{symbols}{$psymbol}{performance}{fpo};

            my ($sd_me, $efi_me) = (0) x 2;
            #don't calculate if reduction self-reference
            if ($psymbol ne $key) {
              $sd_me  = $sd_p + ($lat_p-1) + ($afi_p * $fpo_p);
              $efi_me = $afi_p * $fpo_p;
            }
            $efi_max = mymax($efi_me, $efi_max);
            $sd_max  = mymax($sd_me , $sd_max);

            #print YELLOW; print "$psymbol -> $key :: sd_me = $sd_me; sd_max = $sd_max\n"; print RESET;
          }#foreach
      
          #see if sd_max_at_output/opd_max_at_output needs updating          
          if(($hash->{symbols}{$key}{cat} eq 'arg') || ($hash->{symbols}{$key}{cat} eq 'func-arg')) {
            if($hash->{symbols}{$key}{dir} eq 'output') {
              #$opd_max_at_output = mymax($opd_max_at_output, $sd_max_at_output+$lat_me);
              #$sd_max_at_output  = mymax($opd_max_at_output-$lat_me, $sd_max);

              #the global output delay is max of prev, vs this nodes (local) sd_max +  its internal latency
              $opd_max_at_output = mymax($opd_max_at_output, $sd_max+$lat_me);
              
              #the sd_max_at_output is now irrelevant
              #$sd_max_at_output  = mymax($sd_max_at_output , $opd_max_at_output-$lat_me);

              print ">>> $key, $opd_max_at_output, $sd_max_at_output, $sd_max, $lat_me\n";
            }
          }
          #$sd_max_at_output  = $opd_max_at_output-$lat_me;
          
          #the afi of this key is max of lfi and efi (and efi is now known after prev loop)
          #$afi_max = mymax ($efi_max, $hash->{symbols}{$key}{performance}{fpo});
          $afi_max = mymax ($efi_max, $hash->{symbols}{$key}{performance}{lfi});
          
          #update calculated values of sd, efi, afi
          setCostValue($func,$key,'performance','sd' ,$sd_max);
          setCostValue($func,$key,'performance','efi',$efi_max);
          setCostValue($func,$key,'performance','afi',$afi_max);
          #print("TyBEC::schedule:: $key in $func has been scheduled with $sd_max, $efi_max, $afi_max\n");
        }#if
        
        #loop through ALL nodes to see if all done or not, set flag
        $done = 1;
        foreach my $key2 ( keys %{$hash->{symbols}} ) {
          $done = 0 if($hash->{symbols}{$key2}{performance}{sd} < 0);
          #print "::localScheduler::key2 = $key2 \n"  if($hash->{symbols}{$key2}{performance}{sd} < 0);
        }
        
      }#if
    }#for
  }#while
  
  #---------------------------------------------------------------------
  #2.15 pass :: Synchornize output nodes
  #---------------------------------------------------------------------
  #there is an additional constraint on the SD that can only be considered on a second pass over all
  #OUTPUT nodes: All output nodes must have the *same* sd, equal to the maximum SD of all nodes (already calculated in the previous loop). This SD constraint, unlike others, is NOT
  #dependent on a predecessor,  but on "peers", which is why we need an additional pass to set this SD on 
  #all output nodes    
  foreach my $key ( keys %{$hash->{symbols}} ) {
    my $lat_me  = $hash->{symbols}{$key}{performance}{lat};
    if(($hash->{symbols}{$key}{cat} eq 'arg') || ($hash->{symbols}{$key}{cat} eq 'func-arg')) {
      if($hash->{symbols}{$key}{dir} eq 'output') {
        setCostValue($func,$key,'performance','sd' ,$opd_max_at_output-$lat_me);      
        #setCostValue($func,$key,'performance','sd' ,$sd_max_at_output);      
      }
    }
  }

  
  
#  #---------------------------------------------------------------------
#  #2.25 pass :: Synchornize output nodes
#  #---------------------------------------------------------------------
#  #Now that all nodes are scheduled, we revisit all output nodes and make sure they are in step
#  #by setting the SD of all to the max
#  my $sd_max = 0;    
#  my $sd_me;
#  
#  #loop through each output node and find the max
#  foreach my $key ( keys %{$hash->{symbols}} ) {
#    #print GREEN; print "in the scheduling loop for $key\n"; print RESET;
#    $node = $func.".".$key;
#    my $nsucc = $main::dfGraph->successors($node);
#    #see if this is output node
#    if( ($main::dfGraph->is_sink_vertex($node)  )
#      ||($main::dfGraph->is_self_loop_vertex($node) && ($nsucc == 1) )
#      ){
#      $sd_me = $hash->{symbols}{$key}{performance}{sd};  
#      $sd_max  = mymax($sd_me , $sd_max);
#    }
#  }
#  
#  #loop again through each output node and set its sd to sd_max
#  foreach my $key ( keys %{$hash->{symbols}} ) {
#    #print GREEN; print "in the scheduling loop for $key\n"; print RESET;
#    $node = $func.".".$key;
#    my $nsucc = $main::dfGraph->successors($node);
#    #see if this is output node
#    if( ($main::dfGraph->is_sink_vertex($node)  )
#      ||($main::dfGraph->is_self_loop_vertex($node) && ($nsucc == 1) )
#      ){
#      setCostValue($func,$key,'performance','sd' ,$sd_max);
#    }
#  }

  #---------------------------------------------------------------------
  #2.5 pass :: Infer buffer on un-balanced paths (latency differences)
  #---------------------------------------------------------------------
  
  #Check for buffer inference for every symbol
  foreach my $ckey ( keys %{$hash->{symbols}} ) {
    #the current node is the consumer node
    my $cnode = $func.".".$ckey;
    
    #find all (immediate) pre-decessors
    @predecs = $main::dfGraph->predecessors($cnode);

    #my SD is the sd_max from SD due to all predecessors, as computed in previous pass
    my $my_sd = $hash->{symbols}{$ckey}{performance}{sd};
    
    #if consumer is a reduction node, then I do not need to infer buffers?
    #TODO: check if this logic is ok
    if(defined $hash->{symbols}{$ckey}{reductionOp}) {
    }
    
    else {
    #for each predecessor compare the SD due to it with the SD_max, find the difference
    #and infer buffer if applicable
    foreach (@predecs) {
      my $pnode = $_;
      #NOTE/TODO: I am assuming just one edge here? 
      my $pnode_local = $main::dfGraph ->get_edge_attribute_by_id ( $pnode, $cnode, 0, 'pnode_local');
      my $cnode_local = $main::dfGraph ->get_edge_attribute_by_id ( $pnode, $cnode, 0, 'cnode_local');
      my $connection  = $main::dfGraph ->get_edge_attribute_by_id ( $pnode, $cnode, 0, 'connection');
      #print "pnode = $pnode, pnode_local = $pnode_local;; cnode = $cnode, cnode_local = $cnode_local, connection = $connection\n";
      
      
      my (undef, $pkey) = split('\.', $_,2); #get 2nd part (symbol) from node-name
      my $sd_p  = $hash->{symbols}{$pkey}{performance}{sd};
      my $lat_p = $hash->{symbols}{$pkey}{performance}{lat};
      my $afi_p = $hash->{symbols}{$pkey}{performance}{afi};
      my $fpo_p = $hash->{symbols}{$pkey}{performance}{fpo};
      
      #the starting delay as determined by this particular predecessor only
      my $sd_due2_this = $sd_p + ($lat_p-1) + ($afi_p * $fpo_p);
      
      #buffsize is difference of the determine SD (based on maximum SD), and the SD due to this predecessor
      my $buff_size_4this   = $my_sd-$sd_due2_this; #buffer size due to THIS consumer
      my $buff_size         = $buff_size_4this; #actual buffer size (max of this, and previously set, if app')
      my $buff_offset_4this = $buff_size_4this-1;
        #there may be multiple fan-outs from this buffer. So the max buff size may be more than what is required
        #for this particular consumer node. Hence we need to track what is the offset for this consumer
     
     
      #Add buffer node
      if   ($buff_size_4this > 0) {
        #create symbol(key) and node name, produces, consumes
        #my $bufkey = $pkey."__".$ckey; 
        my $bufkey = $pkey."_".$ckey."_b"; 
        $bufkey =~ s/\%//g; 
        my $bufnode    = $func.".".$bufkey;
        
        #Check if this buffer already exists, and if so, set the buffer's size to max
        if($main::dfGraph->has_vertex($bufnode)) {
          my $previousBuffSize = $main::CODE{$func}{symbols}{$bufkey}{bufferSizeWords};
          $buff_size = mymax($previousBuffSize, $buff_size_4this);
          #print YELLOW; print "Buffer $bufnode for $pnode in $func alread exists::$previousBuffSize, $buff_size_4this_con, $buff_size \n"; print RESET;
        }
        #my $bufDataType = $main::CODE{$func}{symbols}{$ckey}{dtype};
        my $bufDataType = $main::dfGraph->get_edge_attribute_by_id($pnode, $cnode, 0,'edgeDataType'); 
          #TODO: I have hardwired the the "by_id" to 0th edge between these two nodes. This will FAIL if
          #there are multiple edges of DIFFERENT TYPES between two nodes

        (my $bufWordWidth = $bufDataType) =~ s/\D+//g;
        my $bufferSizeBits = $buff_size * $bufWordWidth;
        my $bufConsumes    = $main::CODE{$func}{symbols}{$ckey}{dtype};
        my $shape = 'component';
        
        (my $ckey_plain = $ckey) =~ s/\%//g;
        #my $buffPkey = $pkey.'_to_'.$ckey_plain.'_b';
        my $buffProduces = $connection.'_b_'.$buff_offset_4this;
          #the "produces" as appended with the offset value, so that for each different offset required of this
          #buffer, there is a different "PRODUCES" entry in the hash
        
        #make entry in symbol table?
        $main::CODE {$func} {symbols}{$bufkey}{dfgnode}   = $bufkey;    
        $main::CODE {$func} {symbols}{$bufkey}{cat}       = 'fifobuffer';
        $main::CODE {$func} {symbols}{$bufkey}{dtype}     = $bufDataType;
        #@{$main::CODE{$func}{symbols}{$bufkey}{consumes}} = ($pkey);     #is this ok? or use the "produces/consumes" from hashtable
        @{$main::CODE{$func}{symbols}{$bufkey}{consumes}} = ($connection);     #is this ok? or use the "produces/consumes" from hashtable
        push @{$main::CODE{$func}{symbols}{$bufkey}{produces}}     , $buffProduces;
        push @{$main::CODE{$func}{symbols}{$bufkey}{tapsAtDelays}} , $buff_offset_4this+1;
        $main::CODE{$func}{symbols}{$bufkey}{funcunit}  = 'fifobuf';
        $main::CODE{$func}{symbols}{$bufkey}{synthunit} = 'fifobuf';
        $main::CODE{$func}{symbols}{$bufkey}{synthDtype} = $bufDataType; 
        $main::CODE{$func}{symbols}{$bufkey}{bufferSizeWords} = $buff_size; 
        $main::CODE{$func}{symbols}{$bufkey}{bufferSizeBits}  = $bufferSizeBits;
        
        #change the "consumes" of the consumer to reflect the buffered value
        #get array reference from hash
        my $consArrRef = $main::CODE{$func}{symbols}{$ckey}{consumes};
        
        #loop through all "consumes" of consumer, and if match, then update it to reflect
        #the buffered version of that variable (so that correct connection is now made)
        for my $i (0 .. $#{$consArrRef}) {
          #print "::localScheduler:: cnode = $cnode; pnode = $pnode; INDEX = $i, consumes[i] = $$consArrRef[$i], pkey = $pkey \n";
          #if($$consArrRef[$i] eq $pkey) {
          if($$consArrRef[$i] eq $connection) {
            $$consArrRef[$i] = $buffProduces;
          }
        }
        
        #also, loop through all args2child{key}{name} to see if match, as these need to be updated as well
        #to reflect change in signal to be passed to a child function
        my $args2childHashRef = $main::CODE{$func}{symbols}{$ckey}{args2child};
        foreach my $key (keys %{$args2childHashRef}){
          if ($args2childHashRef->{$key}{name} eq $connection) {
              $args2childHashRef->{$key}{name} = $buffProduces;
          }
        }
        
        ##add graph node
        TirGrammarMod::addGraphNode(  $func
                              , $bufkey   #symbol (for accessing hash)
                              , $bufnode  #node (for setting node identifier)
                              , $bufnode  #name (name property)
                              , $shape
                              , 'red'
                              );

        
        #remove producer->consumer edge
        $main::dfGraph->delete_edge($pnode, $cnode);
          #This won't take care of multiple edges! :: TODO
       
        #Add performance and resource cost for the buffer
        Cost::costFifoBuffers ( $func
                              , $bufkey
                              , $buff_size
                              , $bufferSizeBits);
      }#if
    }
  }#foreach
  }#else
}#sub
  
  
sub globalScheduler {  
  my $narg = @_;
  my $func = shift(@_);
  
  my $hash = $main::CODE{$func}; 
  my $node;
  my $sd;
  my $efi;
  my $lfi;
  my $afi;
  my $lat;
  my $fpo;
  #---------------------------------------------------------------------
  #Third pass :: Calculate overall scheduling parameters for function
  #---------------------------------------------------------------------
  
  #main has asynch-gates to the outside world, so it is always good to go when asynch handshakes allow it to
  if($func eq 'main') {
    $hash->{performance}{efi}=1;
    $hash->{performance}{afi}=1;
    $hash->{performance}{sd }=0;
  }
  #other functions
  else {
    # At this stage, we cannot calculate any parameter depending on predecessors
    # to the function as a whole, as that scheduling will happen at the parent function
    # that is: efi, afi, sd
    # Note: We are assuming symmetrical input and output (terminal) nodes of the function
    $hash->{performance}{efi}=-1; #if (!(exists $hash->{performance}{efi}));
    $hash->{performance}{afi}=-1; #if (!(exists $hash->{performance}{afi}));
    $hash->{performance}{sd }=-1; #if (!(exists $hash->{performance}{sd} )); 
  }

  #get source and sink vertices (input and output nodes) for later use  
  #Note: this approach is problematic as I don't have separate DFGs for
  #functions, but a large single DFG with disconnected subgraphs
  my @inputs = $main::dfGraph->source_vertices();
  my @outputs = $main::dfGraph->sink_vertices();
  
  #find one input and one output node
  #also find maximum AFI from all nodes, which is the AFI of the  parent node
  my ($inNode, $outNode);
  my $maxLFI = 0;
  foreach my $key ( keys %{$hash->{symbols}} ) {
    my $node = $func.".".$key;
    $inNode = $node if($main::dfGraph->is_source_vertex($node));
    
    #see if AFI is maximum
    $maxLFI = mymax($maxLFI, $hash->{symbols}{$key}{performance}{lfi});
    
    #normally, outNode is one without successors, but if there is just one outNode
     #that is a reduction node, then we have no such node without successors
     #in that case, outNode = has one successor which is self (i.e. self-loop, and one successor)
    my $nsucc = $main::dfGraph->successors($node);
    my $is_sink_vertex = ($nsucc == 0);
    $outNode  = $node if( ($main::dfGraph->is_sink_vertex($node)  )
                      ||($main::dfGraph->is_self_loop_vertex($node) && ($nsucc == 1) )
                      );
                      
    #if($node eq "$func.%vin0_stream_load_lane1") {
    #  print GREEN; print "For $func, node = $node; outNode = $outNode; nsucc = $nsucc\n";  print RESET;
    #  print "true FIRST\n"  if ($is_sink_vertex);
    #  print "true SECOND\n" if ($main::dfGraph->is_self_loop_vertex($node) && ($nsucc == 1) );
    #}
  }
  
  (undef, $inNode)  = split('\.', $inNode,2);
  (undef, $outNode) = split('\.', $outNode,2);
  #print YELLOW; print "$func :: outNode = $outNode, inNode = $inNode \n"; print RESET;
  
  #Calculate 3 parameters we can at this point
  #(refer to ../../doc/tybec_dfg_scheduler_buffer_generator.pdf for more details
  #_i/_o refer to input/output node
  #lat = SD_o + lat_o
  #lfi = lfi_i
  #fpo = fpo_o
  $hash->{performance}{lat} = $hash->{symbols}{$outNode}{performance}{sd}
                            + $hash->{symbols}{$outNode}{performance}{lat};
  $hash->{performance}{fpo} = $hash->{symbols}{$outNode}{performance}{fpo};
  
  #not quite true; the firing interval should be limited by the largest FI 
  #$hash->{performance}{lfi} = $hash->{symbols}{$inNode}{performance}{lfi}; 
  #currently this is hardwired, I need to change this
  #if($func eq 'pow') {
  $hash->{performance}{lfi} = $maxLFI; 
  #}
  
  #Main takes latency from its (only) function call module?
  if($func eq 'main') {
#    my $top = $hash->{topKernelName};
#    $hash->{performance}{lat} = $hash->{symbols}{$key}{performance}{lat};
  
   foreach my $key ( keys %{$hash->{symbols}} ) {
     if ($hash->{symbols}{$key}{cat} eq 'funcall') {
       $hash->{performance}{lat} = $hash->{symbols}{$key}{performance}{lat};
     }
   }
  }
}#sub()  
  


## # --------------------------------------------------------------------------
## # Create a local schedule for a (non-main) function
## # --------------------------------------------------------------------------
## 
## sub localSchedulerMain {
##   my $narg = @_;
##   my $func = shift(@_);
##   
##   my $hash = $main::CODE{$func}; 
##   my $node;
##   my $sd;
##   my $efi;
##   my $lfi;
##   my $afi;
##   my $lat;
##   my $fpo;
##     
##   #---------------------------------------------------------------------------
##   #First pass :: Loop through all and schedule global memories (asynch gates)
##   #---------------------------------------------------------------------------
##   foreach my $key ( keys %{$hash->{symbols}} ) {
##     #re-create the node name in the dfgraph
##     $node = $func.".".$key;
##     
##     #INPUT/OUTPUT args only::source and sink vertices are input/output arguments
##     #NOTE: (For now) I assume ALL  IOs point to arrays in global memory as this is main
##     if  (  ($main::dfGraph->is_source_vertex($node)) 
##         || ($main::dfGraph->is_sink_vertex($node))  ) {
##         # see scheduling document in ../../doc for details
##         $lat = 0;
##         $lfi = 1;
##         $efi = 1;
##         $afi = 1;
##         $fpo = 1;
##         $sd  = 0;
##         
##         #update calcualted costs
##         setCostValue($func,$key,'performance','sd'  ,$sd);
##         setCostValue($func,$key,'performance','efi' ,$efi);
##         setCostValue($func,$key,'performance','afi' ,$afi);
##         setCostValue($func,$key,'performance','lat' ,$lat);
##         setCostValue($func,$key,'performance','lfi' ,$lfi);
##         setCostValue($func,$key,'performance','fpo' ,$fpo);
##     }
##   }#foreach my $key
## }#sub

# ============================================================================
# GRAMMAR ACTIONS' SUB-ROUTINES
# ============================================================================
# Easier to maintain/re-use code

# ----------------------------------------------------------------------------
# act --> ALLOCA
# ----------------------------------------------------------------------------
sub actALLOCA{
#print "tada \n";
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  #because I use a subrule(?) to get addrspace, so I get it as an array
  #my @aspace = @{$item[6]};
  my $aspace = pop(@{$item[6]});
  my $func = $arg[0];
  my $mem  = $item{VARIABLE};
  
  #Extracting info from data-type string (see footnote [1] for regex explanation)
               # 1     2    3       4     #             
  #$item[4] =~ /(ui|i)(\d+)(\.?)(\d+|auto)?/;
  $item[4] =~ /(ui|i|float)(\d+)(\.?)(\d+|auto)?/;
  my $unitDataType = $1.$2; #e.g. i32, ui2 etc
  my $size = 1;             #default size is scalar
  $size = $4 if defined $4; #if there was a size given (so not a scalar), then get it
     
  # Entry in the symbol table:
  $main::CODE {$func}   {symbols} {$mem} {dfgnode} = $mem;
  $main::CODE {$func}   {symbols} {$mem} {cat} = "alloca";
  $main::CODE {$func}   {symbols} {$mem} {dtype} = $item[4];
  $main::CODE {$func}   {symbols} {$mem} {aspace} = $aspace;
  $main::CODE {$func}   {symbols} {$mem} {size}   = $size;
  @{$main::CODE {$func} {symbols} {$mem} {produces}}= ($mem);
  @{$main::CODE {$func} {symbols} {$mem} {consumes}}= ();
  
  $main::CODE{$func}{symbols}{$mem}{connStreamCount} = 0;
  $main::CODE{$func}{symbols}{$mem}{connInStreamCount} = 0;
  $main::CODE{$func}{symbols}{$mem}{connOutStreamCount} = 0;
  
  #IF the function is MAIN, then we set the parameter bufsize, as that is required for OCL code generation
  #We are working on the assumption that any alloca call actually represents the size of ALL alloca (global) arrays in main: NOTE
  #We just check to make sure this alloca is not a scalar
  if(($func eq 'main') && ($size > 1)) {
    $main::CODE{$func}{bufsize} = $size;
  }

  #initialize cost (though not used), as otherwise I get errors
  my $hashref = $main::CODE{$func}{symbols}{$mem}; 
  Cost::costInit($hashref);  
   
 print "TyBEC: Found allocated memory: $mem, $unitDataType , $size words , addressspace = $aspace \n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_STREAM_START_ADDR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  #$main::CODE{$arg[1]}{symbols}{$arg[0]}{startAddr} = eval($item{EXPRESSION});
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{startAddr} = $item{IMM_INT_OPER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_STREAM_TYPE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{streamtype} = $item{TYPES_OF_STREAMS};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_STREAM_SIZE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{size} = $item{IMM_INT_OPER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_STREAM_STRIDE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{stride} = $item{IMM_INT_OPER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAMREAD{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};

  my $func = $arg[0];
  my $mystream   = $item{LOCAL_VAR};
  my $mymem      = $item{VARIABLE};
  
  # Entry in the symbol table:
  $main::CODE   {$func} {symbols} {$mystream} {dfgnode}   = $mymem;  
  $main::CODE   {$func} {symbols} {$mystream} {cat}       = "streamread";
  $main::CODE   {$func} {symbols} {$mystream} {dtype}     = $item{DATA_TYPE};
  @{$main::CODE {$func} {symbols} {$mystream} {produces}} = ($mystream);
  @{$main::CODE {$func} {symbols} {$mystream} {consumes}} = ($mymem);
  $main::CODE {$func} {symbols} {$mystream} {maxPosOffset}      = 0;
  $main::CODE {$func} {symbols} {$mystream} {numOffsetStreams}  = 0;
  $main::CODE {$func} {symbols} {$mystream} {maxNegOffset}      = 0;

  ##assign default values for parameters not defined
  $main::CODE{$func}{symbols}{$mystream}{stride} = 1
    if (!exists $main::CODE{$func}{symbols}{$mystream}{stride});

  $main::CODE{$func}{symbols}{$mystream}{startAddr} = 0
    if (!exists $main::CODE{$func}{symbols}{$mystream}{startAddr});
  
  #Updates based on the memory connection of this stream
  
  #pickup memory type (addrspace qualifier) and add to stream's hash as well
  $main::CODE{$func}{symbols}{$mystream}{memConnAddrSpace}  
    = $main::CODE{$func}{symbols}{$mymem}{addrspace};
  
  #Also update the hash of relevant memory object
  # pick up connStreamCount value from the hash 
  my $counter = $main::CODE{$func}{symbols}{$mymem}{connStreamCount};
  # update in hash
  $main::CODE{$func}{symbols}{$mymem}{streamConn}{$counter}{name} = $mystream;
  $main::CODE{$func}{symbols}{$mymem}{streamConn}{$counter}{dir} = 'input';  

  # increment counter in the hash
  $main::CODE{$func}{symbols}{$mymem}{connStreamCount} = $counter + 1;
  # also increment counter specific for read streams
  $main::CODE{$func}{symbols}{$mymem}{connInStreamCount}++;
 
  #initialize cost (though not used), as otherwise I get errors
   my $hashref = $main::CODE{$func}{symbols}{$mystream}; 
  Cost::costInit($hashref);
 
   print "TyBEC: Found STREAMREAD: $mystream, connected to  $mymem\n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAMWRITE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};

  my $func = $arg[0];
  my $mystream   = $item{LOCAL_VAR};
  my $mymem      = $item{VARIABLE};
  
  # Entry in the symbol table:
  $main::CODE   {$func} {symbols} {$mystream} {dfgnode}   = $mymem;  
  $main::CODE   {$func} {symbols} {$mystream} {cat}       = "streamwrite";
  $main::CODE   {$func} {symbols} {$mystream} {dtype}     = $item{DATA_TYPE};
  @{$main::CODE {$func} {symbols} {$mystream} {consumes}} = ($mystream);
  @{$main::CODE {$func} {symbols} {$mystream} {produces}} = ($mymem);

  
  #pickup memory type (addrspace qualifier) and add to stream's hash as well
  $main::CODE{$func}{symbols}{$mystream}{memConnAddrSpace}  
    = $main::CODE{$func}{symbols}{$mymem}{addrspace};
  
  #Also update the hash of relevant memory object
  # pick up connStreamCount value from the hash 
  my $counter = $main::CODE{$func}{symbols}{$mymem}{connStreamCount};
  # update in hash
  $main::CODE{$func}{symbols}{$mymem}{streamConn}{$counter}{name} = $mystream;
  $main::CODE{$func}{symbols}{$mymem}{streamConn}{$counter}{dir} = 'output';  

  # increment counter in the hash
  $main::CODE{$func}{symbols}{$mymem}{connStreamCount} = $counter + 1;
  # also increment counter specific for read streams
  $main::CODE{$func}{symbols}{$mymem}{connOutStreamCount}++;  
  
  #initialize cost (though not used), as otherwise I get errors
   my $hashref = $main::CODE{$func}{symbols}{$mystream}; 
  Cost::costInit($hashref);  
  
  print "TyBEC: Found STREAMWRITE: $mystream, connected to  $mymem\n";
  
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSPLIT_OUT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  #I have to use a global temporary array as at this point in the parse I
  #I don't know that source stream 
  push  @main::split_outs, $item{OPER};  
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSPLIT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};

  my $func      = $arg[0];
  my $dtype     = $item{DATA_TYPE};
  my $instream  = $item{OPER1};
  my $nsplits   = $item{INTEGER};
  my $node = "split.".$instream;

  # ----------------------------------------
  # Entry in the symbol table (for  SPLIT node)
  # ----------------------------------------
  $main::CODE{$func}{symbols}{$node}{dfgnode}   = $node;  
  $main::CODE{$func}{symbols}{$node}{cat}       = 'split';
  $main::CODE{$func}{symbols}{$node}{dtype}     = $dtype;
  $main::CODE{$func}{symbols}{$node}{nSplit}    = $nsplits;
  $main::CODE{$func}{symbols}{$node}{funcunit}  = 'split';
  $main::CODE{$func}{symbols}{$node}{synthunit} = 'split';
  $main::CODE{$func}{symbols}{$node}{synthDtype} = $dtype;   
  
  @{$main::CODE{$func}{symbols}{$node}{consumes}} = ($instream);
#  @{$main::CODE{$func}{symbols}{$node}{produces}} = @main::split_outs;
  @{$main::CODE{$func}{symbols}{$node}{produces}} = ($node);

  # ----------------------------------------
  # Set port directions for caller function
  # ----------------------------------------
  #If the SPLIT is on an argument, then we need to tell that argument that you are an input
  TirGrammarMod::setArgDir($func, '', $instream, '');
  
  # -------
  # Cost it
  # -------
  my $hashref = $main::CODE{$func}{symbols}{$node}; 
  Cost::costSplit($func, $node); 
  
  # -------------------------------------------------
  #Now create nodes for each split output, cost them
  # -------------------------------------------------
  #loop over split-outs, create their nodes and cost them
  my $pos = 0;
  foreach (@main::split_outs) {
    $pos = $pos + 1;
    my $splitStream = $_;
    $main::CODE{$func}{symbols}{$splitStream}{dfgnode}      = $splitStream;  
    $main::CODE{$func}{symbols}{$splitStream}{cat}          = 'impscalSplit';
    $main::CODE{$func}{symbols}{$splitStream}{dtype}        = $dtype;
    $main::CODE{$func}{symbols}{$splitStream}{splitSource}  = $node;
    $main::CODE{$func}{symbols}{$splitStream}{nSplit}       = $nsplits;
    $main::CODE{$func}{symbols}{$splitStream}{mySplitSeq}   = $pos;
    $main::CODE{$func}{symbols}{$splitStream}{funcunit}     = 'impscalSplit';
    $main::CODE{$func}{symbols}{$splitStream}{synthunit}    = 'impscalSplit';
    $main::CODE{$func}{symbols}{$splitStream}{synthDtype}   = $dtype;   
    
    @{$main::CODE{$func}{symbols}{$splitStream}{consumes}} = ($node);
    @{$main::CODE{$func}{symbols}{$splitStream}{produces}} = ($splitStream);
    
    my $hashref = $main::CODE{$func}{symbols}{$node}; 
    Cost::costSplitOut($func, $splitStream); 
  }
  
  
  print "TyBEC: Found split $func, $dtype, $instream\n"; 
  print "TyBEC: Outputs of split are: @main::split_outs \n";
  @main::split_outs=(); 
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMERGE_IN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  #I have to use a global temporary array as at this point in the parse I
  #I don't know that source stream 
  push  @main::merge_ins, $item{OPER};  
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMERGE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};

  my $func      = $arg[0];
  my $dtype     = $item{DATA_TYPE};
  my $outstream = $item{OPER_DEST};
  my $nmerges   = $item{INTEGER};
   
  my $node = "merge.".$outstream;
  #my $node = $outstream;
  
  # Entry in the symbol table (for both the SPLIT node and EACH splitted stream)
  $main::CODE{$func}{symbols}{$node}{dfgnode}   = $node;  
  $main::CODE{$func}{symbols}{$node}{cat}       = 'merge';
  $main::CODE{$func}{symbols}{$node}{dtype}     = $dtype;
  $main::CODE{$func}{symbols}{$node}{nMerge}    = $nmerges;
  $main::CODE{$func}{symbols}{$node}{funcunit}  = 'merge';
  $main::CODE{$func}{symbols}{$node}{synthunit} = 'merge';
  $main::CODE{$func}{symbols}{$node}{synthDtype} = $dtype;   

  @{$main::CODE{$func}{symbols}{$node}{consumes}} = @main::merge_ins;
  @{$main::CODE{$func}{symbols}{$node}{produces}} = ($outstream);

  # -------
  # Cost it
  # -------
  my $hashref = $main::CODE{$func}{symbols}{$node}; 
  Cost::costMerge($func, $node); 
  
  print "TyBEC: Found merge $func, $dtype, $outstream\n"; 
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMAIN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $func  = 'main';
  my $hash = $main::CODE{main}; 

  print "TyBEC: Found function definition of main.\n\n";

  # ------------------------------------------------
  # Create DFG for this function 
  # (first pass, no DOT edges yet as buffers may be added)
  # but abstract-DFG requires edges for localScheduler to function
  # ------------------------------------------------   
  TirGrammarMod::createDFG($func, 1);

  # ------------------------------------------------
  # Calls local scheduler 
  #  - Schedules inside function
  #  - does not calculate global function parameters yet (edges to inferred buffers not added yet)
  #  - Also infer buffers (adds new nodes)
  # ------------------------------------------------   
  #(leaf kernels only for now)
  TirGrammarMod::localScheduler($func);# if($hash->{hierarchical} eq 'no');

  # ------------------------------------------------
  # Create DFG for this function 
  #  - second pass, adds new abstract edges for inferred buffers
  #  - creates ALL DOT edges
  # ------------------------------------------------   
  TirGrammarMod::createDFG($func, 2);
  
  # ------------------------------------------------
  # Call GLOBAL scheduler
  #  - calculated function's black-box parameters
  # ------------------------------------------------   
  TirGrammarMod::globalScheduler($func);
  
  # ------------------------------------------------
  # Calculate resoure estimate for this function
  # ------------------------------------------------   
  Cost::costFunction($func);

  
  #------------------------------------------------
  # reset the global counters when a function is parsed, so that they can be 
  # reused for parsing next function
  # ------------------------------------------------
  $main::insCntr = 0; 
  $main::insCntrFcall = 0; 
  $main::funCntr = 0;
  $main::argSeq = 0;
  
}#actMAIN()

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCT_ARG{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $func  = $arg[0];
  my $name  = $item{ARG_NAME};
  my $dtype = $item{ARG_TYPE};
  my $dir   = 'null';    
  
  #NOTE/TODO:: This is a hack. I take data type of one argument and assume function data type is the same. This needs to change
  $main::CODE{$func}{synthDtype} = $dtype ; 

  # Entry in the symbol table:
    #if this an output argument, then the "consumes" would be filled later by 
      #the appropriate instruction which has this argument as operD
      #By default we treat this as an input argument... if it is recognized as an\
      #output argument then the "produces" entry will be removed...
  $main::CODE {$func} {symbols} {$name} {dfgnode} = $name;  
  $main::CODE {$func} {symbols} {$name} {cat}     = "arg";
  $main::CODE {$func} {symbols} {$name} {dtype}   = $dtype;
  #@{$main::CODE {$func} {symbols} {$name} {produces}}= ($name);
  @{$main::CODE {$func} {symbols} {$name} {produces}}= ($name);
  @{$main::CODE {$func} {symbols} {$name} {consumes}}= (); 
  $main::CODE {$func} {symbols} {$name} {dir}               = $dir;
  #$main::CODE {$func} {symbols} {$name} {streamtype}        = 'streamfifo';
  #$main::CODE {$func} {symbols} {$name} {memconn}           = 'arg';
  $main::CODE {$func} {symbols} {$name} {numOffsetStreams}  = 0;
  $main::CODE {$func} {symbols} {$name} {maxPosOffset}      = 0;
  $main::CODE {$func} {symbols} {$name} {maxNegOffset}      = 0;
  
  
  # Entry in the "arguments" table:
  $main::CODE {$func} {args} {$main::argSeq} {name}  = $name;
  $main::CODE {$func} {args} {$main::argSeq} {dtype} = $dtype;
  $main::CODE {$func} {args} {$main::argSeq} {dir}   = $dir;
    # direction will be filled when instructions are parsed
  $main::CODE {$func} {args} {$main::argSeq} {isOffsetStream} = 0;
   #initialize to 0. Will be updated to 1 if needed when parent function is parsed
  $main::argSeq++;

  # -------
  # Cost it
  # -------
  #NOTE: Can't cost it completely here as information is not complete (direction)  
  #So I am only going to initialize it
  my $hashref = $main::CODE{$func}{symbols}{$name}; 
  Cost::costInit($hashref);
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCT_DECLR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $func = $item{FUNC_NAME};
  
  $main::CODE{$func}{func_type}    = $item{FUNC_TYPE};
  $main::CODE{$func}{depth}   = 'flat'; #default
  #initialize number of inputs and outputs
  $main::CODE{$func}{ninputs} = 0;
  $main::CODE{$func}{noutputs} = 0;

}
 
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCTION{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
     # reduce clutter
  my $func = $item{FUNCT_DECLR};
  my $hash = $main::CODE{$func}; 
     
  print "TyBEC: Found function definition of $item{FUNCT_DECLR} \n"; 
  $hash->{funcName} = $item{FUNCT_DECLR}; 
    #having the name of function (i.e. the key) is useful later in code generation
    
  $hash->{instrCount} = $main::insCntr;
  $hash->{insCntrFcall} = $main::insCntrFcall;

  # ------------------------------------------------
  # Create DFG for this function 
  # (first pass, no DOT edges yet as buffers may be added)
  # but abstract-DFG requires edges for localScheduler to function
  # ------------------------------------------------   
  TirGrammarMod::createDFG($func, 1);

  # ------------------------------------------------
  # Calls local scheduler 
  #  - Schedules inside function
  #  - does not calculate global function parameters yet (edges to inferred buffers not added yet)
  #  - Also infer buffers (adds new nodes)
  # ------------------------------------------------   
  #(leaf kernels only for now)
  TirGrammarMod::localScheduler($func);# if($hash->{hierarchical} eq 'no');

  # ------------------------------------------------
  # Create DFG for this function 
  #  - second pass, adds new abstract edges for inferred buffers
  #  - creates ALL DOT edges
  # ------------------------------------------------   
  TirGrammarMod::createDFG($func, 2);
  
  # ------------------------------------------------
  # Call GLOBAL scheduler
  #  - calculated function's black-box parameters
  # ------------------------------------------------   
  TirGrammarMod::globalScheduler($func);
  
  # ------------------------------------------------
  # Calculate resoure estimate for this function
  # ------------------------------------------------   
  Cost::costFunction($func);
  
  # reset the main counters when a function is parsed, so that they can be 
  # reused for parsing next function
  $main::insCntr = 0; 
  $main::insCntrFcall = 0; 
  $main::funCntr = 0;
  $main::argSeq = 0;
}#actFUNCTION

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_AI_TYPE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{type} = $item{AUTOINDEX_TYPE};
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_AI_RANGE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{end}   = eval($item{EXPRESSION2});
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{start} = eval($item{EXPRESSION1});
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_AI_DIMNUM{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{dimNum}   = eval($item{EXPRESSION1});
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_AI_NESTUNDER{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{nestUnder}   = $item{LOCAL_VAR};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMD_AI_NESTOVER{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{nestOver}   = $item{LOCAL_VAR};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actAUTOINDEX{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
 
  my $func    = $arg[0];
  my $dtype   = $item{DATA_TYPE};
  my $name    = $item{LOCAL_VAR};
#  my $myoperD = $name;
  my $sstream = $item{LOCAL_VAR2};
#  my $type    = $item{DATA_TYPE};
  print "TyBEC: Found autoindex $name connected to  $sstream\n"; 
  
  my $myoptype  = $item{DATA_TYPE};
  (my $myoperDnameonly = $name) =~ s/(%|@)//;
  
  #symbol table entry 
  #------------------------
  $main::CODE  {$func}{symbols}{$name}{dfgnode}   = $name;    
  $main::CODE  {$func}{symbols}{$name}{cat}      = 'autoindex';
  $main::CODE  {$func}{symbols}{$name}{dtype}    = $dtype;
  @{$main::CODE{$func}{symbols}{$name}{produces}}= ($name);
  @{$main::CODE{$func}{symbols}{$name}{consumes}}= ();

  $main::CODE{$func}{symbols}{$name}{funcunit}  = 'autoindex';
  $main::CODE{$func}{symbols}{$name}{synthunit} = 'autoindex';
  $main::CODE{$func}{symbols}{$name}{synthDtype}= $myoptype; 
  $main::CODE{$func}{symbols}{$name}{sstream}   = $sstream; 

  # -------
  # Cost it
  # -------
  my $hashref = $main::CODE{$func}{symbols}{$name}; 
  #Cost::costComputeInstruction($func, $myoperD);
  Cost::costAutoIndex($func, $name);  

  
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actOFFSET_STREAM{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $func        = $arg[0];
  my $streamo     = $item{LOCAL_VAR};
  my $streamo_pre = $item{LOCAL_VAR}.".pre";
  my $streami     = $item{LOCAL_VAR2};
  my $dist        = eval($item{EXPRESSION});
  my $dir         = $item{PLUS_OR_MINUS};
  my $dtype       = $item{DATA_TYPE};
  
  #--------------------------------------------------------
  #Smache node
  #--------------------------------------------------------
  
  #before creating a node for the offset variable, we need to create SMACHE node
  #that creates the offset
  my $smachenode =$streami."_smache";
  $main::CODE{$func}{symbols}{$smachenode}{dfgnode}= $smachenode;
  $main::CODE{$func}{symbols}{$smachenode}{cat}    = 'smache';
  $main::CODE{$func}{symbols}{$smachenode}{dtype}  = $dtype;
  @{$main::CODE{$func}{symbols}{$smachenode}{consumes}} = ($streami);    
  push @{$main::CODE{$func}{symbols}{$smachenode}{produces}}, $streamo; 
    #following comment now obsolete
      #push @{$main::CODE{$func}{symbols}{$smachenode}{produces}}, $streamo_pre; 
      #we cannot use the actual offset for stream identifier here, as we
      #have a unqiue node for each offset value related to this source stream
      #(an offset variable in the IR is just like any other impscalar node, so it needs to be treated
      #no differently.
      #So, to uniquley identify the output(s) from a smache module, we add a "pre"
      #to the identifier we  used in the "produces" entry,
  $main::CODE{$func}{symbols}{$smachenode}{funcunit}  = 'smache';
  $main::CODE{$func}{symbols}{$smachenode}{synthunit} = 'smache';
  $main::CODE{$func}{symbols}{$smachenode}{synthDtype} = $dtype; 
  
  $main::CODE{$func}{symbols}{$smachenode}{offstreams}{$streamo} {dtype}  = $dtype;
  $main::CODE{$func}{symbols}{$smachenode}{offstreams}{$streamo} {dir}    = $dir;
  $main::CODE{$func}{symbols}{$smachenode}{offstreams}{$streamo} {dist}   = $dist;
    
  
  #This was redundant; no need to have nodes in the DFG for each offstream
  #The smache module should be treated as just another module with a latency
  #that emits multiple outputs. Otherwise we break the opaque uniformity of nodes
    #--------------------------------------------------------
    # offset stream node
    #--------------------------------------------------------
    # Entry in the symbol table for the created stream, which effectively is 
    # treated as just another impscalar. What it "consumes" is the 
    # "pre" stream created from the offset module.
    #$main::CODE   {$func} {symbols} {$streamo} {dfgnode}   = $streamo;    
    #$main::CODE   {$func} {symbols} {$streamo} {cat}       = 'offstream';
    #$main::CODE   {$func} {symbols} {$streamo} {dtype}     = $dtype;
    #@{$main::CODE {$func} {symbols} {$streamo} {produces}} = ($streamo);
    #@{$main::CODE {$func} {symbols} {$streamo} {consumes}} = ($streamo_pre);
    #$main::CODE   {$func} {symbols} {$streamo} {funcunit}  = 'offstream';
    #$main::CODE   {$func} {symbols} {$streamo} {synthunit} = 'offstream';
    #$main::CODE   {$func} {symbols} {$streamo} {synthDtype}= $dtype; 
  
  
  #entry in the source-stream's table, as well as the corresponding SPLIT object 
  #TODO: Should be redundant in the STREAMs entrys
  $main::CODE {$func} {symbols} {$streami} {offstreams} {$streamo} {dtype}  = $dtype;
  $main::CODE {$func} {symbols} {$streami} {offstreams} {$streamo} {dir}    = $dir;
  $main::CODE {$func} {symbols} {$streami} {offstreams} {$streamo} {dist}   = $dist;
  $main::CODE {$func} {symbols} {$streami} {numOffsetStreams} += 1;
  
  #update max POS/NEG streams for this source stream if applicable    
  if( $dir eq '+')
    {$main::CODE{$func}{symbols}{$streami}{maxPosOffset} =
      mymax( $dist, $main::CODE{$func}{symbols}{$streami}{maxPosOffset} );
     push @{$main::CODE{$func}{symbols}{$smachenode}{tapsAtPosDelays}} , $dist;
  }
  if( $dir eq '-')
    {$main::CODE{$func}{symbols}{$streami}{maxNegOffset} =
      mymax( $dist, $main::CODE{$func}{symbols}{$streami}{maxNegOffset} );
      push @{$main::CODE{$func}{symbols}{$smachenode}{tapsAtNegDelays}} , $dist;
  }

  #update the maxOffset in the smache node
  $main::CODE {$func} {symbols} {$smachenode} {maxPosOffset}
    = $main::CODE{$func}{symbols}{$streami}{maxPosOffset};
  $main::CODE {$func} {symbols} {$smachenode} {maxNegOffset}
    = $main::CODE{$func}{symbols}{$streami}{maxNegOffset};


  #--------------------------------------------------------
  # Costs
  #--------------------------------------------------------
  #The resource cost (buffer registers) and latency is counted
  #as part of the smache node
  #the offstream node is essentially a place holder, and any 
  #resource or latency cost associated with it would be double-counting
  
  # Cost/Schedule the new SMACHE node [or update if already there]
  # -------
  my $hashref = $main::CODE{$func}{symbols}{$smachenode}; 
  Cost::costSmache($func, $smachenode);  
    
  # Cost offstream node
  # ----------------------------------------
  # output offset streams no longer have their own nodes, so following is obsolete
    #$hashref = $main::CODE{$func}{symbols}{$streamo}; 
    #Cost::costOffsetStream($func, $streamo);  

  #  $main::CODE {$func} {symbols} {$smachenode} {maxPosOffset} {$streamo} {dtype}  
#    = $main::CODE{$func}{symbols}{$streami}{maxPosOffset};
#  $main::CODE {$func} {symbols} {$smachenode} {maxNegOffset} {$streamo} {dir}    
#    = $main::CODE{$func}{symbols}{$streami}{maxNegOffset}
    
}  


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCALLED_FUNCT_ARG{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $caller = $arg[0];
  my $callee = $arg[1]."_".$main::funCntr;
  
  $main::CODE {$caller} {symbols} 
              {$callee} 
              {args2child} {$main::argSeq2} {name} 
                = $item{ARG_NAME};

  $main::CODE {$caller} {symbols} 
              {$callee} 
              {args2child} {$main::argSeq2} {type} 
                = $item{ARG_TYPE};

  # pick up direction of called argument from 
  # hash entry for child function <<<<--- NOTE REQUIRES CHILD DEFINITION TO APPEAR FIRST IN CODE
  # matching to child argument is done by position (not name!)
  $main::CODE {$caller} {symbols} 
              {$callee} 
              {args2child} {$main::argSeq2} {dir} 
                = $main::CODE{$arg[1]}{args}{$main::argSeq2}{dir};


  # if direction of port is output, then it means this is the destination operand
  # ONLY RELEVANT for comb functions which have only one output by definition
  # (pipe functions can have multiple outputs)
  # TODO/NOTE: This was giving warning (unitialized value). Not sure if it is serving any 
  # purpose anymore, I am commenting it out...
  #if ($main::CODE{$caller}{args}{$main::argSeq2}{dir} eq 'output') {
  #  $main::CODE{$caller}{instructions}{$callee}{operD} =  $item{ARG_NAME}; }
    

  # pick up name of port in child to which this port is connected
  $main::CODE {$caller} {symbols} 
              {$callee} 
              {args2child} {$main::argSeq2} {nameChildPort} 
                = $main::CODE{$arg[1]}{args}{$main::argSeq2}{name};
   # ----------------------------------------
   # WHERE APPLICABLE
   # Set port directions for caller function
   # based on Called function port directions
   # ----------------------------------------
   #iterate through all arguments of the caller function, 
   #and check if it matches any argument of called function
   #if so, set direction of parent port based on dir of child port
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} )
   {
     # first confirm if port direction (parent) has not already been assigned
     if ($main::CODE{$caller}{args}{$key}{dir} eq 'null') 
     {
       my $childPortDirection = $main::CODE{$arg[1]}{args}{$main::argSeq2}{dir};
       #if argument to child function matches an argument of parent function
       #then pick up direction from child function signature, and assign to parent's
       if ($item{ARG_NAME} eq $main::CODE{$arg[0]}{args}{$key}{name})
       { 
          $main::CODE{$caller}{args}{$key}{dir} = $childPortDirection;
          $main::CODE{$caller}{symbols}{$item{ARG_NAME}}{dir} = $childPortDirection;
       
          #Symbol table update: the produces/consumes caller for this callee
          #-----------------------------------------------------------------
          if ($childPortDirection eq 'input') {
          #  push @{$main::CODE{$caller}{symbols}{$item{ARG_NAME}}{produces}}, $item{ARG_NAME};
            ##NOTE: The above was causing duplication in the edges as the "produces" entry was already fixed by actFUNCT_ARG
          }
          else {
            push @{$main::CODE{$caller}{symbols}{$item{ARG_NAME}}{consumes}}, $item{ARG_NAME};
          }
       }#if
     }
   }

   $main::argSeq2++;
}#CALLED_FUNCT_ARG:
 
 
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------

sub actFUNC_CALL_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $caller   =  $arg[0];
  my $callee   =  $item{CALLEE_FUNC_NAME};
  my $calleeWC =  $callee."_".$main::funCntr;#callee with function counter appended (this is how it appears in the "instructions" and "symbols" hash
  
  #identify parent function as a hierarchical function
  #$main::CODE {$caller} {hierarchical} = 'yes'; 
  $main::CODE {$caller} {depth} = 'hier'; 

  # Entry in the symbol table:
  $main::CODE {$caller} {symbols} {$calleeWC} {dfgnode}   = $calleeWC;    
  $main::CODE {$caller} {symbols} {$calleeWC} {cat}       = "funcall";
#  @{$main::CODE {$func} {symbols} {$mystream} {produces}}= ($mystream);
#  @{$main::CODE {$func} {symbols} {$mystream} {consumes}}= ($mymem);
 
  #function call can have both multiple producers and consumers. So loop through
  #all the arguments passed to this function call to fill up these arrays
  foreach my $key (keys %{$main::CODE{$caller}{symbols}{$calleeWC}{args2child}}) {    
    my $argName = $main::CODE{$caller}{symbols}{$calleeWC}{args2child}{$key}{name};
    #if the argument is an input TO the callee, then it CONSUMES that passed symbol
    if($main::CODE{$caller}{symbols}{$calleeWC}{args2child}{$key}{dir} eq 'input') {
      push @{$main::CODE{$caller}{symbols}{$calleeWC}{consumes}}, $argName;

      # ----------------------------------------
      # Set port directions for caller function
      # ----------------------------------------
      #also, we need to see if the parent functions argument direction needs to be set based
      #on this one (and also its "consumes" entry in the symbol table
      #print "::actFUNC_CALL_INSTR:: set arg direction for $caller  and $calleeWC and oper1 = $argName \n" 
      #  if ($caller eq 'kernelTop');
      TirGrammarMod::setArgDir($caller,'null', $argName, 'null');      
    }
    else {
      push @{$main::CODE{$caller}{symbols}{$calleeWC}{produces}}, $argName;
      # ----------------------------------------
      # Set port directions for caller function
      # ----------------------------------------
      #also, we need to see if the parent functions argument direction needs to be set based
      #on this one (and also its "consumes" entry in the symbol table
      TirGrammarMod::setArgDir($caller, $argName, 'null', 'null');      
    }
  }
  
   #entry in main token tree
   $main::CODE{$caller}{symbols}{$calleeWC}{instrType}        ='funcCall';
   $main::CODE{$caller}{symbols}{$calleeWC}{instrSequence}    =  $main::insCntr;
   $main::CODE{$caller}{symbols}{$calleeWC}{funcType}         = $item{FUNC_TYPE};
   $main::CODE{$caller}{symbols}{$calleeWC}{funcName}         = $callee;
   $main::CODE{$caller}{symbols}{$calleeWC}{funcRepeatCounter}= $main::funCntr;
   
   print "TyBEC: $item{CALLEE_FUNC_NAME} called by $arg[0]\n";

   # reset counter that was sequencing
   # the position of argumetns in called function
   $main::argSeq2 = 0;

  # -------------------------------------------------------------
  # When CALLER is MAIN
  # CHECK if argument passed to child is an OFFSET STREAM
  # Also set the top kernel
  # -------------------------------------------------------------
  # check arguments passed to function called (which would be the
  # top level pipe
  # compare then with local offsetStreams created in Main
  # if any match, then go to hash of child function, and 
  # update the argument property of the relevant argument
  # to indicate that the argument is an offsetStream stream (not to be generated for LMEM i.e.)
  
  my $childCall = "$item{CALLEE_FUNC_NAME}"."_0"; #reduce clutter. this is e.g. funcName_0 in the main
  (my $childFunc = $childCall) =~ s/\.\d+//; #extract function name from function-call hash 
   
  if($arg[0] eq 'main') {
    #We allow STRICTLY 1 child function in the MAIN. While that is not tested here, that is
    #assumed. If multiple kernels are called, the behaviour is undefined
    $main::CODE{main}{topKernelName} = $childFunc;
    print "The top kernel called from Main is  = $childFunc\n";
  
    #go the 0th function call of child function (which is the only on main as per allowed syntax
    #and iterate through the arguments passed to it
    foreach my $key (keys %{$main::CODE{main}{symbols}{$childCall}{args2child}} ) {
      #now iterate through each offset stream, and compare against each argument
      foreach my $key2 (keys %{$main::CODE{main}{offsetStreams}} ) {
        #compare argument to child, against offstream variable, and enter if found
        if ($main::CODE{main}{symbols}{$childCall}{args2child}{$key}{name} eq $key2) {

          #get the name of port in child Function
          my $childPort = $main::CODE{main}{symbols}{$childCall}{args2child}{$key}{nameChildPort};
          
          #go the hash of child function, and set the argument property 
          #accordingly for this argument/port in the child's hash
          #as args in child hash function are keyed by sequence (rather than by name)
          #so we will have to loop through the entire args hash to find the right childPort
          foreach my $key3 (keys %{$main::CODE{$childFunc}{args}} ) {
            if ($main::CODE{$childFunc}{args}{$key3}{name} eq $childPort) {
              $main::CODE{$childFunc}{args}{$key3}{isOffsetStream} = 1;
              $main::CODE{$childFunc}{args}{$key3}{offsetStreamNameInMain} = $key2;
              $main::CODE{$childFunc}{args}{$key3}{offsetSourceStream} = $main::CODE{main}{offsetStreams}{$key2}{sourceStream};
            }#if
          }#foreach
        }#if
      }#foreach 
    }#foreach
    
  }#if($arg[0] eq 'main') {

  # -------
  # Cost it
  # -------
  my $hashref = $main::CODE{$caller}{symbols}{$calleeWC};
  Cost::costInit($hashref); #initialization is needed because of the way I update the xnode title on the DFG-dot
  #Cost::costFuncCallInstruction($hashref,$caller);
  Cost::costFuncCallInstruction($caller, $calleeWC);

# ------------------------------------------
# Calculate cost of instruction 
# ------------------------------------------
# pick up the cost of function call instruction from the
# calculated cost of called (child) function
#   $main::CODE{$arg[0]}{symbols}{$item{CALLEE_FUNC_NAME}.".".$main::funCntr}{resource}
#     = { 'ALMS'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{ALMS}       
#       , 'ALUTS'     => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{ALUTS}      
#       , 'REGS'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{REGS}       
#       , 'M20Kbits'  => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{M20Kbits}   
#       , 'MLABbits'  => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{MLABbits}   
#       , 'DSPs'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{DSPs}       
#       , 'Latency'   => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{Latency}    
#       , 'PropDelay' => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{PropDelay}  
#       , 'CPI'       => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{CPI}        
#       };

   # ------------------------------------------
   # increment required counters over detection of a valid
   # function call instruction
   # ------------------------------------------
   $main::funCntr++;
   $main::insCntr++;
   $main::insCntrFcall++;
 }#FUNC_CALL_INSTR


# ----------------------------------------------------------------------------
sub actMD_REDUCTION_SIZE {
# ----------------------------------------------------------------------------
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};  
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{reductionSize} = eval($item{EXPRESSION});
  $main::CODE{$arg[1]}{symbols}{$arg[0]}{reductionOp}   = 'yes';
}



 
# ----------------------------------------------------------------------------
sub actPRIMITIVE_INSTRUCTION{
# ----------------------------------------------------------------------------
  my $instType  = shift(@_); #[compute/compare]
  my @item      = @{shift(@_)};
  my %item      = %{shift(@_)};
  my @arg       = @{shift(@_)};
  
#  print YELLOW; print "TyBEC: Primitive instruction  with operD = $item{OPER_DEST}\n"; print RESET;
#  print "arg[0] = $arg[0]\n";

  my $func    = $arg[0];
  my $myoperD   = $item{OPER_DEST};
 
  my $myoper1     = $item{OPER1};
  my $myoper2;
  my $myoper3;
  
  $myoper2 = $item{OPER2} if ($instType ne 'load'); #load has 1 source operand
  $myoper3 = $item{OPER3} if($instType eq 'select'); #select has 3 source operands
  
## ----------------------------------------
#if ($instType eq 'compute') {
## ----------------------------------------

  ## Operation type ##
  my $myop;
  $myop = $item{OP}       if($instType eq 'compute');
  $myop = $item{OP_ONEOP} if($instType eq 'compute1op');
  $myop = 'compare'       if($instType eq 'compare');
  $myop = 'select'        if($instType eq 'select');
  $myop = 'load'          if($instType eq 'load');
  
  # Error checks for select
  if (  ($instType eq 'select')
     && ($item{OP_TYPE2} ne $item{OP_TYPE3})
     )
    {die "TyBEC **ERROR**: Type of operands compared in a select instruction must be same";}  
    
  my $myoptype;
  if($instType eq 'select') {$myoptype = $item{OP_TYPE2};}
  else                      {$myoptype = $item{OP_TYPE}; }

  (my $myoperDnameonly = $myoperD) =~ s/(%|@)//;
  
  # ----------------------------------------
  # Symbol table entry
  # ----------------------------------------
  #symbol table entry: check if the symbol does not already exist (as arg)
  if(!exists($main::CODE{$func}{symbols}{$myoperD}) ) {
    $main::CODE {$func} {symbols} {$myoperD}  {dfgnode}   = $myoperD;    
    $main::CODE {$func} {symbols} {$myoperD}  {cat}       = "impscal";
    $main::CODE {$func} {symbols} {$myoperD}  {dtype}     = $item{DEST_TYPE};
    @{$main::CODE{$func}{symbols} {$myoperD}  {produces}} = ($myoperD);
  }
  else {
  }
  
    
  #What function is this, and what unit should be synthesized for it?
  $main::CODE{$func}{symbols}{$myoperD}{funcunit}  = $myop;
  $main::CODE{$func}{symbols}{$myoperD}{synthunit} = $myop;
  #data type of synth unit? (if we include optimizations, this may not be same as myoptype)
  $main::CODE{$func}{symbols}{$myoperD}{synthDtype} = $myoptype; 
   
  # Set port directions for caller function
  # ----------------------------------------
  if($instType eq 'select') 
    {TirGrammarMod::setArgDir($func, $myoperD, $myoper1, $myoper2, $myoper3);}
  elsif(($instType eq 'load') || ($instType eq 'compute1op'))
    {TirGrammarMod::setArgDir($func, $myoperD, $myoper1, 'null');}
  else                      
    {TirGrammarMod::setArgDir($func, $myoperD, $myoper1, $myoper2);}
    #this function will also change the {cat} parameter (to func-arg) if required 


  # --------------------------------------------------------
  # Check 'form' of input operations (constant, argument, local)
  # --------------------------------------------------------

  # Check if any input operand is a direct port connection
  # --------------------------------------------------------
  # this information is later needed for code generation
  
  #iterate through all arguments of the caller function, and check
  #if it matches operand 1
  my ($oper1form,  $oper2form, $oper3form);
  foreach my $key ( keys %{$main::CODE{$func}{args}} ) {
   if ($main::CODE{$func}{args}{$key}{name} eq $myoper1) {
     $oper1form = 'inPort';
   }#if
   #if the property oper1form does not exist, it means it can safely be defined is
   #local type, as we are sure no previous iteration has detected as inPort already
   elsif (!(exists $main::CODE{$func}{symbols}{$myoperD}{oper1form})) {
     $oper1form = 'local';
   }
   $main::CODE{$func}{symbols}{$myoperD}{oper1form} = $oper1form;
  }#foreach
  
  #same for operand 2
  #if load instruction, give the same form to oper2 as oper1
  #as there IS no oper2 (and it is cleaner in the costing module to have both values present anyway)
  if (($instType eq 'load') || ($instType eq 'compute1op')) {
    $main::CODE{$func}{symbols}{$myoperD}{oper2form} = $oper1form;
  }
  else {
    foreach my $key ( keys %{$main::CODE{$func}{args}} ) {
    if ($main::CODE{$func}{args}{$key}{name} eq $myoper2) {
      $oper2form = 'inPort';
    }#if
    elsif (!(exists $main::CODE{$func}{symbols}{$myoperD}{oper2form})) {
      $oper2form = 'local';
    }
    $main::CODE{$func}{symbols}{$myoperD}{oper2form} = $oper2form;
    }#foreach
  }

  #same for operand 3 if applicable
  if($instType eq 'select'){
    foreach my $key ( keys %{$main::CODE{$func}{args}} ) {
    if ($main::CODE{$func}{args}{$key}{name} eq $myoper3) {
      $oper3form = 'inPort';
    }#if
    elsif (!(exists $main::CODE{$func}{symbols}{$myoperD}{oper3form})) {
      $oper3form = 'local';
    }
    $main::CODE{$func}{symbols}{$myoperD}{oper3form} = $oper3form;
    }#foreach
  }
  
  # Check if any of the operands is constant (immediate operand)
  # --------------------------------------------------------
  if (($myoper1 =~ /^-?\d+$/) || ($myoper1 =~ /^-?\d+\.?\d*$/)) {
    $oper1form = 'constant';
    $main::CODE{$func}{symbols}{$myoperD}{oper1val}  = $myoper1;
  }
  if (($instType ne 'load') && ($instType ne 'compute1op')) {
    if (($myoper2 =~ /^-?\d+$/) || ($myoper2 =~ /^-?\d+\.?\d*$/)) {
      $oper2form = 'constant';
      $main::CODE{$func}{symbols}{$myoperD}{oper2val}  = $myoper2;
    }
  }
  if($instType eq 'select'){
    if (($myoper3 =~ /^-?\d+$/) || ($myoper3 =~ /^-?\d+\.?\d*$/)) {
      $oper3form = 'constant';
      $main::CODE{$func}{symbols}{$myoperD}{oper3val}  = $myoper3;
    }
  }
  
  #now update in hash (earlier stored in local vars)
  $main::CODE{$func}{symbols}{$myoperD}{oper1form} = $oper1form;
  $main::CODE{$func}{symbols}{$myoperD}{oper2form} = $oper2form if (($instType ne 'load') && ($instType ne 'compute1op'));
  $main::CODE{$func}{symbols}{$myoperD}{oper3form} = $oper3form if($instType eq 'select');
  
  #update CONSUMES
  #-----------------
  #The "consumes" entry has to be made as even if the entry was already there due
  #to operD being an argument, there would be no entry for "consumes"
  #Also, if operand type is CONSTANT, do not make CONSUMES entry as it messes up the DFG and code-gen
  
  
  #all instructions have one operand
  push @{$main::CODE{$func}{symbols}{$myoperD}{consumes}}, $myoper1 
    if ($oper1form ne 'constant');
    
  #all but LOAD have 2 operands  
  push @{$main::CODE{$func}{symbols}{$myoperD}{consumes}}, $myoper2
    if (($instType ne 'load') && ($instType ne 'compute1op') && ($oper2form ne 'constant'));

  #only SELECT has 3 operands
  push @{$main::CODE{$func}{symbols}{$myoperD}{consumes}}, $myoper3
    if (($instType eq 'select') && ($oper3form ne 'constant'));
  
#  if($instType eq 'load'){
#    @{$main::CODE {$func} {symbols} {$myoperD} {consumes}}= ($myoper1) if ($oper1form ne 'constant');
#  } 
#  else {
#    #(at least) two operand instructions
#    @{$main::CODE {$func} {symbols} {$myoperD} {consumes}}= ($myoper1, $myoper2) 
#      if (($oper1form ne 'constant') && ($oper2form ne 'constant'));
#    #this instruction has 3rd operand  
#    push @{$main::CODE{$func}{symbols}{$myoperD}{consumes}}, $myoper3
#      if(($instType eq 'select') && ($oper3form ne 'constant'));
#  }

  
  # -------
  # Cost it
  # -------
  my $hashref = $main::CODE{$func}{symbols}{$myoperD}; 
  #Cost::costComputeInstruction($func, $myoperD);
  Cost::costPrimitiveInstruction($func, $myoperD);   #<==========
  #Cost::costComputeInstruction($hashref, $func, $myoperD);
#  }#if ($instType eq 'compute') 
#  
## ----------------------------------------
#elsif ($instType eq 'compare') {
## ----------------------------------------  
#
#  }#elsif ($instType eq 'compare') 
  $main::glComputeInstCntr++;

}#()


# ----------------------------------------------------------------------------
#  OBSOLETE: handled in actPRIMITIVE_INSTRUCTION
# ----------------------------------------------------------------------------
sub actASSIGN_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
 
  my $func  = $arg[0];
  my $myoperD = $item{OPER_DEST};
  my $myoper1 = $item{OPER1};
 
  #symbol table entry: check if the symbol does not already exist (as arg)
  if(!exists($main::CODE{$arg[0]}{"symbols"}{$item{OPER_DEST}}) ) {
    $main::CODE {$func} {symbols} {$myoperD} {dfgnode}      = $myoperD;    
    $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {cat}  = "impscal";
    $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {dtype}= $item{DEST_TYPE};
    @{$main::CODE {$func} {"symbols"} {$myoperD} {produces}}= ($myoperD);
  }
  #The "consumes" entry has to be made as even if the entry was already there due
  #to operD being an argument, there would be no entry for "consumes"
  @{$main::CODE {$func} {"symbols"} {$myoperD} {consumes}}= ($item{OPER1});
  
  #main entry
  $main::CODE {$arg[0]} {"instructions"} { $item{OPER_DEST} }
    = { 'destType'  => $item{DEST_TYPE}
      , 'oper1'     => $item{OPER1}
      , 'opType'    => $item{OP_TYPE}
      ,  'operD'    => $item{OPER_DEST}
      , 'op'        => "assign"
      , 'instrType' => "assign"
      };

  $main::insCntr++;
  print "TyBEC: Assign instruction found in $arg[0]\n";
  
  # ----------------------------------------
  # Set port directions for caller function
  # ----------------------------------------
  TirGrammarMod::setArgDir($func, $myoperD, $myoper1, 'null');
}
 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actSELECT_INSTR{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   my $func  = $arg[0];
##   my $myoperD = $item{OPER_DEST};
##   my $myoper1 = $item{PRED_OPER};
##   my $myoper2 = $item{TRUE_OPER};
##   my $myoper3 = $item{FALSE_OPER};
##   
##    if ($item{OP_TYPE2} ne $item{OP_TYPE3})
##      {die "TyBEC **ERROR**: Type of operands compared in a select instruction must be same";}
## 
##   #symbol table entry: check if the symbol does not already exist (as arg)
##   if(!exists($main::CODE{$arg[0]}{"symbols"}{$item{OPER_DEST}}) ) {
##     $main::CODE {$func}     {symbols} {$myoperD} {dfgnode}    = $myoperD;    
##     $main::CODE {$func}   {symbols} {$myoperD} {cat}        = "impscal";
##     $main::CODE {$func}   {symbols} {$myoperD} {dtype}      = $item{DEST_TYPE};
##     @{$main::CODE {$func} {symbols} {$myoperD} {produces}}  = ($myoperD);    
##   }
##   #The "consumes" entry has to be made as even if the entry was already there due
##   #to operD being an argument, there would be no entry for "consumes"
##   @{$main::CODE {$func}{symbols}{$myoperD}{consumes}}= ($item{PRED_OPER}, $item{TRUE_OPER}, $item{FALSE_OPER});
##   
##   #main entry     
##    $main::CODE {$arg[0]} {instructions} {$item{OPER_DEST}} 
##      =  {  'destType'     => $item{DEST_TYPE}
##         ,  'operPred'     => $item{PRED_OPER}
##         ,  'operTrue'     => $item{TRUE_OPER}
##         ,  'operFalse'    => $item{FALSE_OPER}
##         ,  'op'           => $item{OP_SELECT}
##         ,  'operD'        => $item{OPER_DEST}
##         ,  'opType'       => $item{OP_TYPE1}
##         ,  'instrType'    => "select"
##         ,  'instrSequence'=> $main::insCntr  
##         };
## 
##    $main::insCntr++;
##    print "TyBEC: Select instruction found in $arg[0]\n";      
## 
##    #dfgraph entry
##    #TirGrammarMod::addGraphNode($func.".".$myoperD
##    #                           ,"$func.".".$myoperD"
##    #                           );
##    # ----------------------------------------
##    # Set port directions for caller function
##    # ----------------------------------------
##    TirGrammarMod::setArgDir($func, $myoperD, $myoper1, $myoper2, $myoper3);
##    
##    # ------------------------------------------
##    # Calculate cost of instruction 
##    # ------------------------------------------
##    $main::CODE{$arg[0]}{instructions}{$item{OPER_DEST}}{cost}     
##      = { 'ALMS'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{ALMS}          
##        , 'ALUTS'     => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{ALUTS}    
##        , 'REGS'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{REGS}     
##        , 'M20Kbits'  => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{M20Kbits} 
##        , 'MLABbits'  => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{MLABbits} 
##        , 'DSPs'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{DSPs}     
##        , 'Latency'   => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{Latency}  
##        , 'PropDelay' => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{PropDelay}
##        , 'CPI'       => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{CPI}      
##        }; 
##  }

## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actCOMPARE_INSTR{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
## 
##   my $func  = $arg[0];
##   my $myoperD = $item{OPER_DEST};
##   my $myoper1 = $item{OPER1};
##   my $myoper2 = $item{OPER2};
##   
##   #symbol table entry: check if the symbol does not already exist (as arg)
##   if(!exists($main::CODE{$arg[0]}{"symbols"}{$item{OPER_DEST}}) ) {
##     $main::CODE {$func}     {symbols} {$myoperD} {dfgnode}      = $myoperD;    
##     $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {cat}  = "impscal";
##     $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {dtype}= $item{DEST_TYPE};
##     @{$main::CODE {$func} {"symbols"} {$myoperD} {produces}}= ($myoperD);
## }
##   #The "consumes" entry has to be made as even if the entry was already there due
##   #to operD being an argument, there would be no entry for "consumes"
##   @{$main::CODE {$func} {"symbols"} {$myoperD} {consumes}}= ($item{OPER1}, $item{OPER2});
##  
## 
##  
##   #main entry
##    $main::CODE {$arg[0]} {instructions} {$item{OPER_DEST}} 
##      =  {  'destType'     => $item{DEST_TYPE}
##         ,  'oper1'        => $item{OPER1}
##         ,  'oper2'        => $item{OPER2}
##         ,  'op'           => $item{OP_COMPARE}
##         ,  'opType'       => $item{OP_TYPE}
##         ,  'operD'        => $item{OPER_DEST}        
##         ,  'instrType'    => "compare"
##         ,  'instrSequence'=> $main::insCntr  
##         };
## 
##    $main::insCntr++;
##    print "TyBEC: Compare instruction found in $arg[0]\n";  
## 
##    #dfgraph entry
##    #TirGrammarMod::addGraphNode($func.".".$myoperD
##    #                           ,"$func.".".$myoperD"
##    #                           );
##   
##    # ----------------------------------------
##    # Set port directions for caller function
##    # ----------------------------------------
##    TirGrammarMod::setArgDir($func, $myoperD, $myoper1, $myoper2);
##   
##    
##    # ------------------------------------------
##    # Calculate cost of instruction 
##    # ------------------------------------------
##    $main::CODE{$arg[0]}{instructions}{$item{OPER_DEST}}{cost} = 
##    {'ALMS'=> $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{ALMS}          
##    , 'ALUTS'    => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{ALUTS}    
##    , 'REGS'     => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{REGS}     
##    , 'M20Kbits' => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{M20Kbits} 
##    , 'MLABbits' => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{MLABbits} 
##    , 'DSPs'     => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{DSPs}     
##    , 'Latency'  => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{Latency}  
##    , 'PropDelay'=> $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{PropDelay}
##    , 'CPI'      => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{CPI}      
##    }; 
## 
##  }

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
#sub actREDUX_INSTR{
#  my @item = @{shift(@_)};
#  my %item = %{shift(@_)};
#  my @arg  = @{shift(@_)};
#
#  my $func  = $arg[0];
#  my $myoperD = $item{GLOBAL_VAR};
#  
#  #symbol table entry: check if the symbol does not already exist (as arg)
#  if(!exists($main::CODE{$arg[0]}{"symbols"}{$item{GLOBAL_VAR}}) ) {
#    $main::CODE {$func}     {symbols} {$myoperD} {dfgnode}      = $myoperD;    
#    $main::CODE {$arg[0]} {"symbols"} {$item{GLOBAL_VAR}} {cat}  = "impscal";
#    $main::CODE {$arg[0]} {"symbols"} {$item{GLOBAL_VAR}} {dtype}= $item{DEST_TYPE};
#    @{$main::CODE {$func} {"symbols"} {$myoperD} {produces}}= ($myoperD);    
#  }
#  #The "consumes" entry has to be made as even if the entry was already there due
#  #to operD being an argument, there would be no entry for "consumes"
#  @{$main::CODE {$func} {"symbols"} {$myoperD} {consumes}}= ($item{OPER1}, $item{OPER2});
#  
#  #main entry
#   $main::CODE {$arg[0]} {instructions} {$item{GLOBAL_VAR}} 
#     =  {  'destType'     => $item{DEST_TYPE}
#        ,  'oper1'        => $item{OPER1}
#        ,  'oper2'        => $item{OPER2}
#        ,  'operD'        => $item{GLOBAL_VAR}
#        ,  'op'           => $item{OP}
#        ,  'opType'       => $item{OP_TYPE}
#        ,  'instrType'    => "reduction"
#        ,  'instrSequence'=> $main::insCntr  
#        };
#        # the parExecInstWise is 0 by default 
#   
#   #since this is reduction instruction, so one of the operands is the same as the 
#   #destination. Check which one, and add keys to identify this distinction
#   #as later needed in code generation
#   
#   $main::insCntr++;
#   print "TyBEC: Reduction instruction found in $arg[0]\n";
#   
#    #since this is reduction instruction, so one of the operands is the same as the 
#    #destination. Check which one, and add keys to identify this distinction
#    #as later needed in code generation
#    #we need to keep track of which operand is NOT the accumulator, as the other
#    #is identified by the dest operand anyway
#    if($item{GLOBAL_VAR} eq $item{OPER1}) {
#      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{operNotAcc} =  $item{OPER2}; }
#    elsif($item{GLOBAL_VAR} eq $item{OPER2}) {
#      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{operNotAcc} =  $item{OPER1}; }
#    #at least one oper should match operD. Othewise this is not a legal REDUX  instruction
#    else
#      {die "TyBEC-ERROR: If destination is global variable, this is considered a REDUCTION/ACCUMULATION operation, and that means one of the source operands must be the same as the destination operand\n";}
#    
##
##   # ----------------------------------------
##   # Set port directions for caller function
##   # ----------------------------------------
##   #iterate through all arguments of the caller function, and check
##   #if it should be set to output or input based on if it matches a LHS operand
##   #and set their direction
##   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} )
##   {
##     # first check tp confirm if the argument has not already been set by a previous
##     # parse over another instruction. 
##     if ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'null') 
##     {
##       # if argument matches destination operand of this instruction
##       if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{GLOBAL_VAR})
##         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'output';}
##       # if argument matches a source operand of this instruction
##       elsif (   ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) 
##             ||  ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) )
##         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'input';}
##       else
##         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'null';}
##     }
##   }
##   
##   # --------------------------------------------------------
##   # Check if any input operand is a direct port connection 
##   # --------------------------------------------------------
##   # this information is later needed for code generation
##   
##   #iterate through all arguments of the caller function, and check
##   #if it matches operand 1 (only relevant for input ports)
##   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
##    if (  ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) 
##       && ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'input')        ){
##      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form} = 'inPort';
##    }#if
##    #if the property oper1form does not exist, it means it can safely be defined is
##    #local type, as we are sure no previous iteration has detected as inPort already
##    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form})) {
##      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form} = 'local';
##    }
##   }#foreach
##   
##   #same for operand 2
##   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
##    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) {
##      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form} = 'inPort';
##    }#if
##    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form})) {
##      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form} = 'local';
##    }
##   }#foreach
##   
##   # --------------------------------------------------------
##   # Check if any input operand is an offset Stream
##   # --------------------------------------------------------
##   # this information may be  needed for code generation
##   # TODO...
##   
##   # ------------------------------------------
##   # Calculate cost of instruction 
##   # ------------------------------------------
##   # call sub-routine in Cost package; pass it: type, addrspace, size in words
##   # TODO: The Macro needs to be translated into value here... SO DO SECOND PASS FIRST!
##   #$main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{cost}
##   #          = Cost::costComputeInstruction($item{OP_TYPE}, $item{OP}); 
##             
##   $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{cost}
##             = Cost::costComputeInstruction(
##                $item{OP_TYPE}
##              , $item{OP}
##              , $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form}
##              , $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form}
##             );              
## }#REDUX INSTRUCTION

 

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
##sub actCOMPUTE_INSTR{
##  my @item = @{shift(@_)};
##  my %item = %{shift(@_)};
##  my @arg  = @{shift(@_)};
##  
##  my $func  = $arg[0];
##  my $myoperD = $item{LOCAL_VAR};
##  my $myoper1 = $item{OPER1};
##  my $myoper2 = $item{OPER2};
##  
##  
##  (my $myoperDnameonly = $myoperD) =~ s/(%|@)//;
##  
##  #symbol table entry: check if the symbol does not already exist (as arg)
##  if(!exists($main::CODE{$func}{symbols}{$myoperD}) ) {
##    $main::CODE {$func} {symbols} {$myoperD}  {dfgnode}   = $myoperD;    
##    $main::CODE {$func} {symbols} {$myoperD}  {cat}       = "impscal";
##    $main::CODE {$func} {symbols} {$myoperD}  {dtype}     = $item{DEST_TYPE};
##    @{$main::CODE{$func}{symbols} {$myoperD}  {produces}} = ($myoperD);
##  }
##  #The "consumes" entry has to be made as even if the entry was already there due
##  #to operD being an argument, there would be no entry for "consumes"
##  @{$main::CODE {$func} {"symbols"} {$myoperD} {consumes}}= ($item{OPER1}, $item{OPER2});
##  
##  #print "numbers = @numbers\n";
##  
##   print "TyBEC: Compute instruction found in $func\n";
##  
##  #main entry
##  $main::CODE {$arg[0]} {instructions} {$item{LOCAL_VAR}} 
##     =  {  'destType'     => $item{DEST_TYPE}
##        ,  'oper1'        => $item{OPER1}
##        ,  'oper2'        => $item{OPER2}
##        ,  'operD'        => $item{LOCAL_VAR}
##        ,  'op'           => $item{OP}
##        ,  'opType'       => $item{OP_TYPE}
##        ,  'instrType'    => "compute"
##        ,  'instrSequence'=> $main::insCntr  
##        };
##        # the parExecInstWise is 0 by default 
##
##        
##   $main::insCntr++;
##   $main::glComputeInstCntr++;
##   
##   # ----------------------------------------
##   # Set port directions for caller function
##   # ----------------------------------------
##   TirGrammarMod::setArgDir($func, $myoperD, $myoper1, $myoper2);
##   
##   # --------------------------------------------------------
##   # Check if any input operand is a direct port connection
##   # --------------------------------------------------------
##   # this information is later needed for code generation
##   
##   #iterate through all arguments of the caller function, and check
##   #if it matches operand 1
##   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
##    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) {
##      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'inPort';
##    }#if
##    #if the property oper1form does not exist, it means it can safely be defined is
##    #local type, as we are sure no previous iteration has detected as inPort already
##    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form})) {
##      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'local';
##    }
##   }#foreach
##   
##   #same for operand 2
##   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
##    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) {
##      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'inPort';
##    }#if
##    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form})) {
##      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'local';
##    }
##   }#foreach
##   
##   # --------------------------------------------------------
##   # Check if any of the operands is constant
##   # --------------------------------------------------------
##   if ($item{OPER1} =~ /^-?\d+$/) {
##     $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'constant';
##   }
##   if ($item{OPER2} =~ /^-?\d+$/) {
##     $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'constant';
##   }
##
##   # --------------------------------------------------------
##   # Check if any input operand is an offset Stream
##   # --------------------------------------------------------
##   # this information may be  needed for code generation
##   # TODO...
##   
##   # ------------------------------------------
##   # Calculate cost of instruction 
##   # ------------------------------------------
##   # call sub-routine in Cost package; pass it: type, addrspace, size in words
##   # TODO: The Macro needs to be translated into value here... SO DO SECOND PASS FIRST!
##   $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{cost}
##             = Cost::costComputeInstruction(
##                $item{OP_TYPE}
##              , $item{OP}
##              , $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form}
##              , $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form}
##             ); 
## }#COMPUTE_INSTR

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
## sub actASSIGN_INSTR{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##  
##   my $func  = $arg[0];
##   my $myoperD = $item{OPER_DEST};
##   my $myoper1 = $item{OPER1};
##  
##   #symbol table entry: check if the symbol does not already exist (as arg)
##   if(!exists($main::CODE{$arg[0]}{"symbols"}{$item{OPER_DEST}}) ) {
##     $main::CODE {$func} {symbols} {$myoperD} {dfgnode}      = $myoperD;    
##     $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {cat}  = "impscal";
##     $main::CODE {$arg[0]} {"symbols"} {$item{OPER_DEST}} {dtype}= $item{DEST_TYPE};
##     @{$main::CODE {$func} {"symbols"} {$myoperD} {produces}}= ($myoperD);
##   }
##   #The "consumes" entry has to be made as even if the entry was already there due
##   #to operD being an argument, there would be no entry for "consumes"
##   @{$main::CODE {$func} {"symbols"} {$myoperD} {consumes}}= ($item{OPER1});
##   
##   #main entry
##   $main::CODE {$arg[0]} {"instructions"} { $item{OPER_DEST} }
##     = { 'destType'  => $item{DEST_TYPE}
##       , 'oper1'     => $item{OPER1}
##       , 'opType'    => $item{OP_TYPE}
##       ,  'operD'    => $item{OPER_DEST}
##       , 'op'        => "assign"
##       , 'instrType' => "assign"
##       };
## 
##   $main::insCntr++;
##   print "TyBEC: Assign instruction found in $arg[0]\n";
##   
##   # ----------------------------------------
##   # Set port directions for caller function
##   # ----------------------------------------
##   TirGrammarMod::setArgDir($func, $myoperD, $myoper1, 'null');
##   
##   
## }

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
# sub actCALL_MAIN{
#   my @item = @{shift(@_)};
#   my %item = %{shift(@_)};
#   my @arg  = @{shift(@_)};
#   
#   print "TyBEC: Found call to main() in launch module.\n"; 
#   $main::CODE{launch}{call2main}{kIterSize} = 1;
# }

## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actBLMEM_TR_SIZE_MDATA{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {trSizeWords} = $item{INTEGER};
## }
## 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actBLMEM_DEST_ADDR_MDATA{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {destStartAddr} = $item{INTEGER};
## }
## 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actBLMEM_SRC_ADDR_MDATA{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {srcStartAddr} = $item{INTEGER};
## }
## 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actBLOCK_MEM_COPY{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   print "TyBEC: Found Block Memory Copy instruction in Launch: $item{NAME2} --> $item{NAME1}\n";
##   $main::CODE{launch}{blockMemCpyInstrs}{$main::insCntr}{dest}        = $item{NAME1};
##   $main::CODE{launch}{blockMemCpyInstrs}{$main::insCntr}{src}         = $item{NAME2};
##   $main::insCntr++; 
## }
## 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actCALL_MAIN_IN_REPEAT{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   print "TyBEC: Found call to main() inside a repeat block in  launch module.\n";
## }
## 
## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actREPEAT{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   # update Kernel Iterator parameters here
##   $main::CODE{launch}{call2main}{kIter}       = $item{NAME};
##   $main::CODE{launch}{call2main}{kIterStart}  = $item{INTEGER1};
##   $main::CODE{launch}{call2main}{kIterEnd}    = $item{INTEGER2};
##   $main::CODE{launch}{call2main}{kIterSize}   = $item{INTEGER2}-$item{INTEGER1}+1;
## }


## # ----------------------------------------------------------------------------
## # 
## # ----------------------------------------------------------------------------
## sub actLAUNCH{
##   my @item = @{shift(@_)};
##   my %item = %{shift(@_)};
##   my @arg  = @{shift(@_)};
##   
##   my $hash = $main::CODE{launch}; 
##   #reduce clutter
##   print "TyBEC: Found launch module.\n\n";
##   
##   # -------------------------------
##   # Initialize 
##   # -------------------------------
##   $main::CODE {launch} {costExclusive}    
##   = { 'ALMS'       => 0     
##     , 'ALUTS'      => 0
##     , 'REGS'       => 0
##     , 'M20Kbits'   => 0
##     , 'MLABbits'   => 0
##     , 'DSPs'       => 0
##     , 'Latency'    => 0
##     , 'PropDelay'  => 0
##     , 'CPI'        => 0
##   };
##   
##   $main::CODE{launch}{hostComm}{from} = 0;
##   $main::CODE{launch}{hostComm}{to}   = 0;
##   $main::CODE{launch}{hostComm}{toFrom}   = 0;
##   
##   $main::CODE{launch}{gMemComm}{to}   = 0;
##   $main::CODE{launch}{gMemComm}{from} = 0;
##   $main::CODE{launch}{gMemComm}{toFrom}   = 0;
## 
##   # -------------------------------
##   # Accumulate cost of MEM OBJs
##   # -------------------------------
##   ## Iterate through all MEM_OBJECTS to accumulate cost 
##   foreach my $key ( keys %{$hash->{mem_objects}} )
##   {
##     #iterate over all cost parameters
##     foreach my $key2 ( keys %{$hash->{mem_objects}{$key}{cost} } )
##     {
##       $hash->{costExclusive}{$key2} += $hash->{mem_objects}{$key}{cost}{$key2} 
##         if ($hash->{mem_objects}{$key}{cost}{$key2} ne 'null');#don't accumulate null values
##     }
##   }
##   
##   # ----------------------------------------------------------
##   # Accumulate RESOURCE and COMMUNICATION cost of STREAM OBJs
##   # ----------------------------------------------------------
##   #init. sustBW as min has to be picked
##   $hash->{costExclusive}{sustBW_Mbps} = 1000000000; #inf
## 
##   #iterate over all stream objects
##   foreach my $key ( keys %{$hash->{stream_objects}} ) {    
##     #iterate over all cost parameters
##     foreach my $key2 ( keys %{$hash->{stream_objects}{$key}{cost} } )
##     {
##       #don't accumulate sustained BW, just pick up the lowest 
##       #But make sure you leave out any streams with sust bandwidth = -1
##       #that is just indicating this stream is not relevant (constant stream e.g.)
##       if ($key2 eq 'sustBW_Mbps') {
##         $hash->{costExclusive}{$key2} = mymin($hash->{costExclusive}{$key2}, 
##                                               $hash->{stream_objects}{$key}{cost}{$key2})
##           if($hash->{stream_objects}{$key}{cost}{$key2} > 0);                 
##       }#if
##       
##       #accumulate all other costs
##       else {
##       $hash->{costExclusive}{$key2} += $hash->{stream_objects}{$key}{cost}{$key2}
##         if ($hash->{stream_objects}{$key}{cost}{$key2} ne 'null'); #don't accumulate null values
##       }#else
##     }#foreach 
##     
##     #accumulate total data transferred between host-device over streams
##     my $totalBits = $hash->{stream_objects}{$key}{cost}{totalBits};
##     $hash->{hostComm}{toFrom} += $totalBits;
## 
##     #separately record against in and out too, in case needed
##     if ($hash->{stream_objects}{$key}{dir} eq 'in') {
##       $hash->{hostComm}{from} += $totalBits; }
##     else {
##       $hash->{hostComm}{to} += $totalBits; }   
##   }
##   
##   # FIXME: I am recording it for BOTH host and gMEM..only one will be used dependong on memory-exec type
##   $hash->{gMemComm}{to}     = $hash->{hostComm}{to}    ;
##   $hash->{gMemComm}{from}   = $hash->{hostComm}{from}  ;
##   $hash->{gMemComm}{toFrom} = $hash->{hostComm}{toFrom};
##   
##   #reset instruction counter that was counting number of mem copy instructions in launch
##   $main::insCntr=0;
##   
##   # -----------------------------------------
##   # Accumulate cost of MEM COPY instructions 
##   # -----------------------------------------
##   
##   # -----------------------------------------
##   # Cost of Compute_Core (MAIN) accumulated
##   # when main is parsed
##   # -----------------------------------------
##   
##   # -----------------------------------------
##   # Update DOT and CALL_GRAPH
##   # -----------------------------------------
##   #$main::dotGraph->add_node('launch');
##   #$main::CODE{callGraph}{launch} = {};
## }




# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actDEFINE_STATEMENT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {"macros"} {$item{NAME}} = $item[4]; 
  print "TyBEC: Found macro $item{NAME} = $item[4]\n";
}

# ============================================================================
# GRAMMAR STRING
# ============================================================================

# --------------------------------
# >>>> Load Grammar file
# --------------------------------
my $grammarFileName = "$TyBECROOTDIR/lib-intern/TirGrammarString.pm"; 
open (my $fhTemplate, '<', $grammarFileName)
 or die "Could not open file '$grammarFileName' $!";     
 
# --------------------------------
# >>>> Read 
# --------------------------------
our $grammar = read_file ($fhTemplate);
 close $fhTemplate;

 
 
 
 
# --------------------------------
# FOOTNOTES
# --------------------------------
 
#[1]
#/
#(ui|i)\d+\.?(\d+|auto)?
#/
#1st Capturing Group (ui|i)
#1st Alternative ui
#ui matches the characters ui literally (case sensitive)
#2nd Alternative i
#i matches the character i literally (case sensitive)
#\d+ matches a digit (equal to [0-9])
#+ Quantifier — Matches between one and unlimited times, as many times as possible, giving back as needed (greedy)
#\.? matches the character . literally (case sensitive)
#? Quantifier — Matches between zero and one times, as many times as possible, giving back as needed (greedy)
#2nd Capturing Group (\d+|auto)?
#? Quantifier — Matches between zero and one times, as many times as possible, giving back as needed (greedy)
#1st Alternative \d+
#\d+ matches a digit (equal to [0-9])
#+ Quantifier — Matches between one and unlimited times, as many times as possible, giving back as needed (greedy)
#2nd Alternative auto
#auto matches the characters auto literally (case sensitive)