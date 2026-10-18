import json,math,random,numpy as np,cv2
from scipy import ndimage as ndi
from skimage.graph import route_through_array
from skimage.measure import approximate_polygon
random.seed(11);np.random.seed(11)
m=np.load('../data/masks.npz');IW,IH=1176,1029
G=512;CELL=4096/G
def grid(mask):  # image mask -> world grid
    return cv2.resize(mask.astype(np.uint8),(G,G),interpolation=cv2.INTER_NEAREST).astype(bool)
water=grid(m['water']);mount=grid(m['mount']);forest=grid(m['forest'])&~water
mount&=~forest
# compass / scale-bar exclusion + border
excl=np.zeros((G,G),bool)
def img_rect(x0,y0,x1,y1):
    gx0,gx1=int(x0/IW*G),int(x1/IW*G);gy0,gy1=int(y0/IH*G),int(y1/IH*G);excl[gy0:gy1,gx0:gx1]=True
img_rect(20,760,260,1029);
b=int(150/CELL);excl[:b,:]=excl[-b:,:]=excl[:,:b]=excl[:,-b:]=True
land=~water
dw=ndi.distance_transform_edt(~water);dm=ndi.distance_transform_edt(~mount);df=ndi.distance_transform_edt(~forest);dnf=ndi.distance_transform_edt(forest);dl=ndi.distance_transform_edt(water)
data=json.load(open('../data/data_original_compact.json'));syms=[[s[0],s[1],s[2]] for s in data['syms']]
cl=lambda v:min(G-1,max(0,int(v/CELL)))
def cellxy(i,j):return (j+.5)*CELL,(i+.5)*CELL
# ---- 1. snap originals
moved=[]
for s in syms:
    i,j=cl(s[2]),cl(s[1])
    coastal=s[0] in('ic_portcity','iv_fishvillage')
    bad=water[i,j] or (coastal and dw[i,j]>12)
    if not bad:continue
    cand=land&~mount if coastal else land
    if coastal:cand=cand&(dw<=4)&(dw>=1)
    ii,jj=np.nonzero(cand);d=np.hypot(ii-i,jj-j)
    k=d.argmin();nx,ny=cellxy(ii[k],jj[k])
    moved.append((s[0],round(s[1]),round(s[2]),round(nx),round(ny),round(d[k]*CELL)));s[1],s[2]=round(nx,1),round(ny,1)
print('moved',len(moved));[print(' ',x) for x in moved]
stat={}
for s in syms:
    i,j=cl(s[2]),cl(s[1]);stat.setdefault(s[0],[]).append((int(water[i,j]),int(mount[i,j]),int(forest[i,j]),round(dw[i,j]*CELL)))
for k,v in stat.items():print(k,'water',sum(a for a,_,_,_ in v),'mount',sum(b for _,b,_,_ in v),'forest',sum(c for _,_,c,_ in v),'dw',[d for *_,d in v][:8])
placed=[(s[1],s[2]) for s in syms]
def far(x,y,d):return all(math.hypot(x-px,y-py)>=d for px,py in placed)
def pick(mask,n,dmin,sym,extra=None):
    ii,jj=np.nonzero(mask&~excl);idx=np.random.permutation(len(ii));c=0
    for t in idx:
        x,y=cellxy(ii[t],jj[t]);x+=random.uniform(-4,4);y+=random.uniform(-4,4)
        if far(x,y,dmin):
            syms.append([sym,round(x,1),round(y,1)]);placed.append((x,y));c+=1
            if c>=n:break
    print(sym,c)
plain=land&~mount&~forest&(dw>=3)&(dm>=2)
rivery=plain&(dw<=26)
pick(rivery,13,260,'iv_farm')
pick(plain,13,240,'ih_mezra')
pick(forest&(dnf<=1)&(dw>=3),7,230,'il_lumber')
pick(land&~mount&~forest&(dm<=3)&(dm>=1)&(dw>=4),5,300,'ia_abbey')
# ---- 2. roads
RANK={'ic_freecity':3,'ic_city':3,'ic_portcity':3,'it_town':2,'it_rivertown':2,'it_swamptown':2,'it_markettown':2,'iv_fishvillage':2,'it_minetown':2,'ie_deepmine':1.5,'ie_saltmine':1.5,'ix_mountaintribe':1,'in_yurtcamp':1,'in_khantent':1.2,'iv_farm':1,'ih_mezra':1,'il_lumber':1,'ia_abbey':1.2}
nodes=[s for s in syms if s[0] in RANK]
par=list(range(len(nodes)))
def f(i):
    while par[i]!=i:par[i]=par[par[i]];i=par[i]
    return i
