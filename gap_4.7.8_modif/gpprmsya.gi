#############################################################################
##
#W  gpprmsya.gi                 GAP Library                    Heiko Theißen
#W                                                           Alexander Hulpke
#W                                                           Martin Schönert
##
##
#Y  Copyright (C)  1996,  Lehrstuhl D für Mathematik,  RWTH Aachen,  Germany
#Y  (C) 1998 School Math and Comp. Sci., University of St Andrews, Scotland
#Y  Copyright (C) 2002 The GAP Group
##
##  This file contains the methods for symmetric and alternating groups
##

# xref to transgrp library
if not IsBound(TRANSDEGREES) then
  TRANSDEGREES:=0;
fi;


#############################################################################
##
#M  <perm> in <nat-alt-grp>
##
InstallMethod( \in,
    "alternating",
    true,
    [ IsPerm,
      IsNaturalAlternatingGroup ],
    0,

function( g, S )
    local   m,  l;

    if SignPerm(g)=-1 then
      return false;
    fi;
    m := MovedPoints(S);
    l := NrMovedPoints(S);
    
    if g = One( g )  then
        return true;
    elif l = 0  then
        return false;
    elif IsRange(m) and ( l = 1 or m[2] - m[1] = 1 )  then
        return SmallestMovedPoint(g) >= m[1]
           and LargestMovedPoint(g)  <= m[l];
    else
        return IsSubset( m, MovedPoints( [g] ) );
    fi;
end );

InstallMethod( Random,
    "alternating group: floyd's algorithm",
    true,
    [ IsNaturalAlternatingGroup ],
    10, # override perm gp. method
function ( G )
    local   rnd,        # random permutation, result
            sgn,        # sign of the permutation so far
            tmp,        # temporary variable for swapping
	    deg,
	    mov,
            i,  k;      # loop variables

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;
    # use Floyd\'s algorithm
    mov:=MovedPoints(G);
    deg:=Length(mov);
    rnd := [1..deg];
    sgn := 1;
    for i  in [1..deg-2] do
        k := Random( [ i .. deg] );
        tmp := rnd[i];
        rnd[i] := rnd[k];
        rnd[k] := tmp;
        if i <> k  then
            sgn := -sgn;
        fi;
    od;

    # make the permutation even
    if sgn = -1  then
        tmp := rnd[deg-1];
        rnd[deg-1] := rnd[deg];
        rnd[deg] := tmp;
    fi;

    # return the permutation
    return PermList( rnd )^MappingPermListList([1..deg],mov);
end);

#T special StabChain method?



#############################################################################
##
#M  RepresentativeAction( <G>, <d>, <e>, <opr> ). . for alternating groups
##
InstallOtherMethod( RepresentativeActionOp, "natural alternating group",
  true, [ IsNaturalAlternatingGroup, IsObject, IsObject, IsFunction ], 
  # the objects might be group elements: rank up	
  2*RankFilter(IsMultiplicativeElementWithInverse),
function ( G, d, e, opr )
local dom,dom2,sortfun,max,cd,ce,rep,dp,ep;
  # test for internal rep
  if HasGeneratorsOfGroup(G) and 
    not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
    TryNextMethod();
  fi;
  dom:=Set(MovedPoints(G));
  if opr=OnPoints then
    if IsInt(d) and IsInt(e) then
      if d in dom and e in dom and Length(dom)>2 then
	return (d,e,First(dom,i->i<>d and i<>e));
      else
        return fail;
      fi;
    elif IsPerm(d) and IsPerm(e) and d in G and e in G then
      sortfun:=function(a,b) return Length(a)<Length(b);end;
      if Order(d)=1 then #LargestMovedPoint does not work for ().
        if Order(e)=1 then
	  return ();
	else
	  return fail;
	fi;
      fi;
      if CycleStructurePerm(d)<>CycleStructurePerm(e) then
        return fail;
      fi;
      max:=Maximum(LargestMovedPoint(d),LargestMovedPoint(e));
      dp:=d;
      ep:=e;
      cd:=ShallowCopy(Cycles(d,[1..max]));
      ce:=ShallowCopy(Cycles(e,[1..max]));
      Sort(cd,sortfun);
      Sort(ce,sortfun);
      rep:=MappingPermListList(Concatenation(cd),Concatenation(ce));
      if SignPerm(rep)=-1 then
        dom2:=Difference(dom,Union(Concatenation(cd),Concatenation(ce)));
	if Length(dom2)>1 then
	  rep:=rep*(dom2[1],dom2[2]);
	else
	  #this is more complicated
	  TryNextMethod();

	  # temporarily disabled, Situation is more complicated
	  cd:=Filtered(cd,i->IsSubset(dom,i));
	  d:=CycleStructurePerm(d);
	  e:=PositionProperty([1..Length(d)],i->IsBound(d[i]) and
	    # cycle structure is shifted, so this is even length
	    # we need either to swap a pair of even cycles or to 3-cycle
	    # odd cycles
	    ((IsInt((i+1)/2) and d[i]>1) or
	    (IsInt(i/2) and d[i]>2)));
	  if e=fail then
	    rep:=fail;
	  elif IsInt((e+1)/2) then
	    cd:=Filtered(cd,i->Length(i)=e+1);
	    cd:=cd{[1,2]};
	    rep:=MappingPermListList(Concatenation(cd),
	                                 Concatenation([cd[2],cd[1]]))*rep;
	  else
	    cd:=Filtered(cd,i->Length(i)=e+1);
	    cd:=cd{[1,2,3]};
	    rep:=MappingPermListList(Concatenation(cd),
	                             Concatenation([cd[2],cd[3],cd[1]]))*rep;
	  fi;
        fi;
      fi;
      if rep<>fail then
	Assert(1,dp^rep=ep);
      fi;
      return rep;
    fi;
  elif (opr=OnSets or opr=OnTuples) and (IsDuplicateFreeList(d) and
    IsDuplicateFreeList(e)) then
    if Length(d)<>Length(e) then
      return fail;
    fi;
    if IsSubset(dom,Set(d)) and IsSubset(dom,Set(e)) then
      rep:=MappingPermListList(d,e);
      if SignPerm(rep)=-1 then
	cd:=Difference(dom,e);
	if Length(cd)>1 then
	  rep:=rep*(cd[1],cd[2]);
	elif opr=OnSets then
	  if Length(d)>1 then
	    rep:=(d[1],d[2])*rep;
	  else
	    rep:=fail; # set Length <2, maximal 1 further point in dom,imposs.
	  fi;
	else # opr=OnTuples, not enough points left
	  rep:=fail;
	fi;
      fi;
      return rep;
    fi;
  fi;
  TryNextMethod(); 
end);


