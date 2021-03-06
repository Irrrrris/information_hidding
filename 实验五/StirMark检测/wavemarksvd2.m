%这也是一个生成水印的函数,不完整,仅供其他函数调用
function [watermarkimagergb,watermarkimage,waterCA,watermark2,correlationU,correlationV]=wavemarksvd2(input,goal,seed,wavelet,level,alpha,ratio)
%读取原始图像
data=imread(input);
data=double(data)/255;
datared=data(:,:,1);%在R层加水印
%对原始图像的R层进行小波分解记录原始大小,并将其补成正方
[C,Sreal]=wavedec2(datared,level,wavelet);
[row,list]=size(datared);
standard1=max(row,list);
new=zeros(standard1,standard1);
if row<=list
   new(1:row,:)=datared;
else
   new(:,1:list)=datared;
end   
%正式开是加水印
%小波分解,提取低频系数
[C,S]=wavedec2(new,level,wavelet);
CA=appcoef2(C,S,wavelet,level);
%对低频系数进行归一化处理
[M,N]=size(CA);
CAmin=min(min(CA));
CAmax=max(max(CA));
CA=(1/(CAmax-CAmin))*(CA-CAmin);
d=max(size(CA));
%对低频率系数单值分解
[U,sigma,V]=svd(CA);
%按输出参数得到要替换的系数的数量
np=round(d*ratio);
%以下是随机正交矩阵的生成
rand('seed',seed);
M_V=rand(d,np)-0.5;
[Q_V,R_V]=qr(M_V,0);
M_U=rand(d,np)-0.5;
[Q_U,R_U]=qr(M_U,0);
%替换
V2=V;U2=U;
V(:,d-np+1:d)=Q_V(:,1:np);
U(:,d-np+1:d)=Q_U(:,1:np);
sigma_tilda=alpha*flipud(sort(rand(d,1)));
correlationU=corr2(U,U2);%计算替换的相关系数
correlationV=corr2(V,V2);
%生成水印
watermark=U*diag(sigma_tilda,0)*V';
%重构生成水印的形状,便于直观认识,本身无意义
watermark2=reshape(watermark,1,S(1,1)*S(1,2));
waterC=C;
waterC(1,1:S(1,1)*S(1,2))=watermark2;
watermark2=waverec2(waterC,S,wavelet);
%调整系数生成嵌入水印后的图片
CA_tilda=CA+watermark;
over1=find(CA_tilda>1);
below0=find(CA_tilda<0);
CA_tilda(over1)=1;
CA_tilda(below0)=0;%系数调整,将过幅与附数修正
CA_tilda=(CAmax-CAmin)*CA_tilda+CAmin;%系数还原到归一化以前的范围
%记录加有水印的低频系数
waterCA=CA_tilda;
if row<=list
   waterCA=waterCA(1:Sreal(1,1),:);
else
   waterCA=waterCA(:,1:Sreal(1,2));
end   
%重构
CA_tilda=reshape(CA_tilda,1,S(1,1)*S(1,2));
C(1,1:S(1,1)*S(1,2))=CA_tilda;
watermarkimage=waverec2(C,S,wavelet);
%将前面补上的边缘去掉
if row<=list
  watermarkimage=watermarkimage(1:row,:);
else
   watermarkimage=watermarkimage(:,1:list);
end   
watermarkimagergb=data;
watermarkimagergb(:,:,1)=watermarkimage;
imwrite(watermarkimagergb,goal,'BitDepth',16);%通过写回修正过幅系数
watermarkimagergb2=imread(goal);