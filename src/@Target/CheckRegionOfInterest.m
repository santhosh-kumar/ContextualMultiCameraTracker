%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function checks region of interest for the given frameNumber.
%   Give in an image with 2 rectangles in the image, get out all pixels.
%   This is done for getting the inner and outer masks used in the
%   subsequent training process.
%
%   Input -- 
%       @obj        - Target object
%       @frameImage - image of the current frame
%   Output -- 
%        @obj       - target object
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = CheckRegionOfInterest( obj, frameImage )
    
    try
        assert( nargin == 2 );
        assert( ~isempty( frameImage ) );
        
        [imHeight, imWidth, ~] = size(frameImage);
        Bd = obj.m_rectangle;                                                                     
                                                                        
                                                                        
        if Bd(1) < 1
            dStartX = 1;
        elseif Bd(1) > imWidth
            dStartX = imWidth;
        else
            dStartX = Bd(1);
        end

        if Bd(2) < 1
            dStartY = 1;
        elseif Bd(2) > imHeight
            dStartY = imHeight;
        else
            dStartY = Bd(2);
        end


        if ( Bd(1) + Bd(3) ) > imWidth
            wD = max( imWidth -  Bd(1), 0 );
        elseif ( Bd(1)+ Bd(3) ) < 1
            wD = 0;
        else
            wD = Bd(3);
        end

        if ( Bd(2)+Bd(4) ) > imHeight
            hD = max( imHeight -  Bd(2), 0);
        elseif ( Bd(2) + Bd(4) ) < 1
            hD = 0;
        else
            hD = Bd(4);
        end
        
        obj.m_rectangle = [ dStartX dStartY wD hD];
    catch ex
        throwAsCaller( ex );
    end
    
end