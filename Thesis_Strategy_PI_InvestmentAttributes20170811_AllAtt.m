clear; clc

%% Abbreviations

% LP = Local population
% TP = Tourism population
% WasteLoc = tonne waste arising/ locals/ year in 2018
% WasteTou = tonne waste arising/ tourist / year in 2018


%% Curacao Data

load InvestmentAttribute.mat

% Demographics
LP = 158000;
TP = 6000;

% Waste arisings
WasteLoc = 0.5402;
WasteTou = 0.47815;
StartWaste = WasteLoc*LP + WasteTou*TP; %waste arising in 2018 in tonnes

%use bias correction; explain

%% Definitions

EndYear = 2050;
StartYear = 2018;
numYear = EndYear - StartYear+1;
Year = StartYear:EndYear;

%%  SCENARIOS (Growth rates are yearly 
% waste increases, due to a mixture of population and tourism growth)
% little growth waste arisings; gradual over time
% first Growthrate is initial waste arising -> specify this separately
Scenario(1).Growthrate = [
    2018,   1;
    2019,   1.015];

% medium growth: abrupt increase from 2020 until 2022 due to influx chinese as labour for
% refinery and gradual tourism increase
Scenario(2).Growthrate = [
    2018,   1;
    2019,   1.015;
    2020,   1.08;
    2022,   1.015];

% high growth: tourism increase growth first, then level down once
% environmental consequences can be seen
Scenario(3).Growthrate = [
    2018,   1;
    2019,   1.05;
    2025,   1.03;
    2035,   1.01];

numScen = length(Scenario);

%% Scenario analysis
% run through all scenarios to get % increase every year in one table
for countScen = 1:numScen
    Scenario(countScen).Growthrate(:,3) = Scenario(countScen).Growthrate(:,1)-StartYear+1;
    [Scenario(countScen).numGrowthrate,~] = size(Scenario(countScen).Growthrate);
    
    % Preallocate memory by creating vectors of zeros for period of years specified (numYear)
    Scenario(countScen).GrowthrateVector = zeros(numYear,2);
    Scenario(countScen).GrowthrateVector(:,1) = [StartYear:EndYear];
    
    for countGrowthrate = 1:Scenario(countScen).numGrowthrate
        
        if countGrowthrate ~= Scenario(countScen).numGrowthrate % if not in the final Growthrate
            
            Scenario(countScen).GrowthrateVector(Scenario(countScen).Growthrate(countGrowthrate,3): ...
                Scenario(countScen).Growthrate(countGrowthrate+1,3)-1,2) = ...
                Scenario(countScen).Growthrate(countGrowthrate,2);
           
        else
            Scenario(countScen).GrowthrateVector(Scenario(countScen).Growthrate(countGrowthrate,3):numYear,2)...
                = Scenario(countScen).Growthrate(countGrowthrate,2);
            
        end
    end
    
    % create vector with waste arisings in each year called Total waste
    Scenario(countScen).TotWasteVector = zeros(numYear,2);
    Scenario(countScen).TotWasteVector(1,2) = StartWaste;
    Scenario(countScen).TotWasteVector(:,1) = [StartYear:EndYear];
    
    for countYear = 2:numYear 
    
    Scenario(countScen).TotWasteVector(countYear,2) = ...
        Scenario(countScen).GrowthrateVector(countYear,2).*...
        Scenario(countScen).TotWasteVector(countYear-1,2);
    end
   
end


%% Strategy development
% Pipeline or business as usual
PI = {InvestmentAttribute.Properties.VariableNames{4:12}};

%'EnergyProduced' = InvestmentAttribute.EnergyProduced;
% PIvar = {InvestmentAttribute.Properties.VariableNames{6:9}};
PIvar = {PI{3:9}};

numPI = length(PI);
numPIvar = length(PIvar);

Strategy(1).name = 'Business as usual';
Strategy(2).name = 'Local initiative';
Strategy(3).name = 'Infrastructure Led';
numStrat = length(Strategy);

% Specify number/type investments which are part of which strategy 
Strategy(1).Investments = length((InvestmentAttribute.CAPEX(1:7)));
Strategy(2).Investments = length((InvestmentAttribute.CAPEX([1:4,8:11])));
Strategy(3).Investments = length((InvestmentAttribute.CAPEX([1:4,12:13])));

for countStrat = 1:numStrat
    for countPI = 1:numPI
        Strategy(countStrat).(PI{countPI}).Input = zeros(Strategy(countStrat).Investments,2);
    end
end
 
% add lifetime in forth column, adjust below 
%where strategyID
for countPI = 1:numPI
    Strategy(1).(PI{countPI}).Input = [InvestmentAttribute.YearInstall(1:7), InvestmentAttribute.(PI{countPI})(1:7)];
    Strategy(2).(PI{countPI}).Input = [InvestmentAttribute.YearInstall([1:4,8:11]), InvestmentAttribute.(PI{countPI})([1:4,8:11])];
    Strategy(3).(PI{countPI}).Input = [InvestmentAttribute.YearInstall([1:4,12:13]), InvestmentAttribute.(PI{countPI})([1:4,12:13])];