InstallMethod( SylowSubgroupOp,
    "alternating",
    true,
    [ IsNaturalAlternatingGroup, IsPosInt ], 0,
function ( G, p )
    local   S,          # <p>-Sylow subgroup of <G>, result
            sgs,        # strong generating set of <G>
            q,          # power of <p>
            i,          # loop variable
	    trf,
	    mov,
	    deg;

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;
    mov:=MovedPoints(G);
    deg:=Length(mov);
    # make the strong generating set
    sgs := [];
    for i  in [3..deg]  do
        q := p;
        if p = 2  and i mod 2 = 0  then
            Add( sgs, (mov[1],mov[2])(mov[i-1],mov[i]) );
            q := q * p;
        fi;
	trf:=MappingPermListList([1..deg],mov); # translating perm
        while i mod q = 0  do
            Add( sgs, PermList( Concatenation(
                        [1..i-q], [i-q+1+q/p..i], [i-q+1..i-q+q/p] ) )^trf );
            q := q * p;
        od;
    od;

    # make the Sylow subgroup
    S := SubgroupNC( G, sgs );

    # add the stabilizer chain
    #MakeStabChainStrongGenerators( S, Reversed([1..G.degree]), sgs );

    if Size( S ) > 1 then
        SetIsPGroup( S, true );
        SetPrimePGroup( S, p );
    fi;

    # return the Sylow subgroup
    return S;
end);


InstallMethod( ConjugacyClasses,
    "alternating",
    true,
    [ IsNaturalAlternatingGroup ], 0,
function ( G )
    local   classes,    # conjugacy classes of <G>, result
            prt,        # partition of <G>
            sum,        # partial sum of the entries in <prt>
            rep,        # representative of a conjugacy class of <G>
	    mov,deg,trf, # degree, moved points, transfer
            i;          # loop variable

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;
    mov:=MovedPoints(G);
    deg:=Length(mov);
    if deg=0 then
      TryNextMethod();
    fi;
    trf:=MappingPermListList([1..deg],mov);
    # loop over the partitions
    classes := [];
    for prt  in Partitions( deg )  do

        # only take those partitions that lie in the alternating group
        if Number( prt, i -> i mod 2 = 0 ) mod 2 = 0  then

            # compute the representative of the conjugacy class
            rep := [2..deg];
            sum := 1;
            for i  in prt  do
                rep[sum+i-1] := sum;
                sum := sum + i;
            od;
            rep := PermList( rep )^trf;

            # add the new class to the list of classes
            Add( classes, ConjugacyClass( G, rep ) );

            # some classes split in the alternating group
            if      ForAll( prt, i -> i mod 2 = 1 )
                and Length( prt ) = Length( Set( prt ) )
            then
                Add( classes, ConjugacyClass(G,rep^(mov[deg-1],mov[deg])) );
            fi;

        fi;

    od;

    # return the classes
    return classes;
end);

InstallMethod( IsomorphismFpGroup, "alternating group", true,
    [ IsNaturalAlternatingGroup ], 10, # override `IsSimpleGroup' method
function(G)
  return IsomorphismFpGroup(G,
           Concatenation("A_",String(Length(MovedPoints(G))),".") );
end);

InstallOtherMethod( IsomorphismFpGroup, "alternating group,name",
    true,
    [ IsNaturalAlternatingGroup, IsString ],
    10, # override `IsSimpleGroup' method
function ( G,str )
local   F,      # free group
	gens,	#generators of F
	imgs,
	hom,	# bijection
	mov,deg,# moved pts, degree
	m,	#[n/2]
	relators,
	r,s,	# generators
	d,	# subset of pts
	p,	# permutation
	j;      # loop variables

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    mov:=MovedPoints(G);
    deg:=Length(mov);

    # create the finitely presented group with <G>.degree-1 generators
    F := FreeGroup( 2, str);
    gens:=GeneratorsOfGroup(F);

    # add the relations according to the presentation by Coxeter
    # (see Coxeter/Moser)
    r:=F.1;
    s:=F.2;
    if IsOddInt(deg) then
      m:=(deg-1)/2;
      relators:=[r^deg/s^deg,r^deg/(r*s)^m];
      for j in [2..m] do
	Add(relators,(r^-j*s^j)^2);
      od;
      #(1,2,3,..deg) and (1,3,2,4,5,..deg)
      p:=MappingPermListList(mov,Concatenation(mov{[2..deg]},[mov[1]]));
      imgs:=[p,p^(mov[2],mov[3])];
    else
      m:=deg/2;
      relators:=[r^(deg-1)/s^(deg-1),r^(deg-1)/(r*s)^m];
      for j in [1..m-1] do
	Add(relators,(r^-j*s^-1*r*s^j)^2);
      od;
      # (1,2,3,4..,deg-2,deg),(1,2,3,4,deg-3,deg-1,deg);
      d:=Concatenation(mov{[1..deg-2]},[mov[deg]]);
      p:=MappingPermListList(d,Concatenation(d{[2..deg-1]},[d[1]]));
      imgs:=[p];
      d:=Concatenation(mov{[1..deg-3]},mov{[deg-1,deg]});
      p:=MappingPermListList(d,Concatenation(d{[2..deg-1]},[d[1]]));
      Add(imgs,p);
    fi;

    F:=F/relators;

    SetSize(F,Size(G));
    UseIsomorphismRelation( G, F );

    # return the isomorphism to the finitely presented group
    hom:= GroupHomomorphismByImagesNC(G,F,imgs,GeneratorsOfGroup(F));
    SetIsBijective( hom, true );
    return hom;
end);

