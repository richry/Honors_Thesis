% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu

%%

clear
clc

load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Temporal_Shifting_50ms_Master_All.mat');
load(load_name);

load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Temporal_Growing_50ms_Master_All.mat');
load(load_name);

shifting_size = size(shifting_matrix);
growing_size = size(growing_matrix);

shifting_accuracy = ones(shifting_size(1)-1,shifting_size(2)-1);
growing_accuracy = ones(growing_size(1)-1, growing_size(2)-1);

shifting_helper = cell2mat(shifting_matrix(2:end,2:end));
growing_helper = cell2mat(growing_matrix(2:end,2:end));

shifting_accuracy = shifting_accuracy - shifting_helper;
growing_accuracy = growing_accuracy - growing_helper;

shifting_accuracy = [shifting_accuracy(1:7,:);shifting_accuracy(9:end,:)];
growing_accuracy = [growing_accuracy(1:7,:);growing_accuracy(9:end,:)];


boxplot(shifting_accuracy,'Labels',{shifting_matrix{1,2:end}},'LabelOrientation','inline');
title('SVM Classification Accuracy: Moving 50ms Window')
xlabel('Time Window')
ylabel('Accuracy')

plot_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Moving_50ms_Plot.pdf');
saveas(gcf,plot_save_name)

close(gcf)

boxplot(growing_accuracy,'Labels',{growing_matrix{1,2:end}},'LabelOrientation','inline');
title('SVM Classification Accuracy: Increasing 50ms Window')
xlabel('Time Window')
ylabel('Accuracy')

plot_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Increasing_50ms_Plot.pdf');
saveas(gcf,plot_save_name)

close(gcf)


