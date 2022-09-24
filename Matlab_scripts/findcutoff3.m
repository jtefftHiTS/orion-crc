function [cutoff,poscells] = findcutoff3(markersample,minval,FDR) 

%%input a vector of a particular marker, a minimum marker value, and chosen False Discovery Rate (FDR);
%%"minval" is for the purpose that some samples have a significant bump for
%%background, for whatever reason, so they should be cut if we stick to 2
%%distributions
    warning('off','all')
    
    tic
    GMMmodel = fitgmdist(markersample(markersample>minval),3,'replicates',20);
    toc
    
    minid = find(GMMmodel.mu==median(GMMmodel.mu));
    [~,maxid] = max(GMMmodel.mu);
    
    peak_min = normpdf(GMMmodel.mu(minid),GMMmodel.mu(minid),sqrt(GMMmodel.Sigma(minid)));
    peak_plus = normpdf(GMMmodel.mu(maxid),GMMmodel.mu(maxid),sqrt(GMMmodel.Sigma(maxid)));
    
    
    if GMMmodel.ComponentProportion(maxid)*peak_plus>GMMmodel.ComponentProportion(minid)*peak_min
        searchrange = prctile(markersample,2):0.01:prctile(markersample,70);
    else
        searchrange = prctile(markersample,50):0.01:prctile(markersample,98);
    end
    
    objfunc = searchrange;
    
    for searchid = 1:size(searchrange,2)
        objfunc(searchid) = (falserate3(searchrange(searchid),GMMmodel)-FDR)^2;
    end
    
    
    %figure,plot(searchrange,log(objfunc)) %this is a diagnostic line
    
    [~,minobj] = min(objfunc);
    cutoff = searchrange(minobj);
    
    %cutoff = fmincon(@(x) (falserate(x,GMMmodel)-FDR).^2,mean(markersample),[1 -1]',[prctile(markersample,99) -min(GMMmodel.mu)]);
    %cutoff = fzero(@(x) (falserate(x,GMMmodel)-FDR), mean(markersample));
    
    poscells = markersample>cutoff;
%% I'm plotting the results here; not sure how you want to incorporate this into your code
    
    figure()
    
    histogram(markersample,'Normalization','pdf')
    ylimits = ylim;
    hold on
    x = linspace(minval,max(markersample),1000);
    plot(x,pdf(GMMmodel,x'))
    
    plot(x,GMMmodel.ComponentProportion(maxid)*normpdf(x,GMMmodel.mu(maxid),sqrt(GMMmodel.Sigma(maxid))))
    plot(x,GMMmodel.ComponentProportion(minid)*normpdf(x,GMMmodel.mu(minid),sqrt(GMMmodel.Sigma(minid))))
    
    line([cutoff cutoff], ylimits, 'Color', 'r')
    text(cutoff,mean(ylimits),['cutoff=' num2str(cutoff,2) ', %pos=' num2str(100*sum(poscells)/length(poscells),2) ', FDR=' num2str(FDR+sqrt(min(objfunc)),2)])
    
    
end
    
    
    
    
    