# alternative, which has nicer (but more) generators
#function ( G )
#local   F,      # free group
#	gens,	#generators of F
#	imgs,
#	hom,	# bijection
#	mov,deg,
#	relators,
#	i, k;       # loop variables
#
#    mov:=MovedPoints(G);
#    deg:=Length(mov);
#
#    # create the finitely presented group with <G>.degree-1 generators
#    F := FreeGroup( deg-2, Concatenation("A_",String(deg),".") );
#    gens:=GeneratorsOfGroup(F);
#
#    # add the relations according to the presentation by Carmichael
#    # (see Coxeter/Moser)
#    relators := [];
#    for i  in [1..deg-2]  do
#        Add( relators, gens[i]^3 );
#    od;
#    for i  in [1..deg-3]  do
#        for k  in [i+1..deg-2]  do
#            Add( relators, (gens[i] * gens[k])^2 );
#        od;
#    od;
#
#    F:=F/relators;
#
#    SetSize(F,Size(G));
#    UseIsomorphismRelation( G, F );
#
#    # compute the bijection
#    imgs:=[];
#    for i in [1..deg-2] do
#      Add(imgs,(mov[1],mov[i+1],mov[deg]));
#    od;
#
#    # return the isomorphism to the finitely presented group
#    hom:= GroupHomomorphismByImagesNC(G,F,imgs,GeneratorsOfGroup(F));
#    SetIsBijective( hom, true );
#    return hom;
#end);

################################################
# h has socle A_n^{l1}, acting on l1-tuples of l2-sets
#output is a subset of the permutation domain, consisting
#of tuples which agree in l1-1 coordinates and intersect in l2-1 points
#in the last coordinate
PermNatAnTestDetect:=function(h,n,l1,l2)
local schreiertree, cosetrepresentative, flag, schtree, stab, k, p, j,
      cosetrep, orbits, neworb, int, set, count, flag2, neworb2, o, i,dom,pt1;

  #permutation group h, on m points, Schreier tree with root k
  schreiertree:=function(h,m,k)
  local mark, gens, inv, schtree, i, j, list;

    mark:=BlistList([1..m],[k]);
    gens:=GeneratorsOfGroup(h);
    inv:=List(gens,x->x^(-1));
    list:=[k];
    schtree:=[ ];
    schtree[k]:=();
    for i in list do
      for j in [1..Length(gens)] do
	if mark[i^(inv[j])]=false then
	    Add(list,i^(inv[j]));
	    mark[i^(inv[j])]:=true;
	    schtree[i^(inv[j])]:=gens[j];
	fi;
      od;
    od;
    return schtree;
  end;

  cosetrepresentative:=function(schtree,k,j)
  local cosetrep;

    cosetrep:=();
    repeat
      cosetrep:=cosetrep*schtree[j];
      j:=j^schtree[j];
    until j=k;
    return cosetrep;
  end;

  flag:=true;
  # create a domain of moved points, at least (n choose l2)^l1 long
  dom:=Set(MovedPoints(h));
  k:=Binomial(n,l2)^l1;
  while Length(dom)<k do
    AddSet(dom,dom[Length(dom)]+1);
  od;

  pt1:=dom[1];
  schtree:= schreiertree(h,dom[Length(dom)],pt1);

  # group generated by ten random elements of the stabilizer of k in h
  stab:=[];
  k:=pt1;
  for i in [1..10] do
    p:=PseudoRandom(h);
    j:=k^p;
    cosetrep:=cosetrepresentative(schtree,k,j);
    Add(stab,p*cosetrep);
  od;
  stab:=Group(stab);

  orbits:=Orbits(stab,dom{[1..Binomial(n,l2)^l1]},OnPoints);
  k:=Position(List(orbits, x->Length(x)),l1*l2*(n-l2));
  if k = fail then
    flag:= false;
  else
    j:=orbits[k][1];
    cosetrep:=cosetrepresentative(schtree,1,j);
    cosetrep:=cosetrep^(-1);
    neworb:=List(orbits[k],x->x^cosetrep);
    int:=Intersection(orbits[k],neworb);
    Add(int,orbits[k][1]);
    Add(int,1);
    if Length(int) <> n then
	flag:=false;
    else
      # int contains l2-1 extra l2-sets
      if l2=1 then
	set:=Set(int);
      else
	count:=1;
	flag2:=false;
	repeat
	  j:=int[count];
	  cosetrep:=cosetrepresentative(schtree,pt1,j);
	  cosetrep:=cosetrep^(-1);
	  neworb2:=List(orbits[k],x->x^cosetrep);
	  if Length(Intersection(int,neworb2))=n-l2 then
	    set:= Union(Intersection(int,neworb2),[int[count]]);
	    flag2:=true;
	  else
	    count:=count+1;
	  fi;
	until flag2 or count>l2;
	if not flag2 then
	    flag:=false;
	fi;
      fi;
    fi;
  fi;

  if flag=true then
    o:=Orbit(h,set,OnSets);
    if Length(o) <> l1*Binomial(n,l2)^(l1-1)*Binomial(n,l2-1) then
      flag:=false;
    fi;
  fi;
  if flag=false then
    return fail;
  else
    return set;
  fi;
end;

# see Ákos Seress, Permutation group algorithms. Cambridge Tracts in
# Mathematics, 152. Section 10.2 for the background of this function.
BindGlobal("DoSnAnGiantTest",function(g,dom,kind)
local bound, n, i, p, cycles, l, pnt;
  pnt := dom[1];
  n:=Length(dom);
  # From the above reference we see that with these bounds this function
  # will fail on a symmetric group with probability < 10^-10.
  if kind=1 then
    bound:=10*LogInt(n,2);
  else
    bound:=50*LogInt(n,2);
  fi;
  i:=0;
  # We are looking for an element with a cycle of prime length > n/2
  # and < n-2. Instead of computing the complete cycle structure we just
  # look at the cycle length of one moved point (if there is a cycle as
  # desired, it will contain this point with probability > 1/2).
  repeat
    i:=i+1;
    p:=PseudoRandom(g);
    l:=CYCLE_LENGTH_PERM_INT(p,pnt);
  until (i>bound) or (l> n/2 and l<n-2 and IsPrime(l));
  if i>bound then
    return fail;
  else
    return true;
  fi;
end);