for i in range(len(nodes)):
    for j in range(i+1,len(nodes)):
        if math.hypot(nodes[i][1]-nodes[j][1],nodes[i][2]-nodes[j][2])<150:par[f(i)]=f(j)
grp={}
for i,n in enumerate(nodes):grp.setdefault(f(i),[]).append(n)
hubs=[{'x':sum(n[1] for n in g)/len(g),'y':sum(n[2] for n in g)/len(g),'r':max(RANK[n[0]] for n in g)} for g in grp.values()]
print('hubs',len(hubs))
RG=256;RC=4096/RG
cost=np.ones((RG,RG),np.float32)
def down(a):return cv2.resize(a.astype(np.uint8),(RG,RG),interpolation=cv2.INTER_NEAREST).astype(bool)
cost[down(forest)]=1.8;cost[down(mount)]=3.6;cost[down(water)]=70
cost=cv2.GaussianBlur(cost,(0,0),.8)
rc=lambda v:min(RG-1,max(0,int(v/RC)))
def route(a,b):
    p,c=route_through_array(cost,(rc(a['y']),rc(a['x'])),(rc(b['y']),rc(b['x'])),fully_connected=True,geometric=True)
    nw=sum(1 for i,j in p if down(water)[i,j]) if False else sum(1 for i,j in p if wmask[i,j])
    return p,c,nw
wmask=down(water)
H=len(hubs);cands={}
for i,a in enumerate(hubs):
    ds=sorted(range(H),key=lambda j:math.hypot(a['x']-hubs[j]['x'],a['y']-hubs[j]['y']))[1:7]
    for j in ds:
        key=(min(i,j),max(i,j))
        if key in cands:continue
        p,c,nw=route(hubs[key[0]],hubs[key[1]])
        if nw<=3:cands[key]=(c,p)
print('cands',len(cands))
par2=list(range(H))
def f2(i):
    while par2[i]!=i:par2[i]=par2[par2[i]];i=par2[i]
    return i
E=set()
for key,(c,p) in sorted(cands.items(),key=lambda kv:kv[1][0]):
    if f2(key[0])!=f2(key[1]):par2[f2(key[0])]=f2(key[1]);E.add(key)
for i,a in enumerate(hubs):
    if a['r']<2:continue
    ks=sorted([k for k in cands if i in k and hubs[k[0]]['r']>=2 and hubs[k[1]]['r']>=2],key=lambda k:cands[k][0])[:2]
    for k in ks:E.add(k)
for i,a in enumerate(hubs):
    if a['r']<3:continue
    ks=sorted([k for k in cands if i in k and hubs[k[0]]['r']>=3 and hubs[k[1]]['r']>=3],key=lambda k:cands[k][0])[:2]
    for k in ks:E.add(k)
roads=[]
for k in E:
    c,p=cands[k];a,b=hubs[k[0]],hubs[k[1]]
    pts=np.array([[(j+.5)*RC,(i+.5)*RC] for i,j in p],np.float32)
    sg=2.0
    if len(pts)>6:
        pts[:,0]=ndi.gaussian_filter1d(pts[:,0],sg,mode='nearest');pts[:,1]=ndi.gaussian_filter1d(pts[:,1],sg,mode='nearest')
    pts[0]=(a['x'],a['y']);pts[-1]=(b['x'],b['y'])
    ap=approximate_polygon(pts,tolerance=9)
    mn,mx=sorted([a['r'],b['r']])
    cls='road' if (mn>=3 or (mx>=3 and mn>=2)) else 'trail'
    roads.append({'c':cls,'p':[[round(float(x),1),round(float(y),1)] for x,y in ap]})
print('roads',len(roads),sum(r['c']=='road' for r in roads))
# ---- 3. POIs along/around roads
def polyline_pts(r,step=30):
    out=[];P=r['p']
    for a,b in zip(P,P[1:]):
        L=math.hypot(b[0]-a[0],b[1]-a[1]);n=max(1,int(L/step))
        for t in range(n):out.append((a[0]+(b[0]-a[0])*t/n,a[1]+(b[1]-a[1])*t/n,b[0]-a[0],b[1]-a[1]))
    return out