end 

%% Strategy analysis

%run through all strategies, all Performance Indicators in turn
for countStrat = 1:numStrat
    for countPI = 1:numPI
       
        Strategy(countStrat).(PI{countPI}).Input(:,3) = ...
            Strategy(countStrat).(PI{countPI}).Input(:,1)-StartYear+1;
        Input = sortrows(Strategy(countStrat).(PI{countPI}).Input);
        Vector = zeros(numYear,2);
        Vector(:,1) = [StartYear:EndYear];
        Vector(1,2) = Input(1,2);
        
        [Strategy(countStrat).(PI{countPI}).numInput, ~] = ...
            size(Strategy(countStrat).(PI{countPI}).Input);
 
        %insert relevant number from strategy development in the correct years
        for countInputs = 2:Strategy(countStrat).(PI{countPI}).numInput
            
            if Input(countInputs,1) == Input(countInputs-1,1)

                Vector(Input(countInputs,3):numYear,2) = ...
                    Input(countInputs,2)+Vector(Input(countInputs,3),2);
                
            else
                Vector(Input(countInputs,3):numYear,2) = Input(countInputs,2);
                
            end
           
        end
        Strategy(countStrat).(PI{countPI}).Vector = Vector;
    end
     
end

% multiply each strategy with % value from each scenario and add
for countStrat = 1:numStrat
    for countPI = 1:numPIvar
        for countScen = 1:numScen
            Strategy(countStrat).(PIvar{countPI}).Result(:,countScen) = ...
                Strategy(countStrat).(PIvar{countPI}).Vector(:,2) .*...
                Scenario(countScen).TotWasteVector(:,2);
        end
        Strategy(countStrat).(PIvar{countPI}).Sum = ...
            sum(Strategy(countStrat).(PIvar{countPI}).Result,1);
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        
        Strategy(countStrat).CAPEX.Result(:,countScen) = ...
            Strategy(countStrat).CAPEX.Vector(:,2) + ...
            Strategy(countStrat).OPEXStanding.Vector(:,2) +...
            Strategy(countStrat).OPEXVariable.Result(:,countScen);
        
    end
    Strategy(countStrat).CAPEX.Sum = ...
        sum(Strategy(countStrat).CAPEX.Result,1);
end

%% Create Plotting Matrix

for countStrat = 1:numStrat
    for countScen = 1:numScen
        EnergyProduced(countStrat,:) = [Strategy(countStrat).EnergyProduced.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        EmissionsAvoided(countStrat,:) = [Strategy(countStrat).EmissionsAvoided.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        WasteNoLandfill(countStrat,:) = [Strategy(countStrat).WasteNoLandfill.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        Cost(countStrat,:) = [Strategy(countStrat).CAPEX.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        Export(countStrat,:) = [Strategy(countStrat).PercWasteExp.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        MatRecov(countStrat,:) = [Strategy(countStrat).PercMatRecov.Sum];
    end
end

for countStrat = 1:numStrat
    for countScen = 1:numScen
        Plastic(countStrat,:) = [Strategy(countStrat).PercPlasticTreated.Sum];
    end
end



%% Plots  

figure(1)
bar(EnergyProduced)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('EnergyProduced generated')
ylabel('EnergyProduced generated in MW')


figure(2)
bar(WasteNoLandfill)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('% Waste not to landfill')


figure(3)
bar(EmissionsAvoided)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('Emissions avoided')
ylabel('CO2e emissions avoided')

figure(4)
bar(Cost)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('Cost')

figure(5)
bar(Export)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('% Waste Exported')

figure(6)
bar(MatRecov)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('% Materials Recovered')

figure(7)
bar(Plastic)
xticklabels({Strategy.name})
set(gca,'fontsize',15)
legend('Scenario 1','Scenario 2','Scenario 3','Location','northwest')
title('% Plastic Waste Treated')

figure(8)
plot(Scenario(1).TotWasteVector(:,1),Scenario(1).TotWasteVector(:,2),...
'-','LineWidth',4,...
'Color',[0.94 0.94 0.94])
set(gca,'fontsize',15)
str = sprintf('Solid Waste Generation Growth (Mt), %d - %d', StartYear, EndYear);
title (str)
xlabel ('Years')
ylabel('Waste in Mt')
hold on
plot(Scenario(2).TotWasteVector(:,1),Scenario(2).TotWasteVector(:,2),...
    '--','Color',[0.5 0.5 0.5],...
    'LineWidth',4)
plot(Scenario(3).TotWasteVector(:,1),Scenario(3).TotWasteVector(:,2),...
    ':','Color','k',...
    'LineWidth',4)
legend('Scenario 1','Scenario 2', 'Scenario 3', 'Location', 'northwest')
hold off