BindGlobal("PermgpContainsAn",function(g)
local dom, n, mine, root, d, k, b, m, l,lh;

  dom:=MovedPoints(g);
  n:=Length(dom);
  if not IsTransitive(g,dom) then
    return false;
  fi;

  if DoSnAnGiantTest(g,dom,1)=true then
    # we've found elements that prove the group must contain A_n.
    return true;
  fi;
  # otherwise, the group is likely (but not proven) to be different

  if not IsPrimitive(g,dom) then
    return false;
  fi;
  # so the group is primitive

  if n>10 then # otherwise the size is immediate
    # test whether its socle could be A_l^m, acting on k-tuples in product
    # action. 
    mine:=Minimum(List(Collected(Factors(n)),i->i[2]));
    for m in [1..mine] do
      root:=RootInt(n,m);
      if root^m=n then
	# case k=1 -> A_root on points
	if m>1 then # k=1, m=1: then it's A_n
	  d:=PermNatAnTestDetect(g,root,m,1);
	  if d<>fail then
	    Info(InfoGroup,3,"Detected ",root,",",m,",",1,"\n");
	    return d;
	  fi;
	fi;

	for l in [2..RootInt(2*root,2)+1] do
	  lh:=Int(l/2)+1;
	  k:=2;
	  b:=Binomial(l,k);
	  while b<root and k<lh do
	    k:=k+1;
	    b:=Binomial(l,k);
	  od;
	  if b=root then
	    d:=PermNatAnTestDetect(g,l,m,k);
	    if d<>fail then
	      Info(InfoGroup,3,"Detected ",l,",",m,",",k,"\n");
	      return d;
	    fi;
	  fi;
	od;
      fi;
    od;
  fi;

  if DoSnAnGiantTest(g,dom,2)=true then
    # we've found elements that prove the group must contain A_n.
    return true;
  fi;

  # now the socle is not a power of A_l or n is small. So the group is small
  # base enforce a stabilizer chain calculation

  return Size(g)>=Factorial(n)/2;

end);

#############################################################################
##
#M  IsNaturalAlternatingGroup( <sym> )
##

InstallMethod(IsNaturalAlternatingGroup,"knows size",true,[IsPermGroup
        and HasSize],0,
        function( g )
    local s, i, n;
    s := Size(g);
    n := NrMovedPoints(g);
    # avoid computing Factorial(n)
    for i in  [3..n] do
        if s mod i <> 0 then
            return false;
        else
            s := s/i;
        fi;
    od;
    return s = 1;
end );

InstallMethod(IsNaturalAlternatingGroup,"comprehensive",true,[IsPermGroup],0,
function( grp )
  if 0 = NrMovedPoints(grp)  then
    return IsTrivial(grp);
  else
    return PermgpContainsAn(grp)=true and
      ForAll(GeneratorsOfGroup(grp),i->SignPerm(i)=1);
  fi;
end );

#############################################################################
##
#M  IsNaturalSymmetricGroup( <sym> )
##

InstallMethod(IsNaturalSymmetricGroup,"knows size",true,[IsPermGroup
        and HasSize],0,
        function( g )
    local s, i, n;
    s := Size(g);
    n := NrMovedPoints(g);
    # avoid computing Factorial(n)
    for i in  [2..n] do
        if s mod i <> 0 then
            return false;
        else
            s := s/i;
        fi;
    od;
    return true;
end );

InstallMethod(IsNaturalSymmetricGroup,"comprehensive",true,[IsPermGroup],0,
function( grp )
  if 0 = NrMovedPoints(grp)  then
    return IsTrivial(grp);
  else
    return PermgpContainsAn(grp)=true and
      ForAny(GeneratorsOfGroup(grp),i->SignPerm(i)=-1);
  fi;
end );

#############################################################################
##
#M  <perm> in <nat-sym-grp>
##
InstallMethod( \in,"perm in natsymmetric group",
    true,
    [ IsPerm,
      IsNaturalSymmetricGroup ],
    0,

function( g, S )
    local   m,  l;

    m := MovedPoints(S);
    l := NrMovedPoints(S);
    
    if g = One( g )  then
        return true;
    elif l = 0  then
        return false;
    elif IsRange(m) and ( l = 1 or m[2] - m[1] = 1 )  then
        return SmallestMovedPoint(g) >= m[1]
           and LargestMovedPoint(g)  <= m[l];
    else
        return IsSubset( m, MovedPoints( [g] ) );
    fi;
end );

#############################################################################
##
#M  IsSubset(<nat-sym-grp>,<permgrp>
##
InstallMethod( IsSubset,"permgrp of natsymmetric group", true,
    [ IsNaturalSymmetricGroup,IsPermGroup ],
    # we need to override a metrhod that computes the size.
    SUM_FLAGS,

function( S,G )
  return IsSubset(MovedPoints(S),MovedPoints(G));
end );


#############################################################################
##
#M  Socle( <nat-sym/alt-grp> )
##
InstallMethod( Socle,
    true, [ IsNaturalSymmetricGroup ], 0,
function(sym)
  if NrMovedPoints(sym)<=4 then
    TryNextMethod();
  else
    return AlternatingGroup(MovedPoints(sym));
  fi;
end);

InstallMethod( Socle, true, [ IsNaturalAlternatingGroup ], 0,
function(alt)
  if NrMovedPoints(alt)<=4 then
    TryNextMethod();
  else
    return alt;
  fi;
end);

#############################################################################
##
#M  Size( <nat-sym-grp> )
##
InstallMethod( Size,
    true,
    [ IsNaturalSymmetricGroup ], 0,
    sym -> Factorial( NrMovedPoints(sym) ) );


InstallMethod( Random,
    "symmetric group: floyd's algorithm",
    true,
    [ IsNaturalSymmetricGroup ],
    10, # override perm. gp. method
function ( G )
    local   rnd,        # random permutation, result
            sgn,        # sign of the permutation so far
            tmp,        # temporary variable for swapping
	    deg,
	    mov,
            i,  k;      # loop variables

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    # use Floyd\'s algorithm
    mov:=MovedPoints(G);
    deg:=Length(mov);
    rnd := [1..deg];
    sgn := 1;
    for i  in [1..deg-1] do
        k := Random( [ i .. deg] );
        tmp := rnd[i];
        rnd[i] := rnd[k];
        rnd[k] := tmp;
    od;

    # return the permutation
    return PermList( rnd )^MappingPermListList([1..deg],mov);
end);

#############################################################################
##
#M  StabilizerOp( <nat-sym-grp>, <int>, OnPoints )
##
InstallOtherMethod( StabilizerOp,"symmetric group", true,
    [ IsNaturalSymmetricGroup, IsPosInt, IsFunction ],
  # the objects might be a group element: rank up	
  RankFilter(IsMultiplicativeElementWithInverse),

function( sym, p, opr )
    # test for internal rep
    if HasGeneratorsOfGroup(sym) and 
      not ForAll(GeneratorsOfGroup(sym),IsInternalRep) then
      TryNextMethod();
    fi;

    if opr <> OnPoints  then
        TryNextMethod();
    fi;
    return AsSubgroup( sym,
           SymmetricGroup( Difference( MovedPoints( sym ), [ p ] ) ) );
end );

