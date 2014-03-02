function palm(varargin)
% ===========================================
% PALM: Permutation Analysis of Linear Models
% ===========================================
%
% PALM performs permutation inference for the general linear
% models (GLMs) of arbitrary complexity, taking as inputs data
% in various formats, and being able to take into account certain
% cases of well-structured non-independence.
%
% The options are:
%
% -i <file>         : Input(s). More than one can be specified, each one
%                     preceded by its own -i. All input files must
%                     contain the same number of observations (e.g., the
%                     same number of subjects). Except for NPC, mixing
%                     is allowed (e.g., voxelwise, vertexwise and
%                     non-imaging data can be all loaded at once, and
%                     later will be all corrected across).
% -m <file>         : Mask(s). Either one for all inputs, or one per
%                     input, supplied in the same order as the
%                     respective -i appear.
% -s <file>         : Surface file(s). When more than one is supplied,
%                     each -s should be entered in the same order as the
%                     respective -i. This option is needed when the
%                     input data is a scalar field over a surface and
%                     spatial statistics (cluster extent, cluster mass
%                     or TFCE) have been enabled.
% -d <file>         : Design matrix. It can be in CSV or VEST format.
%                     For information on how to construct the design
%                     matrix, see the FSL GLM manual.
% -t <file>         : t-contrasts file, in CSV or VEST format. The
%                     option -t can be used more than once, so that more
%                     than one t-contrasts file can be loaded.
% -f <file>         : F-contrasts file, in CSV or VEST format.
%                     The option -f can be used more than once, so that
%                     more than one F-contrasts file can be loaded.
%                     Each file supplied with a -f corresponds to the
%                     file supplied with the option -t in the same
%                     order. The option -f cannot be used more than the
%                     number of times the option -t was used.
% -inormal          : Apply an inverse-normal transformation to the data
%                     using the Waerden method.
% -rmethod <string> : Method for regression/permutation. It can be one
%                     of: Freedman-Lane, Smith, terBraak, Manly,
%                     Draper-Stoneman, Still-White and Huh-Jhun.
%                     Default, and recommended, is Freedman-Lane.
% -n <integer>      : Number of permutations. Use -n 0 to run all
%                     permutations and/or sign-flips exhaustively.
% -eb <file>        : Exchangeability blocks file, in csv or vest
%                     format. If omitted, all observations are treated
%                     as exchangeable and belonging to a single large
%                     exchangeability block.
% -sb               : Permute blocks as a whole if the block
%                     specification has a single column. Otherwise,
%                     permutations will happen within block.
% -vg <file>        : Variance groups file, in csv or vest format.
%                     If omitted, the variance groups are defined
%                     automatically using the exchangeability blocks
%                     (option -eb).
% -ee               : Assume exchangeable errors (ee), to allow
%                     permutations.
% -ise              : Assume independent and symmetric errors (ise),
%                     to allow sign-flipping.
% -cmc              : Use Conditional Monte Carlo. This option will be
%                     ignored if the number of shufflings chosen is
%                     larger than the maximum number of possible
%                     shufflings, in which case all possible shufflings
%                     will be performed.
% -npc              : Use non-parametric combination (NPC).
% -cmethod <string> : Method for combination in the NPC. It can be one
%                     of: Tippett, Fisher, Pearson-David, Stouffer,
%                     Wilkinson <alpha>, Winer, Edgington,
%                     Mudholkar-George, Friston, Darlington-Hayes <r>,
%                     Zaykin <alpha>, Dudbridge-Koeleman <r>,
%                     Dudbridge-Koeleman2 <r> <alpha>, Nichols,
%                     Taylor-Tibshirani or Jiang <alpha>.
%                     Default is Tippett.
%                     Note that some methods require 1 or 2 additional
%                     parameters to be provided.
% -o <string>       : Output prefix. It may itself be prefixed by a
%                     path. Default is 'palm'.
% -c <real>         : Enable cluster extent for t contrasts, with the
%                     supplied cluster-forming threshold.
% -C <real>         : Enable cluster mass for t contrasts, with the
%                     supplied cluster-forming threshold.
% -F <positive>     : Enable cluster extent for F contrasts, with the
%                     supplied cluster-forming threshold.
% -S <positive>     : Enable cluster mass for F contrasts, with the
%                     supplied cluster-forming threshold.
% -T                : Enable TFCE inference for 3D (volume) data,
%                     i.e., with H = 2, E = 0.5, C = 6.
% -T2               : Enable TFCE inference for 2D (surface, TBSS) data,
%                     i.e., H = 2, E = 1, C = 26.
% -cnpc <real>      : Enable NPC cluster extent, with the supplied
%                     cluster-forming threshold (z-stat).
% -Cnpc <real>      : Enable NPC cluster mass, with the supplied
%                     cluster-forming threshold (z-stat).
% -Tnpc             : Enable TFCE inference for NPC on 3D data,
%                     with H = 2, E = 0.5, C = 6.
% -T2npc            : Enable TFCE inference for NPC on 2D data,
%                     i.e., H = 2, E = 1, C = 26.
% -tfce_H <real>    : Set the TFCE H parameter (height power).
% -tfce_E <real>    : Set the TFCE E parameter (extent power).
% -tfce_C <integer> : Set the TFCE C parameter (connectivity).
% -corrmod          : Apply fwer-correction of p-values over
%                     multiple modalities.
% -corrcon          : Apply fwer-correction of p-values over
%                     multiple contrasts.
% -fdr              : Produce FDR-adjusted p-values.
% -saveparametric   : Save also uncorrected parametric p-values.
% -savemask         : Save the effective masks used for each modality.
% -noniiclass       : Do not use the NIFTI class (use this option only
%                     if you have problems and for small datasets).
% -draft <e>        : Run in the "draft mode", with 'e' exceedances. No
%                     FWER correction is possible, only FDR-adjustment.
% -saveperms        : Save one statistic image per permutation, as well
%                     as a CSV file with the permutation indices (one
%                     permutation per row, one index per column;
%                     sign-flips are represented by the negative
%                     indices). Use cautiously, as the images may
%                     consume large amounts of disk space.
% -seed <positive>  : Seed used for the random number generator. Use a
%                     positive integer up to 2^32. Default is 0. To
%                     start with a random number, use '-seed twist'.
%                     Note that a given seed used in MATLAB isn't
%                     equivalent to the same seed used in Octave.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / Univ. of Oxford
% Jan/2013
% http://brainder.org

