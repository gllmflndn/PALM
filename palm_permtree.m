function [Pset,idx] = palm_permtree(Ptree,nP,cmc,idxout,maxP)
% Return a set of permutations from a permutation tree.
% 
% Usage:
% Pset = palm_permtree(Ptree,nP,cmc,idxout,maxP)
% 
% Inputs:
% - Ptree  : Tree with the dependence structure between
%            observations, as generated by 'palm_tree'.
% - nP     : Number of permutations. Use 0 for exhaustive.
% - cmc    : A boolean indicating whether conditional
%            Monte Carlo should be used or not. If not used,
%            there is a possibility of having repeated
%            permutations. The more possible permutations,
%            the less likely to find repetitions.
% - idxout : (Optional) is supplied, Pset is an array of indices
%            rather than a cell array with sparse matrices.
% - maxP   : (Optional) Maximum number of possible permutations.
%            If not supplied, it's calculated internally. If
%            supplied, it's not calculated internally and some
%            warnings that could be printed are omitted.
%            Also, this automatically allows nP>maxP (via CMC).
%
% Outputs:
% - Pset   : A cell array of size nP by 1 containing sparse
%            permutation matrices. If the option idxout is true
%            then it's an array of permutation indices.
% - idx    : Indices that allow sorting the branches of the
%            tree back to the original order. Useful to
%            reorder the sign-flips.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Oct/2013
% http://brainder.org

% Get the number of possible permutations.
% The 2nd output, idx, is for internal use only, so
% no need to print anything.
if nargout == 1 && nargin < 5,
    maxP = palm_maxshuf(Ptree,'perms');
    if nP > maxP,
        nP = maxP;
    end
end
if nargin < 4,
    idxout = false;
end

% Permutation #1 is no permutation, regardless.
P = pickperm(Ptree,[])';
P = horzcat(P,zeros(length(P),nP-1));

% All other permutations up to nP
if nP == 1,
    
    % Do nothing if only 1 permutation is to be done. This is
    % here only for speed and because of the idx output that is
    % used when sorting the sign-flips (palm_fliptree.m).
    
elseif nP == 0 || nP == maxP,

    % This will compute exhaustively all possible permutations,
    % shuffling one branch at a time. If nP is too large,
    % print a warning.
    if nP > 1e5 && nargin <= 3;
        warning([...
            'Number of possible permutations is %g.\n' ...
            '         Performing all exhaustively.'],maxP);
    end
    for p = 2:maxP,
        Ptree  = nextperm(Ptree);
        P(:,p) = pickperm(Ptree,[])';
    end
    
elseif cmc || nP > maxP,

    % Conditional Monte Carlo. Repeated permutations allowed.
    for p = 2:nP,
        Ptree  = randomperm(Ptree);
        P(:,p) = pickperm(Ptree,[])';
    end
    
else
    
    % Otherwise, repeated permutations are not allowed.
    % For this to work, maxP needs to be reasonably larger than
    % nP, otherwise it will take forever to run, so print a
    % warning.
    if nP > maxP/2 && nargin <= 3,
        warning([
            'The maximum number of permutations (%g) is not much larger than\n' ...
            'the number you chose to run (%d). This means it may take a while (from\n' ...
            'a few seconds to several minutes) to find non-repeated permutations.\n' ...
            'Consider instead running exhaustively all possible' ...
            'permutations. It may be faster.'],maxP,nP);
    end
    
    % For each perm, keeps trying to find a new, non-repeated
    % permutation.
    for p = 2:nP,
        whiletest = true;
        while whiletest,
            Ptree     = randomperm(Ptree);
            P(:,p)    = pickperm(Ptree,[])';
            whiletest = any(all(bsxfun(@eq,P(:,p),P(:,1:p-1))));
        end
    end
end

% The grouping into branches screws up the original order, which
% can be restored by noting that the 1st permutation is always
% the identity, so with indices 1:N. This same variable idx can
% be used to likewise fix the order of sign-flips (separate func).
[~,idx] = sort(P(:,1));
P = P(idx,:);