InstallMethod( CentralizerOp,
    "element in natural symmetric group",
    IsCollsElms,
    [ IsNaturalSymmetricGroup, IsPerm ], 0,
function ( G, g )
    local   C,          # centralizer of <g> in <G>, result
            sgs,        # strong generating set of <C>
            gen,        # one generator in <sgs>
            cycles,     # cycles of <g>
            cycle,      # one cycle from <cycles>
            lasts,      # '<lasts>[<l>]' is the last cycle of length <l>
            last,       # one cycle from <lasts>
	    mov,
            i;          # loop variable

    Print("XXX CentralizerOp for symmetric group\n");
    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    if not g in G then
      TryNextMethod();
    fi;

    # handle special case
    mov:=MovedPoints(G);

    # start with the empty strong generating system
    sgs := [];

    # compute the cycles and find for each length the last one
    cycles := Cycles( g, mov );
    lasts := [];
    for cycle  in cycles  do
      lasts[Length(cycle)] := cycle;
    od;

    # loop over the cycles
    for cycle  in cycles  do

      # add that cycle itself to the strong generators
      if Length( cycle ) <> 1  then
	  gen := MappingPermListList(cycle,
	            Concatenation(cycle{[2..Length(cycle)]},[cycle[1]]));
	  Add( sgs, gen );
      fi;

      # and this cycle can be mapped to the last cycle of this length
      if cycle <> lasts[ Length(cycle) ]  then
	  last := lasts[ Length(cycle) ];
	  gen := MappingPermListList(Concatenation(cycle,last),
	                              Concatenation(last,cycle));
	  Add( sgs, gen );
      fi;

  od;

  # make the centralizer
  C := Subgroup(  G , sgs );

  # return the centralizer
  return C;
end);

BindGlobal("OneNormalizerfixedBlockSystem",function(G,dom)
local b, bl;
  if IsPrimeInt(Length(dom)) then
    # no need trying
    return fail;
  fi;
  b:=AllBlocks(Action(G,dom));
  bl:=Collected(List(b,Length));
  bl:=Filtered(bl,i->i[2]=1);
  if Length(bl)=0 then
    Info(InfoGroup,3,"No normalizerfixed block found");
    return fail;
  fi;
  b:=First(b,i->Length(i)=bl[1][1]);
  Info(InfoGroup,3,"Normalizerfixed block system blocksize ",Length(b));
  return Set(Orbit(G,Set(dom{b}),OnSets));
end);

BindGlobal("NormalizerParentSA",function(s,u)
  local dom, issym, o, b, beta, alpha, emb, nb, na, w, perm, pg, l, is, ie, ll, syll, act, typ, sel, bas, wdom, comp, lperm, other, away, i, j;

  dom:=Set(MovedPoints(s));
  issym:=IsNaturalSymmetricGroup(s);
  if not IsSubset(dom,MovedPoints(u)) or
    ((not issym) and ForAny(GeneratorsOfGroup(u),x->SignPerm(x)=-1)) then
    return s; # cannot get parent, as not contained
  fi;
  # get orbits
  o:=ShallowCopy(Orbits(u,dom));
  Info(InfoGroup,1,"SymmAlt normalizer: orbits ",List(o,Length));

  # transitive?
  if Length(o)=1 then
    b:=OneNormalizerfixedBlockSystem(u,o[1]);
    if b=fail then
      # none -- no improvement
      return s;
    fi;
    # the normalizer must fix this block system

    beta:=ActionHomomorphism(u,b,OnSets,"surjective");
    alpha:=ActionHomomorphism(Stabilizer(u,b[1],OnSets),b[1],"surjective");
    emb:=KuKGenerators(u,beta,alpha);
    nb:=Normalizer(SymmetricGroup(Length(b)),Image(beta));
    na:=Normalizer(SymmetricGroup(Length(b[1])),Image(alpha));
    w:=WreathProduct(na,nb);
    if issym then
      perm:=s;
    else
      perm:=SymmetricGroup(MovedPoints(s));
    fi;
    perm:=RepresentativeAction(perm,emb,GeneratorsOfGroup(u),OnTuples);
    if perm<>fail then
      pg:=w^perm;
    else
      #Print("Embedding Problem!\n");
      w:=WreathProduct(SymmetricGroup(Length(b[1])),SymmetricGroup(Length(b)));
      perm:=MappingPermListList([1..Length(o[1])],Concatenation(b));
      pg:=w^perm;
    fi;
  else

    # first sort by Length
    Sort(o,function(a,b) return Length(a)<Length(b);end);
    l:=Length(o);
    pg:=[]; # parent generators
    is:=1;
    ie:=1;
    while is<=l do
      ll:=Length(o[is]);
      while ie<=l and Length(o[ie])=ll do
	ie:=ie+1;
      od;
      # now length block is from is to ie-1

      syll:=SymmetricGroup(ll);
      # if the degrees are small enough, even get local types
      if ll>1 and TRANS_AVAILABLE=true and ll<=TRANSDEGREES then
	Info(InfoGroup,1,"Length ",ll," sort by types");
	act:=[];
	typ:=[];
	for i in [is..ie-1] do
	  act[i]:=Action(u,o[i]);
	  typ[i]:=TransitiveIdentification(act[i]);
	od;
	# rearrange
	for i in Set(typ) do
	  sel:=Filtered([is..ie-1],j->typ[j]=i);
	  bas:=Normalizer(syll,act[sel[1]]);
	  w:=WreathProduct(bas,SymmetricGroup(Length(sel)));
	  wdom:=[1..ll*Length(sel)];
	  comp:=WreathProductInfo(w).components;
	  # now the suitable permutation
	  perm:=();
	  # first permutation on each component
	  for j in [1..Length(sel)] do
	    if j=1 then
	      lperm:=();
	    else
	      lperm:=RepresentativeAction(syll,act[sel[1]],act[sel[j]]);
	    fi;
	    other:=Difference(wdom,comp[j]);
	    away:=[1..Length(other)]+Length(wdom);
	    perm:=perm*MappingPermListList(Concatenation(comp[j],other),
				Concatenation([1..ll],away)) # j-th component
		  *lperm # standard form
		  *MappingPermListList(Concatenation([1..ll],away),
				Concatenation(comp[j],other)); # to j orbit
	  od;
	  # and then of components
	  perm:=perm*MappingPermListList(wdom,Concatenation(o{sel}));
	  for i in SmallGeneratingSet(w) do
	    Add(pg,i^perm);
	  od;
	od;

      else
	bas:=syll;
	w:=WreathProduct(bas,SymmetricGroup(ie-is));
	perm:=MappingPermListList([1..ll*(ie-is)],Concatenation(o{[is..ie-1]}));
	for i in SmallGeneratingSet(w) do
	  Add(pg,i^perm);
	od;
      fi;
      is:=ie;
    od;
    pg:=Group(pg,());
  fi;
  if not issym then 
    pg:=AlternatingSubgroup(pg);
  fi;
  if IsSolvableGroup(pg) then
    perm:=IsomorphismPcGroup(pg);
    pg:=PreImage(perm,Normalizer(Image(perm,pg),Image(perm,u)));
  fi;
  return pg;
end);

