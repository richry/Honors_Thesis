% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu


%% Batch Reports and exclusions

% Prep Stuff
clear
clc

number = int2str(1);
load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
load(load_name);

% Build the two batch reports and fill in the left (lables)

Class_Report_Card_Pass = {};
Class_Report_Card_Pass{1,1} = "Subject Number";
Class_Report_Card_Pass(3:41,1) = report_card(1:39,1);

Class_Report_Card_Fail = {};
Class_Report_Card_Fail{1,1} = "Subject Number";
Class_Report_Card_Fail(3:41,1) = report_card(1:39,1);

% we don't want any empty cells to mess up our stats, so this prevents that
pass_helper = 2;
fail_helper =2;

for i = 1:40
    
    number = int2str(i);
    load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    load(load_name);
    
    Sub_ID = strcat('Sub_', number);
    
    % if they pass all of the exclusion criteria, put them in one batch
    % relational operators (==, >, <, ~=) don't play nice with chars or
    % strings, they work elementally and need equal size, to get around
    % this, we only look at the first letter so size is always 1
    if report_card{4,2}(1) == 'n' & report_card{8,2}(1) == 'N' & report_card{12,2}(1) == 'N' & report_card{17,2}(1) == 'n' & report_card{21,2}(1) == 'n' & report_card{25,2}(1) == 'n'
       Class_Report_Card_Pass{1,pass_helper} = Sub_ID;
       Class_Report_Card_Pass(3:41,pass_helper) = report_card(1:39,2);
       pass_helper = pass_helper+1;
    % if they fail any of the exclusion criteria, put them in the other   
    else
       Class_Report_Card_Fail{1,fail_helper} = Sub_ID;
       Class_Report_Card_Fail(3:41,fail_helper) = report_card(1:39,2);
       fail_helper = fail_helper+1;
    end
end

% Save everything
class_report_card_pass_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','_Combined_Master_Report_Card.mat');
save(class_report_card_pass_save_name,'Class_Report_Card_Pass');

class_report_card_pass_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','_Combined_Master_Reject_Report_Card.mat');
save(class_report_card_pass_save_name,'Class_Report_Card_Fail');
    
%% Class Metrics (not data class, like classroom, like all of the passing data)

% build the top row of lables
supplimental = {};
supplimental{1,2} = 'Mean';
supplimental{1,3} = 'Median';
supplimental{1,4} = 'Mode';
supplimental{1,5} = 'Max';
supplimental{1,6} = 'Min';
supplimental{1,7} = 'SD';
supplimental{1,8} = 'Outliers: Count';
supplimental{1,9} = 'Outliers: Sub ID(s)';

% build the left lables
supplimental(3:41,1) = report_card(1:39,1);

dimensions = size(Class_Report_Card_Pass);

% These are the rows with values we care about
values = [4,5,17,18,22,26,29,32,34,37,40,41];

% Do all of the math on those rows
for i = 1:length(values)
    for l = values(i)
        supplimental{l,2} = mean([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        supplimental{l,3} = median([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        supplimental{l,4} = mode([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        supplimental{l,5} = max([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        supplimental{l,6} = min([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        supplimental{l,7} = std([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        
        outlier_list = isoutlier([Class_Report_Card_Pass{l,2:dimensions(2)}]);
        
        supplimental{l,8} = sum(outlier_list(:) == 1);
        
        outlier_index = find(outlier_list);
        
        % this lil for loop took so long and I'm not sure it's worth it - I
        % both love and hate cell arrays
        for r = 1:length(outlier_index)
            supplimental{l,9} = [[supplimental{l,9}], ', ',[Class_Report_Card_Pass{1,outlier_index(r)+1}]];
        end
    end
end

% there were 41 rows and we only care about 12 of them, so this just pulls
% out the important info for easy viewing
helper = 1;

pretty_supplimental = {};
pretty_supplimental(1,:) = supplimental(1,:);

for i = 1:length(values)
    for l = values(i)
        helper = helper+1;
        pretty_supplimental(helper,:) = supplimental(l,:);
    end
end
        
% don't forget to save kids (I do all the time and get confused)        
supplimental_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','_Combined_Master_Final_Metrics_Card.mat');
save(supplimental_save_name,'pretty_supplimental');     

%% Graphs/Plots

accuracy_helper = ones(1,pass_helper-2);
accuracy_helper = accuracy_helper-[Class_Report_Card_Pass{29,2:pass_helper-1}];

final_matrix = [];
final_matrix(1,:) = accuracy_helper;
final_matrix(2,:) = [Class_Report_Card_Pass{37,2:pass_helper-1}];
final_matrix = final_matrix.';


boxplot(final_matrix,'Labels',{'Origional','Test: Scrambled'})
title('SVM Classification Accuracy: Faces v. Cars')
ylabel('Accuracy')

plot_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Origional_v_Scrambled_Plot.jpg');
saveas(gcf,plot_save_name)

close(gcf)
    