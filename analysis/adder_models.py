from gate_model import GateDAG


def preprocess(dag):
    g, p = [], []
    for i in range(16):
        g.append(dag.add_gate(f"G0[{i}]", "AND", f"A[{i}]", f"B[{i}]", f"RTL G0[{i}]"))
        p.append(dag.add_gate(f"P0[{i}]", "XOR", f"A[{i}]", f"B[{i}]", f"RTL P0[{i}]"))
    return g, p


def black(dag, name, gh, ph, gl, pl, rtl):
    t = dag.add_gate(name + ".and_g", "AND", ph, gl, rtl)
    gout = dag.add_gate(name + ".G", "OR", gh, t, rtl)
    pout = dag.add_gate(name + ".P", "AND", ph, pl, rtl)
    dag.metrics["black_cells"] += 1
    dag.metrics["prefix_cells"] += 1
    dag.mapping.append((name, rtl))
    return gout, pout


def gray(dag, name, gh, ph, gl, rtl):
    t = dag.add_gate(name + ".and_g", "AND", ph, gl, rtl)
    gout = dag.add_gate(name + ".G", "OR", gh, t, rtl)
    dag.metrics["gray_cells"] += 1
    dag.metrics["prefix_cells"] += 1
    dag.mapping.append((name, rtl))
    return gout


def carry(dag, name, g, p, cin, rtl):
    t = dag.add_gate(name + ".and_c", "AND", p, cin, rtl)
    cout = dag.add_gate(name + ".C", "OR", g, t, rtl)
    dag.metrics["local_carry_cells"] += 1
    dag.mapping.append((name, rtl))
    return cout


def finish(dag, p, c):
    for i in range(16):
        dag.set_output(i, dag.add_gate(f"SUM[{i}].xor", "XOR", p[i], c[i], f"SUM[{i}] = P0[{i}] ^ C[{i}]"))
    dag.set_output(16, c[16])
    dag.validate()
    return dag


def build_rca():
    d = GateDAG("RCA"); g, p = preprocess(d); c = ["CONST0"]
    for i in range(16): c.append(carry(d, f"rca.stage{i}", g[i], p[i], c[i], f"gen_rca_stage[{i}]"))
    return finish(d, p, c)


def build_ks():
    d = GateDAG("Kogge-Stone"); g, p = preprocess(d)
    for stage, distance in enumerate((1, 2, 4, 8), 1):
        ng, np = list(g), list(p)
        for i in range(distance, 16):
            ng[i], np[i] = black(d, f"ks.s{stage}.n{i}", g[i], p[i], g[i-distance], p[i-distance], f"stage{stage}[{i}].u_prefix")
        g, p_stage = ng, np
        p = p_stage
    c = ["CONST0"] + g
    # SUM uses the original preprocess P, not the final prefix P.
    p0 = [f"P0[{i}]" for i in range(16)]
    return finish(d, p0, c)


def build_bk():
    d = GateDAG("Brent-Kung"); g, p = preprocess(d)
    g10 = gray(d,"bk.u1_0",g[1],p[1],g[0],"up_sweep_stage1.u_1_0")
    pairs = {}
    for hi in (3,5,7,9,11,13,15): pairs[hi] = black(d,f"bk.u{hi}_{hi-1}",g[hi],p[hi],g[hi-1],p[hi-1],f"up_sweep_stage1.u_{hi}_{hi-1}")
    g30=gray(d,"bk.u3_0",pairs[3][0],pairs[3][1],g10,"up_sweep_stage2.u_3_0")
    groups4={}
    for hi,lo in ((7,5),(11,9),(15,13)): groups4[hi]=black(d,f"bk.u{hi}_{hi-3}",pairs[hi][0],pairs[hi][1],pairs[lo][0],pairs[lo][1],f"up_sweep_stage2.u_{hi}_{hi-3}")
    g70=gray(d,"bk.u7_0",groups4[7][0],groups4[7][1],g30,"up_sweep_stage3.u_7_0")
    g158=black(d,"bk.u15_8",groups4[15][0],groups4[15][1],groups4[11][0],groups4[11][1],"up_sweep_stage3.u_15_8")
    g150=gray(d,"bk.u15_0",g158[0],g158[1],g70,"up_sweep_stage4.u_15_0")
    g110=gray(d,"bk.u11_0",groups4[11][0],groups4[11][1],g70,"down_sweep_stage5.u_11_0")
    g50=gray(d,"bk.u5_0",pairs[5][0],pairs[5][1],g30,"down_sweep_stage6.u_5_0")
    g90=gray(d,"bk.u9_0",pairs[9][0],pairs[9][1],g70,"down_sweep_stage6.u_9_0")
    g130=gray(d,"bk.u13_0",pairs[13][0],pairs[13][1],g110,"down_sweep_stage6.u_13_0")
    evens={2:g10,4:g30,6:g50,8:g70,10:g90,12:g110,14:g130}
    odd_prefix={}
    for hi in (2,4,6,8,10,12,14): odd_prefix[hi]=gray(d,f"bk.u{hi}_0",g[hi],p[hi],evens[hi],f"down_sweep_stage7.u_{hi}_0")
    c=["CONST0",g[0],g10,odd_prefix[2],g30,odd_prefix[4],g50,odd_prefix[6],g70,odd_prefix[8],g90,odd_prefix[10],g110,odd_prefix[12],g130,odd_prefix[14],g150]
    return finish(d,p,c)