BindGlobal("DoNormalizerSA",function ( G, U )
local P;
    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

  P:=NormalizerParentSA(G,U);
  if Size(P)<Size(G) then
    Info(InfoGroup,1,"Normalizer parent deg ",NrMovedPoints(G),
         " reduces by ",Index(G,P));
    return AsSubgroup(G,Normalizer(P,U));
  else
    Info(InfoGroup,2,"No improvement by symm/alt normalizer");
    TryNextMethod(); # go way of permutations
  fi;
end);

InstallMethod( NormalizerOp, "subgp of natural symmetric group",
    IsIdenticalObj, [ IsNaturalSymmetricGroup, IsPermGroup ], 0,
    DoNormalizerSA);

InstallMethod( NormalizerOp, "subgp of natural alternating group",
    IsIdenticalObj, [ IsNaturalAlternatingGroup, IsPermGroup ], 0,
    DoNormalizerSA);


# conjugate subgroups of symmetric group.
# false indicates the method does not work
BindGlobal("SubgpConjSymmgp",function(s,g,h)
local og,oh,cb,cc,cac,perm1,perm2,
  dom,n,a,c,b,b2,w,p1,p2,perm,t,ac,ac2,no,no2,i,j;


  p1:=Set(MovedPoints(g));
  p2:=Set(MovedPoints(h));
  dom:=Set(MovedPoints(s));

  og:=Orbits(g,p1);
  oh:=Orbits(h,p2);
  if Length(og)>1 or p1<>p2 or p1<>dom then
    # intransitive
    if not (IsSubset(dom,p1) and IsSubset(dom,p2)) then
      return false;
    fi;
    if Collected(List(og,Length))<>Collected(List(oh,Length)) then
      return fail;
    fi;
    og:=Set(List(og,Set));
    oh:=Set(List(oh,Set));
    ac:=[];
    a:=1;
    perm:=();
    perm1:=[];
    perm2:=[];
    if p1<>p2 then
      Add(perm1,Difference(dom,p1));
      Add(perm2,Difference(dom,p2));
    fi;
    for i in (Set(List(og,Length))) do
      c:=Filtered(og,x->Length(x)=i);
      #Append(p1,c);
      ac2:=Filtered(oh,x->Length(x)=i);
      #Append(p2,ac2);
      w:=WreathProduct(SymmetricGroup(i),SymmetricGroup(Length(ac2)));
      b:=Blocks(w,MovedPoints(w),[1..i]);
      cc:=Concatenation(c);
      cb:=Concatenation(b);
      cac:=Concatenation(ac2);
      Add(perm1,cc);
      Add(perm2,cac);
      c:=MappingPermListList(cc,cb);
      b:=MappingPermListList(cb,cac);

      # make projections the same
      p1:=List(GeneratorsOfGroup(g),x->RestrictedPerm(x,cc)^c);
      p1:=SubgroupNC(w,p1);
      p2:=List(GeneratorsOfGroup(h),x->b*RestrictedPerm(x,cac)/b);
      p2:=SubgroupNC(w,p2);
      no:=Normalizer(w,p2);
#Print(i," ",Length(ac2)," ",Size(w)," ",Index(w,no),"\n");
      t:=RepresentativeAction(w,p1,p2);
      if t=fail then return fail;fi; # can't map projection OK

#Print(List(Filtered(og,x->Length(x)=i),x->Position(oh,OnSets(x,c*b))),"\n");

      Append(ac,List(GeneratorsOfGroup(no),x->x^b));
      perm:=perm*t^b;
      a:=a*Size(no);
    od;
    perm1:=MappingPermListList(Concatenation(perm1),Concatenation(perm2));
    perm:=perm1*perm;
    ac:=SubgroupNC(s,ac);
    SetSize(ac,a);
    a:=RepresentativeAction(ac,g^perm,h);
    if a=fail then 
      return fail;
    else
      return perm*a;
    fi;

  fi;

  n:=NrMovedPoints(s);
  a:=AllBlocks(g);
  c:=Collected(List(a,Length));
  c:=Filtered(c,i->i[2]=1);
  if Length(c)=0 then
    return false;
  else
    c:=c[1][1];
    a:=First(a,i->Length(i)=c);
    b:=Blocks(g,MovedPoints(g),a);
    ac:=Action(g,b,OnSets);
    a:=AllBlocks(h);
    a:=Filtered(a,i->Length(i)=c);
    if Length(a)<>1 then
      # different blocks
      return fail;
    fi;
    b2:=Blocks(h,MovedPoints(h),a[1]);
    ac2:=Action(h,b2,OnSets);
    t:=SymmetricGroup(n/c);
    perm:=RepresentativeAction(t,ac,ac2);
    if perm=fail then
      return fail;
    else
      b:=Permuted(b,perm);
      Assert(1,Action(g,b,OnSets)=ac2);
    fi;
    p1:=MappingPermListList(Concatenation(b),[1..n]);
    p2:=MappingPermListList(Concatenation(b2),[1..n]);
    no:=Normalizer(t,ac2);
    #Print(" using blocks ",c," factorgp size ",Size(no),"\n");
    g:=g^p1;
    h:=h^p2;
    b:=List(b,i->OnSets(Set(i),p1));
    ac:=Action(Stabilizer(g,b[1],OnSets),b[1]);
    t:=SymmetricGroup(c);
    for i in [1..Length(b)] do
      ac2:=Action(Stabilizer(g,b[i],OnSets),b[i]);
      perm:=RepresentativeAction(t,ac2,ac);
      if perm=fail then
	# b cannot be conjugated -- inconsistent
	Error("inconsistence");
      fi;
      perm:=perm^MappingPermListList([1..c],b[i]);
      g:=g^perm;
      p1:=p1*perm;

      ac2:=Action(Stabilizer(h,b[i],OnSets),b[i]);
      perm:=RepresentativeAction(t,ac2,ac);
      if perm=fail then
	# cannot map onto -- wrong
	return fail;
      fi;
      perm:=perm^MappingPermListList([1..c],b[i]);
      h:=h^perm;
      p2:=p2*perm;
    od;

    no2:=Normalizer(t,ac);

    w:=WreathProduct(no2,no);
    perm:=RepresentativeAction(w,g,h);
    if perm<>fail then
      Assert(1,ForAll(GeneratorsOfGroup(g),i->i^perm in h));
      perm:=p1*perm/p2;
    fi;
    return perm;
  fi;
end);

