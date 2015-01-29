%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function is for preparing foreground and background masks that are
%   are used in training.
%
%   Input -- 
%       @obj                - object of type EnsembleClassifier
%       @frameImage         - image of the current frame
%       @objectRectangle    - rectangle of the target on image
%       @phase              - 'TRAIN' or 'TEST'
%
%   Output -- 
%       @obj                - object of type Target
%       @objectRectangle    - adjusted object rectangle
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ obj, objectRectangle ] = PrepareForegroundAndBackgroundMasks(    obj,...
                                                                            frameImage,...
                                                                            objectRectangle,...
                                                                            phase )
    assert( nargin == 4 );
    assert( ~isempty( frameImage ) );

    [ numberOfRows, numberOfColumns, ~ ] = size( frameImage );
    
    % initialize the mask image to zeros.
    innerRectangleMask = zeros( numberOfRows, numberOfColumns );
    outerRectangleMask = zeros( numberOfRows, numberOfColumns );

    objectRectangle = floor(objectRectangle);
    h = objectRectangle(4); 
    w = objectRectangle(3); 

    % Another .5 is for splitting it on both sides of window
    rect_width = ceil( .5 .* .5 .* ( sqrt( ( h + w )^2 + ( 4 * h * w ) ) - ( h + w ) ) );
    rect_width = rect_width + ( 1-mod(rect_width, 2) );
    if ( strcmp( phase, 'TEST') ) 
        rect_width = floor(rect_width + 0);
    end
    
    inner_rect = [max(1, objectRectangle(2))  min(numberOfRows, objectRectangle(2)+objectRectangle(4)-1)...
                  max(1, objectRectangle(1))  min(numberOfColumns, objectRectangle(1)+objectRectangle(3)-1)];
    innerRectangleMask(inner_rect(1):inner_rect(2), inner_rect(3):inner_rect(4)) = 1;
    
    outer_rect = [max(1, inner_rect(1)-rect_width), min(numberOfRows, inner_rect(2)+rect_width),...
                  max(1, inner_rect(3)-rect_width), min(numberOfColumns, inner_rect(4)+rect_width)];          
    outerRectangleMask(outer_rect(1):outer_rect(2), outer_rect(3):outer_rect(4)) = 1;
    outerRectangleMask = outerRectangleMask - innerRectangleMask;

    % set the foreground and background mask regions
    obj.m_foregroundRegionMask = find( innerRectangleMask );
    obj.m_backgroundRegionMask = find( outerRectangleMask );
    
    obj.m_numberOfRowsForBoosting       = outer_rect(2) - outer_rect(1) + 1;
    obj.m_numberOfColumnsForBoosting    = outer_rect(4) - outer_rect(3) + 1;
end