% If Octave
if palm_isoctave,
    
    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);
    
    % If running as a script, take the input arguments
    cmdname = program_invocation_name();
    if ~ strcmpi(cmdname(end-5:end),'octave'),
        varargin = argv();
    end
end

% This is probably redundant but fix a bug in an old Matlab version
nargin = numel(varargin);

% Print usage if no inputs are given
if nargin == 0 || strcmp(varargin{1},'-q'),
    fprintf('===========================================\n');
    fprintf('PALM: Permutation Analysis of Linear Models\n');
    fprintf('===========================================\n');
    fprintf('\n');
    fprintf('PALM performs permutation inference for the general linear\n');
    fprintf('models (GLMs) of arbitrary complexity, taking as inputs data\n');
    fprintf('in various formats, and being able to take into account certain\n');
    fprintf('cases of well-structured non-independence.\n');
    fprintf('\n');
    fprintf('The options are:\n');
    fprintf('\n');
    fprintf('-i <file>         : Input(s). More than one can be specified, each one\n');
    fprintf('                    preceded by its own -i. All input files must\n');
    fprintf('                    contain the same number of observations (e.g., the\n');
    fprintf('                    same number of subjects). Except for NPC, mixing \n');
    fprintf('                    is allowed (e.g., voxelwise, vertexwise and \n');
    fprintf('                    non-imaging data can be all loaded at once, and \n');
    fprintf('                    later will be all corrected across).\n');
    fprintf('-m <file>         : Mask(s). Either one for all inputs, or one per\n');
    fprintf('                    input, supplied in the same order as the\n');
    fprintf('                    respective -i appear.\n');
    fprintf('-s <file>         : Surface file(s). When more than one is supplied,\n');
    fprintf('                    each -s should be entered in the same order as the\n');
    fprintf('                    respective -i. This option is needed when the\n');
    fprintf('                    input data is a scalar field over a surface and\n');
    fprintf('                    spatial statistics (cluster extent, cluster mass\n');
    fprintf('                    or TFCE) have been enabled.\n');
    fprintf('-d <file>         : Design matrix. It can be in CSV or VEST format.\n');
    fprintf('                    For information on how to construct the design\n');
    fprintf('                    matrix, see the FSL GLM manual.\n');
    fprintf('-t <file>         : t-contrasts file, in CSV or VEST format. The\n');
    fprintf('                    option -t can be used more than once, so that more\n');
    fprintf('                    than one t-contrasts file can be loaded.\n');
    fprintf('-f <file>         : F-contrasts file, in CSV or VEST format.\n');
    fprintf('                    The option -f can be used more than once, so that\n');
    fprintf('                    more than one F-contrasts file can be loaded.\n');
    fprintf('                    Each file supplied with a -f corresponds to the\n');
    fprintf('                    file supplied with the option -t in the same\n');
    fprintf('                    order. The option -f cannot be used more than the\n');
    fprintf('                    number of times the option -t was used.\n');
    fprintf('-inormal          : Apply an inverse-normal transformation to the data\n');
    fprintf('                    using the Waerden method.\n');
    fprintf('-rmethod <string> : Method for regression/permutation. It can be one\n');
    fprintf('                    of: Freedman-Lane, Smith, terBraak, Manly,\n');
    fprintf('                    Draper-Stoneman, Still-White and Huh-Jhun.\n');
    fprintf('                    Default, and recommended, is Freedman-Lane.\n');
    fprintf('-n <integer>      : Number of permutations. Use -n 0 to run all\n');
    fprintf('                    permutations and/or sign-flips exhaustively.\n');
    fprintf('-eb <file>        : Exchangeability blocks file, in csv or vest\n');
    fprintf('                    format. If omitted, all observations are treated\n');
    fprintf('                    as exchangeable and belonging to a single large\n');
    fprintf('                    exchangeability block.\n');
    fprintf('-sb               : Permute blocks as a whole if the block\n');
    fprintf('                    specification has a single column. Otherwise,\n');
    fprintf('                    permutations will happen within block.\n');
    fprintf('-vg <file>        : Variance groups file, in csv or vest format.\n');
    fprintf('                    If omitted, the variance groups are defined\n');
    fprintf('                    automatically using the exchangeability blocks\n');
    fprintf('                    (option -eb).\n');
    fprintf('-ee               : Assume exchangeable errors (ee), to allow\n');
    fprintf('                    permutations.\n');
    fprintf('-ise              : Assume independent and symmetric errors (ise),\n');
    fprintf('                    to allow sign-flipping.\n');
    fprintf('-cmc              : Use Conditional Monte Carlo. This option will be\n');
    fprintf('                    ignored if the number of shufflings chosen is\n');
    fprintf('                    larger than the maximum number of possible\n');
    fprintf('                    shufflings, in which case all possible shufflings\n');
    fprintf('                    will be performed.\n');
    fprintf('-npc              : Use non-parametric combination (NPC).\n');
    fprintf('-cmethod <string> : Method for combination in the NPC. It can be one\n');
    fprintf('                    of: Tippett, Fisher, Pearson-David, Stouffer,\n');
    fprintf('                    Wilkinson <alpha>, Winer, Edgington,\n');
    fprintf('                    Mudholkar-George, Friston, Darlington-Hayes <r>,\n');
    fprintf('                    Zaykin <alpha>, Dudbridge-Koeleman <r>,\n');
    fprintf('                    Dudbridge-Koeleman2 <r> <alpha>, Nichols,\n');
    fprintf('                    Taylor-Tibshirani or Jiang <alpha>.\n');
    fprintf('                    Default is Tippett.\n');
    fprintf('                    Note that some methods require 1 or 2 additional\n');
    fprintf('                    parameters to be provided.\n');
    fprintf('-o <string>       : Output prefix. It may itself be prefixed by a\n');
    fprintf('                    path. Default is ''palm''.\n');
    fprintf('-c <real>         : Enable cluster extent for t contrasts, with the\n');
    fprintf('                    supplied cluster-forming threshold.\n');
    fprintf('-C <real>         : Enable cluster mass for t contrasts, with the\n');
    fprintf('                    supplied cluster-forming threshold.\n');
    fprintf('-F <positive>     : Enable cluster extent for F contrasts, with the\n');
    fprintf('                    supplied cluster-forming threshold.\n');
    fprintf('-S <positive>     : Enable cluster mass for F contrasts, with the\n');
    fprintf('                    supplied cluster-forming threshold.\n');
    fprintf('-T                : Enable TFCE inference for 3D (volume) data,\n');
    fprintf('                    i.e., with H = 2, E = 0.5, C = 6.\n');
    fprintf('-T2               : Enable TFCE inference for 2D (surface, TBSS) data,\n');
    fprintf('                    i.e., H = 2, E = 1, C = 26.\n');
    fprintf('-cnpc <real>      : Enable NPC cluster extent, with the supplied\n');
    fprintf('                    cluster-forming threshold (z-stat).\n');
    fprintf('-Cnpc <real>      : Enable NPC cluster mass, with the supplied\n');
    fprintf('                    cluster-forming threshold (z-stat).\n');
    fprintf('-Tnpc             : Enable TFCE inference for NPC on 3D data,\n');
    fprintf('                    with H = 2, E = 0.5, C = 6.\n');
    fprintf('-T2npc            : Enable TFCE inference for NPC on 2D data,\n');
    fprintf('                    i.e., H = 2, E = 1, C = 26.\n');
    fprintf('-tfce_H <real>    : Set the TFCE H parameter (height power).\n');
    fprintf('-tfce_E <real>    : Set the TFCE E parameter (extent power).\n');
    fprintf('-tfce_C <integer> : Set the TFCE C parameter (connectivity).\n');
    fprintf('-corrmod          : Apply fwer-correction of p-values over\n');
    fprintf('                    multiple modalities.\n');
    fprintf('-corrcon          : Apply fwer-correction of p-values over\n');
    fprintf('                    multiple contrasts.\n');
    fprintf('-fdr              : Produce FDR-adjusted p-values.\n');
    fprintf('-saveparametric   : Save also uncorrected parametric p-values.\n');
    fprintf('-savemask         : Save the effective masks used for each modality.\n');
    fprintf('-noniiclass       : Do not use the NIFTI class (use this option only\n');
    fprintf('                    if you have problems and for small datasets).\n');
    fprintf('-draft <e>        : Run in the "draft mode", with ''e'' exceedances. No\n');
    fprintf('                    FWER correction is possible, only FDR-adjustment.\n');
    fprintf('-saveperms        : Save one statistic image per permutation, as well\n');
    fprintf('                    as a CSV file with the permutation indices (one\n');
    fprintf('                  : permutation per row, one index per column;\n');
    fprintf('                  : sign-flips are represented by the negative\n');
    fprintf('                    indices). Use cautiously, as the images may\n');
    fprintf('                    consume large amounts of disk space.\n');
    fprintf('-seed <positive>  : Seed used for the random number generator. Use a\n');
    fprintf('                    positive integer up to 2^32. Default is 0. To \n');
    fprintf('                    start with a random number, use ''-seed twist''.\n');
    fprintf('                    Note that a given seed used in MATLAB isn''t \n');
    fprintf('                    equivalent to the same seed used in Octave.\n');
    fprintf('\n');
    fprintf('_____________________________________\n');
    fprintf('Anderson M. Winkler\n');
    fprintf('FMRIB / Univ. of Oxford\n');
    fprintf('Jan/2013\n');
    fprintf('http://brainder.org\n');
    return;
end

% Now run what matters
palm_backend(varargin);