def group_tree(d, g, p, size, prefix):
    current=list(zip(g,p)); level=1
    while len(current)>1:
        nxt=[]
        for j in range(0,len(current),2):
            lo=current[j]; hi=current[j+1]
            nxt.append(black(d,f"{prefix}.l{level}.n{j//2}",hi[0],hi[1],lo[0],lo[1],f"{prefix}.level{level}[{j//2}]"))
        current=nxt; level+=1
    return current[0]


def sparse_model(size):
    d=GateDAG(f"Sparse-{size}"); g,p=preprocess(d); groups=[]
    for k in range(16//size): groups.append(group_tree(d,g[k*size:(k+1)*size],p[k*size:(k+1)*size],size,f"sparse{size}.group{k}"))
    gg=[x[0] for x in groups]; gp=[x[1] for x in groups]
    distance=1; stage=1
    while distance<len(groups):
        ng, np=list(gg),list(gp)
        for i in range(distance,len(groups)):
            ng[i],np[i]=black(d,f"sparse{size}.ks{stage}.n{i}",gg[i],gp[i],gg[i-distance],gp[i-distance],f"intergroup_stage{stage}[{i}].u_prefix")
        gg,gp=ng,np;distance*=2;stage+=1
    c=[None]*17;c[0]="CONST0"
    for k in range(16//size):
        for step in range(size-1):
            bit=k*size+step
            c[bit+1]=carry(d,f"sparse{size}.local.g{k}.c{step+1}",g[bit],p[bit],c[bit],f"local_ripple[{k}].step[{step}]")
        c[(k+1)*size]=gg[k]
    return finish(d,p,c)


def build_hc():
    d=GateDAG("Han-Carlson");g,p=preprocess(d)
    g1=[];p1=[None]*8
    g1.append(gray(d,"hc.s1.n0",g[1],p[1],g[0],"stage1[0].gray.u_cell"))
    for i in range(1,8): g1i,p1[i]=black(d,f"hc.s1.n{i}",g[2*i+1],p[2*i+1],g[2*i],p[2*i],f"stage1[{i}].black.u_cell");g1.append(g1i)
    g2=[g1[0]]+[None]*7;p2=[None]*8
    g2[1]=gray(d,"hc.s2.n1",g1[1],p1[1],g1[0],"stage2[1].gray.u_cell")
    for i in range(2,8): g2[i],p2[i]=black(d,f"hc.s2.n{i}",g1[i],p1[i],g1[i-1],p1[i-1],f"stage2[{i}].black.u_cell")
    g3=g2[:2]+[None]*6;p3=[None]*8
    for i in (2,3): g3[i]=gray(d,f"hc.s3.n{i}",g2[i],p2[i],g2[i-2],f"stage3[{i}].gray.u_cell")
    for i in range(4,8): g3[i],p3[i]=black(d,f"hc.s3.n{i}",g2[i],p2[i],g2[i-2],p2[i-2],f"stage3[{i}].black.u_cell")
    g4=g3[:4]+[None]*4
    for i in range(4,8): g4[i]=gray(d,f"hc.s4.n{i}",g3[i],p3[i],g3[i-4],f"stage4[{i}].u_cell")
    c=[None]*17;c[0]="CONST0";c[1]=g[0]
    for k in range(8): c[2*k+2]=g4[k]
    for bit in (2,4,6,8,10,12,14): c[bit+1]=gray(d,f"hc.s5.c{bit+1}",g[bit],p[bit],c[bit],f"stage5.u_c{bit+1}")
    return finish(d,p,c)


def build_all():
    return [build_rca(), build_ks(), build_bk(), sparse_model(2), sparse_model(4), sparse_model(8), build_hc()]
