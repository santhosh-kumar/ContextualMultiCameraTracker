%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Visualizes the tracker output
%
%   Input -- 
%       @obj           - Camera object
%       @networkStruct - Information about the network structure
%
%   Output -- 
%       void
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VisualizeTrackerOutput( obj, networkStructure )

    %display the current frame
    frameNumber = networkStructure.clock;
    frame = figure( obj.m_cameraID * 100 );
    frameImg = obj.GetFrame( frameNumber );
    imshow( frameImg );

    hold on;
    for targetIndex = 1 : obj.m_numberOfObjects
        %is target active
        if obj.IsTargetActive( targetIndex )
            %draw the object rectangle
            targetRectangle = obj.m_targetList{targetIndex}.GetTargetRectangle();
            targetCenter    = [targetRectangle(1)+targetRectangle(3)/2 targetRectangle(2)+targetRectangle(4)/2];
            obj.DrawRectangle( targetRectangle,...
                               Camera.OUTPUT_RECTANGLE_COLOR, 2 );
            targetId =  obj.m_targetList{targetIndex}.GetTargetID( );
            text('position', targetCenter, 'fontsize', 30, 'color', [1 1 1], 'string',num2str(targetId) ); 
        end
    end
    hold off;
    
    % Add to output stream
    obj.AddFrameToOutputStream( getframe(frame) );
end%function
