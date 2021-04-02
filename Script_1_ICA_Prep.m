% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu
%% All the fun pre-run loading and stuff

%***Note***
% a line of stars (**********) indicates that the command beneith it will
% need to be updated with the proper information from each new/different
% dataset

clear
clc


%we have got to use this way of starting EEGLab (with the GUI) otherwise it
%keeps the history of the last thing that was processed with tht GUI, as in
%it doesn't empty ALLEEG, and if you run eegh, it prints off the last
%history
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

name = '_N170.set';

%start the big boy loop
for i = 1:40
    number = int2str(i);
    file_name = strcat(number,name);
    file_path = strcat('C:\\Users\\ryrich\\Documents\\Honors Thesis\\Practice_Dataset\\','Subject_',number);
    
    EEG = pop_loadset('filename',file_name,'filepath',file_path);
    
    % I can't put it into words but this index needs to be 1 not 0
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
    EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\ryrich\\Documents\\Honors Thesis\\Practice_Dataset\\standard-10-5-cap385.elp');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %% Pull out the pre-reject channel info
    %okay, so this has to hapen before any channels have been removed - for
    %some reason, it's buggy with logging removed channel names- so I built my
    %own removed channel name log
    length_pre_clean = size(EEG.chanlocs);
    chan_cell = struct2cell(EEG.chanlocs);
    locs_pre_clean = {};

    for i = 1:length_pre_clean(2)
        locs_pre_clean{i,1} = chan_cell{1,i};
    end
    
    %% Standard Early Pre-proc stuff
    
    %**********************************************************************
    %This will need to be updated with both the number of events and the
    %shift length/direction for each new dataset
    EEG  = pop_erplabShiftEventCodes( EEG , 'DisplayEEG', 0, 'DisplayFeedback', 'both', 'Eventcodes',  1:180, 'Rounding', 'earlier', 'Timeshift',  26 ); % GUI: 06-Jan-2021 15:40:54
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    
    %**********************************************************************
    %This will need to be updated for each new dataset depending on
    %origional sampling frequency
    EEG = pop_resample( EEG, 512);
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    EEG  = pop_basicfilter( EEG,  1:33 , 'Boundary', 'boundary', 'Cutoff',  0.1, 'Design', 'butter', 'Filter', 'highpass', 'Order',  2, 'RemoveDC', 'on' ); % GUI: 06-Jan-2021 15:42:04
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    EEG  = pop_basicfilter( EEG,  1:33 , 'Boundary', 'boundary', 'Cutoff',  100, 'Design', 'fir', 'Filter', 'lowpass', 'Order',  36, 'RemoveDC', 'on' ); % GUI: 06-Jan-2021 15:42:26
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    EEG  = pop_basicfilter( EEG,  1:33 , 'Boundary', 'boundary', 'Cutoff',  60, 'Design', 'notch', 'Filter', 'PMnotch', 'Order',  180, 'RemoveDC', 'on' ); % GUI: 06-Jan-2021 15:42:47
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %**********************************************************************
    %we skip the last 3 because they will always be the EOG channels -
    %will need to change for each dataset accordingly
    EEG = pop_rejchan(EEG, 'elec',[1:EEG.nbchan-3] ,'threshold',5,'norm','on','measure','prob'); %********** found prob, changed, fixed?
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_rejchan(EEG, 'elec',[1:EEG.nbchan-3] ,'threshold',5,'norm','on','measure','prob'); %********** found prob, changed, fixed?
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_rejchan(EEG, 'elec',[1:EEG.nbchan-3] ,'threshold',5,'norm','on','measure','prob'); %********** found prob, changed, fixed?
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    %% Pull pre and post reject channel info, compare
    
    %then this has to happen after channels have been removed
    length_post_clean = size(EEG.chanlocs);
    chan_cell = struct2cell(EEG.chanlocs);
    locs_post_clean = {};
    for i = 1:length_post_clean(2)
        locs_post_clean{i,1} = chan_cell{1,i};
    end
    
        removed_chans = locs_pre_clean; 
    for r = 1:length_pre_clean(2)
        x = convertCharsToStrings(locs_pre_clean{r,1});
        for y = 1:length_post_clean(2)
            t = convertCharsToStrings(locs_post_clean{y,1});
            if x == t
                removed_chans{r,1} = 0;
            end
        end
    end
    
    %% Start the report Card
    
    %EEG.chaninfo.removedchans is acting really buggy in several ways, so
    %we built our own
    report_card = {};
    report_card{1,1} = 'Rejected Channels 0=no Chan Name=yes';
    report_card{1,2} = removed_chans; %EEG.chaninfo.removedchans;
    
    report_card{2,1} = '# of Rejected Chans';
    report_card_chan_length = length(report_card{1,2});
    helper = 0;
    for i = 1:report_card_chan_length
        if report_card{1,2}{i,1} ~= 0
            helper = helper +1;
        end
    end
    report_card{2,2} = helper;
    
    report_card{3,1} = 'Percent Chans Rejected';
    report_card{3,2} = report_card{2,2}/report_card_chan_length;
    
    report_card{4,1} = 'Subject Reject?';
    if report_card{3,2} >= .30
        report_card{4,2} = 'YES';
    else
        report_card{4,2} = 'no';
    end
        
    
    %% More Standard Pre-Processing
    
    EEG  = pop_erplabDeleteTimeSegments( EEG , 'displayEEG',  0, 'endEventcodeBufferMS',  0, 'ignoreUseType', 'ignore', 'startEventcodeBufferMS',  0, 'timeThresholdMS',  2000 ); % GUI: 06-Jan-2021 15:48:38
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); % GUI: 06-Jan-2021 15:50:13
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %**********************************************************************
    %we skip the last 3 because they will always be the EOG channels -
    %will need to change for each dataset accordingly
    EEG = pop_reref( EEG, [],'exclude',[EEG.nbchan-2:EEG.nbchan] );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %**********************************************************************
    %will need to update for each new/diff dataset
    EEG = pop_epoch( EEG, {  '1'  '2'  '3'  '4'  '5'  '6'  '7'  '8'  '9'  '10'  '11'  '12'  '13'  '14'  '15'  '16'  '17'  '18'  '19'  '20'  '21'  '22'  '23'  '24'  '25'  '26'  '27'  '28'  '29'  '30'  '31'  '32'  '33'  '34'  '35'  '36'  '37'  '38'  '39'  '40'  '41'  '42'  '43'  '44'  '45'  '46'  '47'  '48'  '49'  '50'  '51'  '52'  '53'  '54'  '55'  '56'  '57'  '58'  '59'  '60'  '61'  '62'  '63'  '64'  '65'  '66'  '67'  '68'  '69'  '70'  '71'  '72'  '73'  '74'  '75'  '76'  '77'  '78'  '79'  '80'  '101'  '102'  '103'  '104'  '105'  '106'  '107'  '108'  '109'  '110'  '111'  '112'  '113'  '114'  '115'  '116'  '117'  '118'  '119'  '120'  '121'  '122'  '123'  '124'  '125'  '126'  '127'  '128'  '129'  '130'  '131'  '132'  '133'  '134'  '135'  '136'  '137'  '138'  '139'  '140'  '141'  '142'  '143'  '144'  '145'  '146'  '147'  '148'  '149'  '150'  '151'  '152'  '153'  '154'  '155'  '156'  '157'  '158'  '159'  '160'  '161'  '162'  '163'  '164'  '165'  '166'  '167'  '168'  '169'  '170'  '171'  '172'  '173'  '174'  '175'  '176'  '177'  '178'  '179'  '180'  }, [-0.7         0.7], 'newname', 'epoched_and_ready_for_ICA', 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %% Save all the things
    
    save_name = strcat('1_',number,'_N170_Prepped_for_ICA');
    save_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\');
    EEG = pop_saveset( EEG, 'filename',save_name,'filepath',save_path);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    report_card_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    save(report_card_save_name,'report_card');
    
end

erplab redraw
eeglab redraw