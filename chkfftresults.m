fid = fopen('fftresult.bin','r');
dat = fread(fid, [2 inf], 'short');
size(dat)
fclose(fid);

fftln = 1024;
fq = (0:(fftln-1))/fftln;


fig = figure;
idx = 0;
subplot(2,2,1);
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 1;
subplot(2,2,2);
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 2;
subplot(2,2,3);
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));
idx = 3;
subplot(2,2,4);
plot(fq, dat(1,1+(idx*1024):(idx+1)*1024), fq, dat(2,1+(idx*1024):(idx+1)*1024));

waitfor(fig);
