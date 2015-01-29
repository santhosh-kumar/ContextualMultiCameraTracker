%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Display Particles
%
%   Input -- 
%       @ obj            - object of type Particle Filter
%       @ imageFrame     - image frame
%       @ figureHandle   - handle to display particles
%
%   Output -- 
%       void
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DisplayParticles( obj, imageFrame, figureHandle )
    try
        figure(figureHandle);
        imshow(imageFrame);
        
        objectRectangle = obj.m_objectRectangle;
        
        weightList = obj.GetWeightList( );
        assert( sum(weightList) > 0 );
        weightList = weightList ./ max(weightList);
        colors = flip(uniqueColors(100, 1, 0));
        
        [ ~, sortedIndex ] = sort( weightList, 1, 'descend' );
        
        hold on;
        for i = 1 : ParticleFilter.NUMBER_OF_PARTICLES_TO_DISPLAY            
            xMin = obj.m_stateMatrix( sortedIndex(i), 1 ) - obj.m_stateMatrix( sortedIndex(i), 3 ) * objectRectangle(3)/2;
            yMin = obj.m_stateMatrix( sortedIndex(i), 2 ) - obj.m_stateMatrix( sortedIndex(i), 4 ) * objectRectangle(4)/2;
            
            xMax = obj.m_stateMatrix( sortedIndex(i), 1 ) + obj.m_stateMatrix( sortedIndex(i), 3 ) * objectRectangle(3)/2;
            yMax = obj.m_stateMatrix( sortedIndex(i), 2 ) + obj.m_stateMatrix( sortedIndex(i), 4 ) * objectRectangle(4)/2;
            
            x_line = [ xMin xMin  xMax xMax xMin]; 
            y_line = [ yMin yMax  yMax yMin yMin];
            
            colorIndex = max(1, min(floor(weightList( sortedIndex(i) ) * 100 ), 100 ) );
            colorCode = colors(colorIndex,:);
            
            line( x_line, y_line, 'Color', colorCode );
        end
        hold off;
    catch ex
        error( ['Failed to display particles:' ex] );
    end
end