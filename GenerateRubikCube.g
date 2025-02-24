PL:=ArchimedeanPolyhedra("Cube");

RecF:=RubikCubeFormalism(PL);

g:=RecF.GRP1;
u:=SylowSubgroup(RecF.GRP1, 2);
v:=u;


FileDC:="RubikCase";
output:=OutputTextFile(FileDC, true);
WriteGroup(output, RecF.nb1, g);
WriteGroup(output, RecF.nb1, u);
WriteGroup(output, RecF.nb1, v);
CloseStream(output);