#############################################################################
##
#M  RepresentativeAction( <G>, <d>, <e>, <opr> ) .  . for symmetric groups
##
InstallOtherMethod( RepresentativeActionOp, "for natural symmetric group",
    true, [ IsNaturalSymmetricGroup, IsObject, IsObject, IsFunction ], 
  # the objects might be group elements: rank up	
  2*RankFilter(IsMultiplicativeElementWithInverse),
function ( G, d, e, opr )
local dom,n,sortfun,max,cd,ce,p1,p2;
  # test for internal rep
  if HasGeneratorsOfGroup(G) and 
    not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
    TryNextMethod();
  fi;

  dom:=Set(MovedPoints(G));
  n:=Length(dom);
  if opr=OnPoints then
    if IsInt(d) and IsInt(e) then
      if d in dom and e in dom then
	return (d,e);
      else
        return fail;
      fi;
    elif IsPerm(d) and IsPerm(e) and d in G and e in G then
      sortfun:=function(a,b) return Length(a)<Length(b);end;
      if Order(d)=1 then #LargestMovedPoint does not work for ().
        if Order(e)=1 then
	  return ();
	else
	  return fail;
	fi;
      fi;
      if CycleStructurePerm(d)<>CycleStructurePerm(e) then
        return fail;
      fi;
      max:=Maximum(LargestMovedPoint(d),LargestMovedPoint(e));
      cd:=ShallowCopy(Cycles(d,[1..max]));
      ce:=ShallowCopy(Cycles(e,[1..max]));
      Sort(cd,sortfun);
      Sort(ce,sortfun);
      return MappingPermListList(Concatenation(cd),Concatenation(ce));
    elif IsPermGroup(d) and IsPermGroup(e) 
      #and IsTransitive(d,dom) and IsTransitive(e,dom) 
      and IsSubset(G,d) and IsSubset(G,e) then

      if dom<>[1..n] then
	# translate
	p1:=MappingPermListList(dom,[1..n]);
	p2:=SubgpConjSymmgp(G^p1,d^p1,e^p1);
	if p2=false then
	    TryNextMethod();
	elif p2<>fail then
	  p2:=p2^Inverse(p1);
	fi;
	return p2;
      else
	p2:=SubgpConjSymmgp(G,d,e);
	if p2=false then
	  TryNextMethod();
	fi;
	return p2;
      fi;
    fi;
  elif (opr=OnSets or opr=OnTuples) and (IsDuplicateFreeList(d) and
    IsDuplicateFreeList(e)) then
    if Length(d)<>Length(e) then
      return fail;
    fi;
    if IsSubset(dom,Set(d)) and IsSubset(dom,Set(e)) then
      return MappingPermListList(d,e);
    fi;
  fi;
  TryNextMethod(); 
end);

InstallMethod( SylowSubgroupOp,
    "symmetric",
    true,
    [ IsNaturalSymmetricGroup, IsPosInt ], 0,
function ( G, p )
local   S,          # <p>-Sylow subgroup of <G>, result
	sgs,        # strong generating set of <G>
	q,          # power of <p>
	mov,deg,trf, # degree, moved points, transfer
	i;          # loop variable

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    mov:=MovedPoints(G);
    deg:=Length(mov);
    trf:=MappingPermListList([1..deg],mov);
    # make the strong generating set
    sgs := [];
    for i  in [1..deg]  do
        q := p;
        while i mod q = 0  do
            Add( sgs, PermList( Concatenation(
                        [1..i-q], [i-q+1+q/p..i], [i-q+1..i-q+q/p] ) )^trf );
            q := q * p;
        od;
    od;

    # make the Sylow subgroup
    S := Subgroup(  G , sgs );

    if Size( S ) > 1 then
        SetIsPGroup( S, true );
        SetPrimePGroup( S, p );
    fi;

    # return the Sylow subgroup
    return S;
end);

InstallMethod( ConjugacyClasses,
    "symmetric",
    true,
    [ IsNaturalSymmetricGroup ], 0,
function ( G )
    local   classes,    # conjugacy classes of <G>, result
            prt,        # partition of <G>
            sum,        # partial sum of the entries in <prt>
            rep,        # representative of a conjugacy class of <G>
	    mov,deg,trf, # degree, moved points, transfer
            i;          # loop variable

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    mov:=MovedPoints(G);
    deg:=Length(mov);
    trf:=MappingPermListList([1..deg],mov);
    # loop over the partitions
    classes := [];
    for prt  in Partitions( deg )  do

      # compute the representative of the conjugacy class
      rep := [2..deg];
      sum := 1;
      for i  in prt  do
	  rep[sum+i-1] := sum;
	  sum := sum + i;
      od;
      rep := PermList( rep )^trf;

      # add the new class to the list of classes
      Add( classes, ConjugacyClass( G, rep ) );

    od;

    # return the classes
    return classes;
end);

InstallMethod( IsomorphismFpGroup, "symmetric group", true,
    [ IsNaturalSymmetricGroup ], 0,
function(G)
  return IsomorphismFpGroup(G,
           Concatenation("S_",String(Length(MovedPoints(G))),".") );
end);