allp=[(r,polyline_pts(r)) for r in roads]
def along(sym,n,dmin,cond,off=28):
    c=0;pool=[(r,p) for r,pp in allp for p in pp];random.shuffle(pool)
    for r,(x,y,dx,dy) in pool:
        L=math.hypot(dx,dy) or 1;side=random.choice([-1,1]);px,py=x-dy/L*off*side,y+dx/L*off*side
        i,j=cl(py),cl(px)
        if not(0<=i<G and 0<=j<G) or excl[i,j] or water[i,j]:continue
        if not cond(i,j):continue
        if far(px,py,dmin):
            syms.append([sym,round(px,1),round(py,1)]);placed.append((px,py));c+=1
            if c>=n:break
    print(sym,c)
along('iw_tower',10,230,lambda i,j:dm[i,j]<=3 and not mount[i,j] and not forest[i,j])
along('iw_fort',3,300,lambda i,j:not mount[i,j] and not forest[i,j],off=34)
# gallows near cities (on road, ~150px out)
cities=[h for h in hubs if h['r']>=3]
cnt=0
for h in random.sample(cities,len(cities)):
    cand=[(x,y,dx,dy) for r,pp in allp for (x,y,dx,dy) in pp if 110<math.hypot(x-h['x'],y-h['y'])<190]
    random.shuffle(cand)
    for x,y,dx,dy in cand:
        L=math.hypot(dx,dy) or 1;px,py=x-dy/L*30,y+dx/L*30;i,j=cl(py),cl(px)
        if not water[i,j] and not mount[i,j] and not forest[i,j] and not excl[i,j] and far(px,py,120):
            syms.append(['ig_gallows',round(px,1),round(py,1)]);placed.append((px,py));cnt+=1;break
    if cnt>=5:break
print('gallows',cnt)
# graveyards beside towns
towns=[h for h in hubs if 2<=h['r']<3];cnt=0
for h in random.sample(towns,len(towns)):
    for _ in range(40):
        a=random.uniform(0,6.28);d=random.uniform(100,160);px,py=h['x']+math.cos(a)*d,h['y']+math.sin(a)*d;i,j=cl(py),cl(px)
        if 0<i<G-1 and 0<j<G-1 and not water[i,j] and not mount[i,j] and not forest[i,j] and not excl[i,j] and far(px,py,120):
            syms.append(['ig_graveyard',round(px,1),round(py,1)]);placed.append((px,py));cnt+=1;break
    if cnt>=5:break
print('graveyard',cnt)
pick(mount&(dw>=3)&(dm>=0),7,260,'ir_ruins')
pick(plain&(dm<=12),5,360,'is_stones')
pick(land&~mount&~forest&(dw>=2)&(dw<=4),3,300,'ip_lighthouse')
pick(water&(dl>=4)&(dl<=14),4,380,'ix_wreck')
# battlefields: road midpoints on plains
cnt=0;long_=[r for r in roads if len(r['p'])>2];random.shuffle(long_)
for r in long_:
    P=r['p'];k=len(P)//2;x,y=P[k]
    px,py=x+random.uniform(-40,40),y+random.uniform(-40,40);i,j=cl(py),cl(px)
    if not water[i,j] and not mount[i,j] and not forest[i,j] and not excl[i,j] and far(px,py,170):
        syms.append(['ib_battle',round(px,1),round(py,1)]);placed.append((px,py));cnt+=1
    if cnt>=4:break
print('battle',cnt)
from collections import Counter
print(Counter(s[0] for s in syms),len(syms))
json.dump({'canvas':data['canvas'],'roads':roads,'syms':syms},open('../data/world.json','w'),separators=(',',':'))
# preview
im=cv2.imread('../images/source_1176x1029.jpg');im=cv2.resize(im,(1400,1400))
k=1400/4096
for r in roads:
    pts=np.array([[x*k,y*k] for x,y in r['p']],np.int32);cv2.polylines(im,[pts],False,(0,0,200) if r['c']=='road' else (200,0,0),2)
for s in syms:
    col=(0,140,0) if s[0] in RANK else (0,200,255);cv2.circle(im,(int(s[1]*k),int(s[2]*k)),5,col,-1)
cv2.imwrite('../images/world_preview.png',im)
