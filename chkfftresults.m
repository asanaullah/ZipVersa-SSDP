fid = fopen('fftresult.bin','r');
dat = fread(fid, [2 inf], 'short');
size(dat)
fclose(fid);

fftln = 1024;
fq = (0:(fftln-1))/fftln;


figure;
idx = 0;
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 1;
figure;
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 2;
figure;
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 3;
fig=figure;
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));

waitfor(fig);