InstallOtherMethod( IsomorphismFpGroup, "symmetric group,name", true,
    [ IsNaturalSymmetricGroup,IsString ], 0,
function ( G,nam )
local   F,      # free group
	gens,	#generators of F
	imgs,
	hom,	# bijection
	mov,deg,
	relators,
	i, k;       # loop variables

    # test for internal rep
    if HasGeneratorsOfGroup(G) and 
      not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
      TryNextMethod();
    fi;

    mov:=MovedPoints(G);
    deg:=Length(mov);

    # create the finitely presented group with <G>.degree-1 generators
    F := FreeGroup( deg-1, nam );
    gens:=GeneratorsOfGroup(F);

    # add the relations according to the Coxeter presentation $a-b-c-...-d$
    relators := [];
    for i  in [1..deg-1]  do
        Add( relators, gens[i]^2 );
    od;
    for i  in [1..deg-2]  do
        Add( relators, (gens[i] * gens[i+1])^3 );
        for k  in [i+2..deg-1]  do
            Add( relators, (gens[i] * gens[k])^2 );
        od;
    od;

    F:=F/relators;

    SetSize(F,Size(G));
    UseIsomorphismRelation( G, F );

    # compute the bijection
    imgs:=[];
    for i in [2..deg] do
      Add(imgs,(mov[i-1],mov[i]));
    od;

    # return the isomorphism to the finitely presented group
    hom:= GroupHomomorphismByImagesNC(G,F,imgs,GeneratorsOfGroup(F));
    SetIsBijective( hom, true );
    return hom;
end);


#############################################################################
##
#M  ViewObj( <nat-sym-grp> )
##
InstallMethod( ViewString,
    "for natural alternating group",
    true,
    [ IsNaturalAlternatingGroup ], 0,
function(alt)
    alt:=MovedPoints(alt);
    if Length(alt)=0 then TryNextMethod();fi;
    IsRange(alt);
    return Concatenation( "Alt( ", String(alt), " )" );
end );

InstallMethod( ViewString,
    "for natural symmetric group",
    true,
    [ IsNaturalSymmetricGroup ], 0,
function(sym)
    sym:=MovedPoints(sym);
    if Length(sym)=0 then TryNextMethod();fi;
    IsRange(sym);
    return Concatenation( "Sym( ",String(sym), " )" );
end );

InstallMethod( ViewObj,
    "for natural alternating group",
    true,
    [ IsNaturalAlternatingGroup ], 0,
function(alt)
    Print(ViewString(alt));
end );

InstallMethod( ViewObj,
    "for natural symmetric group",
    true,
    [ IsNaturalSymmetricGroup ], 0,
function(sym)
    Print(ViewString(sym));
end );

#############################################################################
##
#M  PrintObj( <nat-sym-grp> )
##
InstallMethod( String,
    "for natural symmetric group",
    true,
    [ IsNaturalSymmetricGroup ], 0,
function(sym)
    sym:=MovedPoints(sym);
    if Length(sym)=0 then TryNextMethod();fi;
    IsRange(sym);
    return Concatenation( "SymmetricGroup( ",String(sym), " )" );
end );

InstallMethod( String,
    "for natural alternating group",
    true,
    [ IsNaturalAlternatingGroup ], 0,
function(alt)
    alt:=MovedPoints(alt);
    if Length(alt)=0 then TryNextMethod();fi;
    IsRange(alt);
    return Concatenation( "AlternatingGroup( ",String(alt), " )" );
end );

InstallMethod( PrintObj,
    "for natural alternating group",
    true,
    [ IsNaturalAlternatingGroup ], 0,
function(alt)
    Print(String(alt));
end );

InstallMethod( PrintObj,
    "for natural symmetric group",
    true,
    [ IsNaturalSymmetricGroup ], 0,
function(sym)
    Print(String(sym));
end );

#############################################################################
##
#M  SymmetricParentGroup( <grp> )
##
InstallMethod( SymmetricParentGroup,
    "symm(moved pts)",
    true,
    [ IsPermGroup ], 0,
    G -> SymmetricGroup( MovedPoints( G ) ) );

InstallMethod( SymmetricParentGroup,
    "natural symmetric group",
    true,
    [ IsNaturalSymmetricGroup ], 0,
    IdFunc );


#############################################################################
##
#M  OrbitStabilizingParentGroup( <grp> )
##
InstallMethod( OrbitStabilizingParentGroup, "direct product of S_n's",
    true, [ IsPermGroup ], 0,
function(G)
local o,d,i,j,l,s;
  o:=ShallowCopy(OrbitsDomain(G,MovedPoints(G)));
  Sort(o,function(a,b) return Length(a)<Length(b);end);
  d:=false;
  i:=1;
  while i<=Length(o) do
    l:=Length(o[i]);
    j:=i+1;
    while j<=Length(o) and Length(o[j])=l do
      j:=j+1;
    od;
    s:=SymmetricGroup(l);
    if j-1>i then
      s:=WreathProduct(s,SymmetricGroup(j-i));
    fi;
    if d=false then 
      d:=s;
    else
      d:=DirectProduct(d,s);
    fi;
    Assert(1,HasSize(d));
    i:=j;
  od;
  d:=ConjugateGroup(d,MappingPermListList(Set(MovedPoints(d)),
                                          Concatenation(o)));
  Assert(1,IsSubset(d,G));
  return d;
end);

InstallOtherMethod( StabChainOp, "symmetric group", true,
    [ IsNaturalSymmetricGroup,IsRecord ], 0,
function(G,r)
local dom, l, sgs, nondupbase;

  # test for internal rep
  if HasGeneratorsOfGroup(G) and 
    not ForAll(GeneratorsOfGroup(G),IsInternalRep) then
    TryNextMethod();
  fi;

  if IsBound(r.reduced) and r.reduced=false then
    TryNextMethod();
  fi;
  dom:=Set(MovedPoints(G));
  l:=Length(dom);
  if IsBound(r.base) then
    nondupbase:=DuplicateFreeList(r.base);
    dom:=Concatenation(Filtered(nondupbase,i->i in dom),Difference(dom,nondupbase));
  fi;
  sgs:=List([1..l-1],i->(dom[i],dom[l]));
  return StabChainBaseStrongGenerators(dom{[1..Length(dom)-1]},sgs,());
end);

#############################################################################
##
#M  AlternatingSubgroup( <grp> )
##
InstallMethod(AlternatingSubgroup,"for perm groups",true,[IsPermGroup],0,
function(G)
local a;
  if SignPermGroup(G)=1 then
    return G;
  fi;
  a:=DerivedSubgroup(G);
  if SignPermGroup(a)=1 and Index(G,a)=2 then
    return a;
  fi;
  # this is faster than intersecting with A_n, because no stabchain for A_n
  # needs to be built
  return SubgroupProperty(G,i->SignPerm(i)=1);
end);


#############################################################################
##
#E