% For compatibility, convert each permutaion to a sparse permutation
% matrix. This section may be removed in the future if the
% remaining of the code is modified.
if idxout,
    Pset = P;
else
    Pset = cell(nP,1);
    for p = 1:nP,
        Pset{p} = palm_idx2perm(P(:,p));
    end
end

% ==============================================================
function [Ptree,flagsucs] = nextperm(Ptree)
% Make the next single shuffle of tree branches, and return
% the shuffled tree. This can be used to compute exhaustively
% all possible permutations.

% Some vars for later
nU   = size(Ptree,1);
sucs = false(nU,1);

% Make sure this isn't the last level (marked as NaN).
if size(Ptree,2) > 1,
    
    % For each branch of the current node
    for u = 1:nU,
        
        % If this is within-block at this level (marked as NaN),
        % go deeper without trying to shuffle things.
        [Ptree{u,3},sucs(u)] = nextperm(Ptree{u,3});
        if sucs(u),
            if u > 1,
                Ptree(1:u-1,:) = resetperms(Ptree(1:u-1,:));
            end
            break;
        elseif ~ isnan(Ptree{u,1}),
            Ptree{u,1}(:,3) = (1:size(Ptree{u,1},1))';
            [tmp,sucs(u)] = palm_nextperm(Ptree{u,1});
            if sucs(u),
                Ptree{u,1} = tmp;
                Ptree{u,3} = resetperms(Ptree{u,3});
                Ptree{u,3} = Ptree{u,3}(Ptree{u,1}(:,3),:);
                if u > 1,
                    Ptree(1:u-1,:) = resetperms(Ptree(1:u-1,:));
                end
                break;
            end
        end
    end
end

% Pass along to the upper level the information that all
% the branches at this node finished (or not).
flagsucs = any(sucs);

% ==============================================================
function Ptree = resetperms(Ptree)
% Recursively reset all permutations of a permutation tree
% back to the original state

if size(Ptree,2) > 1,
    for u = 1:size(Ptree,1),
        if isnan(Ptree{u,1}),
            Ptree{u,3} = resetperms(Ptree{u,3});
        else
            Ptree{u,1}(:,3) = Ptree{u,1}(:,2);
            [Ptree{u,1},idx] = sortrows(Ptree{u,1});
            Ptree{u,3} = Ptree{u,3}(idx,:);
            Ptree{u,3} = resetperms(Ptree{u,3});
        end
    end
end

% ==============================================================
function Ptree = randomperm(Ptree)
% Make a random shuffle of all branches in the tree.

% For each branch of the current node
nU = size(Ptree,1);
for u = 1:nU,
    
    % Make sure this isn't within-block at 1st level (marked as NaN)
    if ~ isnan(Ptree{u,1}(1)),
        tmp = Ptree{u,1}(:,1);
        Ptree{u,1} = Ptree{u,1}(randperm(size(Ptree{u,1},1)),:);
        
        % Only shuffle if at least one of the branches actually changes
        % its position (otherwise, repeated branches would be needlessly
        % shuffled, wasting permutations).
        if any(tmp ~= Ptree{u,1}(:,1)),
            Ptree{u,3} = Ptree{u,3}(Ptree{u,1}(:,3),:);
        end
    end

    % Make sure the next isn't the last level.
    if size(Ptree{u,3},2) > 1,
        Ptree{u,3} = randomperm(Ptree{u,3});
    end
end

% ==============================================================
function P = pickperm(Ptree,P)
% Take a tree in a given state and return the permutation. This
% won't permute, only return the indices for the already permuted
% tree. This function is recursive and for the 1st iteration,
% P = [], i.e., a 0x0 array.

nU = size(Ptree,1);
if size(Ptree,2) == 3,
    for u = 1:nU,
        P = pickperm(Ptree{u,3},P);
    end
elseif size(Ptree,2) == 1,
    for u = 1:nU,
        P(numel(P)+1:numel(P)+numel(Ptree{u,1})) = Ptree{u,1};
    end
end