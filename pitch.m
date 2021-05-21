clear all;
clc;
format compact


func("a.wav", 1); % file a , rectangle window
func("a.wav", 0); % file a , hamming window

func("f.wav", 1); % file f , rectangle window
func("f.wav", 0); % file f , hamming window


% baraye inke chand bar amaliat zir ra anjam midahim yek function misazim
function [] = func(audio_str, is_rectangle) 
    [y,Fs] = audioread(audio_str); %file ra azinja mikhanim

    if is_rectangle == 1 % baraye tashkhis esme panjare bar asase parametre is_rectangle
        win_name = 'rectangle';
    else
        win_name = 'hamming';
    end
    
    fprintf('~ %s - %s\n', audio_str, win_name);
    % Fs sampling frequency
    % Fs = 16KHz
    fprintf('Sampling Frequency (Fs): %d\n', Fs);

    % N = 16,000 * 0.025 = 400 samples
    N = 0.025 * Fs;
    fprintf('Number of Samples (N): %d\n', N);

    % Frame Shift = 40/100 * 400 = 160
    M = N * 40/100;
    fprintf('Frame Shift (M): %d\n', M);
    fprintf('\n\n');


    num_frames = round((length(y)- N)/M + 1) - 1; % tedad kole frame hara bedast miavarim

    ham_win=hamming(N); %yek window hamming be tedad N sample misazim
    rec_win=rectwin(N); %yek window rectangle be tedad N sample misazim
    
    if is_rectangle == 1 % baraye emal noe panjare bar asase parametre is_rectangle
        win = rec_win;
    else
        win = ham_win;
    end

    E = zeros(1,num_frames); % vector baraye zakhire Energy be tedad frame ha 0 initialize mikonim
    ZCR = zeros(1,num_frames); % vector baraye zakhire ZCR dar har frame
    pitch = zeros(1,num_frames); % vector baraye zakhire Pitch bedast amade az autocorrelation
    
    for i=1:num_frames % braye har frame amal zir ra anjam midahim
        s = y((i-1)*M + 1 : (i-1)*M + N);  %i th frame ra tashkhis midahim
        s = s.*win;  %window ra emal mikonim
        s = s - mean(s); % meghdar signal ra az miangin (dc) kam mikonim

        % Energy ra be dast miavarim bana bar ravabet
        E(i) = sum(s.*s)/N;

        %ZCR ra ham be komake rabete be sorate vectorized be dast miavarim
        diff = sign(s(2:num_frames)) - sign(s(1:num_frames-1));
        ZCR(i) = sum(abs(diff))/N;
    end
    
    %autocorr ra dar har frame be dast miavarim
    for i=1:num_frames
        s = y((i-1)*M + 1 : (i-1)*M + N);  %i th frame ra tashkhis midahim
        s = s.*win;  %window ra emal mikonim
        s = s - mean(s); % meghdar signal ra az miangin (dc) kam mikonim
        
        if E(i) > max(E)/4 % meghdar pitch ra dar frame haE ke energy bala daran hesab mikonim 
            corrs = zeros(1,N-1); % meghdar correlation hara inja zakhire mikonim
            for eta=0:N-1 % baraye eta az 0 ta N-1 bar asase ravabet moadele ra hesab mikonim
                res=0;
                for n=1:N
                    if n - eta <= 0 % agar n-eta dar frame mojod nabood az tahe frame dar nazar migirim 
                                    % tahe frame ra be khudash motasel
                                    % mikonim va maghadir ra be in sorat
                                    % hesab mikonim
                        res = res + s(n)*s(n-eta+N);
                    else % dar halat adi ham s(n)*s(n-eta) ra hesab mikonim
                        res = res + s(n)*s(n-eta);
                    end
                end
                corrs(eta+1)=res/N; % dar nahayat bar tedad (N) taghsim mikonim
            end

            [pks,locs]=findpeaks(corrs(1:N/2)); % dar inja peak haye maghadir correlation bedast amade ra hesab mikonim
            [arg, argmax] = max(pks); % bishtarin meghdar nesfe baze ra bedast miavarim (maghadir motagharen hastan)
            index = locs(argmax); % index max meghdar ra bedast miavarim ke I_pos mibashad

            if ~isempty(index) % dar baazi frame ha meghdar max peak vojod nadarad
                               % dar sorate vojod pitch ra az tarigh rabete hesab mikonim
               pitch(i) = Fs/index;
            else
               pitch(i) = NaN;
            end
        else % frame haE ke energy paEni daran meghdar pitch ra NaN migozarim ke f_pitch daghigh be dast biayad
            pitch(i) = NaN;
        end
    end
    
    % yek figure baraye har halat ijad mikonim
    figure('Name', sprintf('%s - %s', audio_str, win_name));
    subplot(2,2,1);
    plot(y); % khude signal speech ra rasm mikonim
    xlabel('Time');
    ylabel('Amplitude');
    xlim([0 size(y,1)])
    title(sprintf('Speech Signal %s', audio_str));
    
    subplot(2,2,2);
    plot(E); % energy bedast amade dar har frame ra rasm mikonim
    xlabel('Frames');
    ylabel('Energy');
    xlim([0 num_frames])
    title(sprintf('Energy %s', audio_str));

    subplot(2,2,3);
    plot(ZCR); % ZCR bedast amade dar har frame ra rasm mikonim
    xlabel('Frames');
    ylabel('ZCR');
    xlim([0 num_frames])
    title(sprintf('ZCR %s', audio_str));
    
    subplot(2,2,4);
    plot(pitch, 'b.'); % dar enteha ham pitch ra be sorate noghte E dar frame haE ke be dast avardim mikeshim
    xlabel('Frames');
    ylabel('Pitch (HZ)');
    xlim([0 num_frames])
    ylim([0 600])
    yticks(0:100:600);
    title(sprintf('Pitch %s', audio_str));
end

