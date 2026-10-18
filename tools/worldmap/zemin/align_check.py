"""Kullanım: python align_check.py <referans.jpg> <uretilen.png>
Üretilen haritanın referansa göre geometrik kaymasını SIFT + afin ile ölçer.
GEÇER ölçütü: ölçek sapması < %1.5, ortalama artık < 3 px (1400 px'e küçültülmüş karede)."""
import cv2,numpy as np,sys
a=cv2.imread(sys.argv[1]);b=cv2.imread(sys.argv[2])
S=1400;a=cv2.resize(a,(S,S));b=cv2.resize(b,(S,S))
g1=cv2.cvtColor(a,cv2.COLOR_BGR2GRAY);g2=cv2.cvtColor(b,cv2.COLOR_BGR2GRAY)
s=cv2.SIFT_create(6000);k1,d1=s.detectAndCompute(g1,None);k2,d2=s.detectAndCompute(g2,None)
m=cv2.BFMatcher().knnMatch(d1,d2,k=2);good=[x for x,y in m if x.distance<.75*y.distance]
if len(good)<30:print('YETERSIZ ESLESME',len(good),'-> stil çok değişmiş olabilir; maske kesişimi ile kontrol edin');sys.exit(2)
p1=np.float32([k1[g.queryIdx].pt for g in good]);p2=np.float32([k2[g.trainIdx].pt for g in good])
A,inl=cv2.estimateAffine2D(p1,p2,ransacReprojThreshold=5)
sx,sy=np.hypot(A[0,0],A[1,0]),np.hypot(A[0,1],A[1,1]);r=np.linalg.norm(cv2.transform(p1[None],A)[0]-p2,axis=1)[inl.ravel()==1]
print(f'eşleşme={len(good)} inlier={int(inl.sum())} ölçek=({sx:.3f},{sy:.3f}) kayma=({A[0,2]:.1f},{A[1,2]:.1f})px artık_ort={r.mean():.2f}px')
ok=abs(sx-1)<.015 and abs(sy-1)<.015 and r.mean()<3 and abs(A[0,2])<8 and abs(A[1,2])<8
print('GEÇER' if ok else 'GEÇMEZ');sys.exit(0 if ok else 1)
