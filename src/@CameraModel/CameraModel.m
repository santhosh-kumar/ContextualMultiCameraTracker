%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This Class is encapsulating camera calibration model
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%
%   NOTE: Important RECT = [XMIN YMIN WIDTH HEIGHT]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef CameraModel < handle
    
    properties(GetAccess = 'public', SetAccess = 'private')
        %geometry
        mImgWidth;
		mImgHeight;
		mNcx;
		mNfx;
		mDx;
		mDy;
		mDpx;
		mDpy;

		%intrinsic 
		mFocal;
		mKappa1;
		mCx;
		mCy;
		mSx;
 
		%extrinsic 
		mTx;
		mTy;
		mTz;
		mRx;
		mRy;
		mRz;
		
		%for computation
		mR11;
		mR12;
		mR13;
		mR21;
		mR22;
		mR23;
		mR31;
		mR32;
		mR33;
		
		%camera position
		mCposx;
		mCposy;
		mCposz;
    end
    
    properties (Constant)     
    end
    
    methods( Access = public )
        
        function obj = CameraModel( calibStruct )
            
            assert( nargin == 1 );
            %calibStruct = obj.xml2struct(xmlFileName);
            
            % set geometry parameters
            obj = obj.SetGeometry( calibStruct.Camera.Geometry.Attributes );
            
            % set inrinsic parameters
            obj = obj.SetIntrinsic( calibStruct.Camera.Intrinsic.Attributes );
            
            % set extrinsic parameters
            obj = obj.SetExtrinsic( calibStruct.Camera.Extrinsic.Attributes );
            
            %intialize the camera matrix from xml values
            obj = obj.Initialize();
        end
        
        
        function obj = SetGeometry( obj, geoStruct)
            obj.mImgWidth   = str2double( geoStruct.width );
            obj.mImgHeight  = str2double( geoStruct.height );
            obj.mNcx        = str2double( geoStruct.ncx );
            obj.mNfx        = str2double( geoStruct.nfx );
            obj.mDx         = str2double( geoStruct.dx );
            obj.mDy         = str2double( geoStruct.dy );
            obj.mDpx        = str2double( geoStruct.dpx );
            obj.mDpy        = str2double( geoStruct.dpy );
        end
        
        function obj = SetIntrinsic( obj, intrinsicStruct )
            obj.mFocal  = str2double( intrinsicStruct.focal );
            obj.mKappa1 = str2double( intrinsicStruct.kappa1 );
            obj.mCx     = str2double( intrinsicStruct.cx );
            obj.mCy     = str2double( intrinsicStruct.cy );
            obj.mSx     = str2double( intrinsicStruct.sx );
        end
        
        function obj = SetExtrinsic( obj, extrinsicStruct )
            obj.mTx = str2double( extrinsicStruct.tx );
            obj.mTy = str2double( extrinsicStruct.ty );
            obj.mTz = str2double( extrinsicStruct.tz );
            obj.mRx = str2double( extrinsicStruct.rx );
            obj.mRy = str2double( extrinsicStruct.ry );
            obj.mRz = str2double( extrinsicStruct.rz );         
        end
        
        
        function obj = Initialize( obj )
            %compute matrix
            sa = sin( obj.mRx );
            ca = cos( obj.mRx );
            sb = sin( obj.mRy );
            cb = cos( obj.mRy );
            sg = sin( obj.mRz );
            cg = cos( obj.mRz );

            obj.mR11 = cb * cg;
            obj.mR12 = cg * sa * sb - ca * sg;
            obj.mR13 = sa * sg + ca * cg * sb;
            obj.mR21 = cb * sg;
            obj.mR22 = sa * sb * sg + ca * cg;
            obj.mR23 = ca * sb * sg - cg * sa;
            obj.mR31 = -sb;
            obj.mR32 = cb * sa;
            obj.mR33 = ca * cb;

            %compute camera position
            obj.mCposx = -( obj.mTx * obj.mR11 + obj.mTy * obj.mR21 + obj.mTz * obj.mR31 );
            obj.mCposy = -( obj.mTx * obj.mR12 + obj.mTy * obj.mR22 + obj.mTz * obj.mR32 );
            obj.mCposz = -( obj.mTx * obj.mR13 + obj.mTy * obj.mR23 + obj.mTz * obj.mR33 );
        end
        
        function [ Xu, Yu ] = DistortedToUndistortedSensorCoord ( obj, Xd, Yd )
            distortion_factor = 1 + obj.mKappa1 * (Xd*Xd + Yd*Yd);
            Xu = Xd * distortion_factor;
            Yu = Yd * distortion_factor;
        end
        
        function worldPoint = ImageToWorld( obj, imagePoint )
            assert( nargin == 2 );
            
            Zw = 0;
            
            Xi = imagePoint(1);
            Yi = imagePoint(2);
            
            %convert from image to distorted sensor coordinates
            Xd = obj.mDpx * (Xi - obj.mCx) / obj.mSx;
            Yd = obj.mDpy * (Yi - obj.mCy);

            %convert from distorted sensor to undistorted sensor plane coordinates
            [ Xu, Yu ] = obj.DistortedToUndistortedSensorCoord ( Xd, Yd );
		
            %calculate the corresponding xw and yw world coordinates
			%(these equations were derived by simply inverting
            %the perspective projection equations using Macsyma)
            
            common_denominator = ( (obj.mR11 * obj.mR32 - obj.mR12 * obj.mR31) * Yu + ...
                               (obj.mR22 * obj.mR31 - obj.mR21 * obj.mR32) * Xu - ...
                                obj.mFocal * obj.mR11 * obj.mR22 + obj.mFocal * obj.mR12 * obj.mR21);
	
            Xw = (((obj.mR12 * obj.mR33 - obj.mR13 * obj.mR32) * Yu +...
                    (obj.mR23 * obj.mR32 - obj.mR22 * obj.mR33) * Xu -...
                        obj.mFocal * obj.mR12 * obj.mR23 + obj.mFocal * obj.mR13 * obj.mR22) * Zw +...
                    (obj.mR12 * obj.mTz - obj.mR32 * obj.mTx) * Yu +...
                    (obj.mR32 * obj.mTy - obj.mR22 * obj.mTz) * Xu -...
                    obj.mFocal * obj.mR12 * obj.mTy + obj.mFocal * obj.mR22 * obj.mTx) / common_denominator;

            Yw = -(((obj.mR11 * obj.mR33 - obj.mR13 * obj.mR31) * Yu +...
                (obj.mR23 * obj.mR31 - obj.mR21 * obj.mR33) * Xu -...
                obj.mFocal * obj.mR11 * obj.mR23 + obj.mFocal * obj.mR13 * obj.mR21) * Zw +...
                (obj.mR11 * obj.mTz - obj.mR31 * obj.mTx) * Yu +...
                (obj.mR31 * obj.mTy - obj.mR21 * obj.mTz) * Xu -...
                 obj.mFocal * obj.mR11 * obj.mTy + obj.mFocal * obj.mR21 * obj.mTx) / common_denominator;

            
            worldPoint = [ Xw; Yw; Zw ];
            
        end
        
        
        function [ Xd, Yd ] = UndistortedToDistortedSensorCoord ( obj, Xu, Yu )
            
            if (((Xu == 0) && (Yu == 0)) || (obj.mKappa1 == 0))
                Xd = Xu;
                Yd = Yu;
            else
                Ru = sqrt(Xu*Xu + Yu*Yu);
		
                c = 1.0 / obj.mKappa1;
                d = -c * Ru;

                Q = c / 3;
                R = -d / 2;
                D = Q*Q*Q + R*R;
		
                if (D >= 0) 
                    %one real root */
                    D = sqrt(D);
                    if (R + D > 0)
                        S = CameraModel.pow(R + D, 1.0/3.0);
                    else
                        S = -CameraModel.pow(-R - D, 1.0/3.0);
                    end

                    if (R - D > 0)
                        T = CameraModel.pow(R - D, 1.0/3.0);
                    else
                        T = -CameraModel.pow(D - R, 1.0/3.0);
                    end

                    Rd = S + T;

                    if (Rd < 0) 
                        Rd = sqrt(-1.0 / (3 * obj.mKappa1));
                        error( 'Warning: undistorted image point to distorted image point mapping limited' );
                    end
                else
                    %three real roots */
                    D = sqrt(-D);
                    S = CameraModel.pow( sqrt(R*R + D*D) , 1.0/3.0 );
                    T = atan2(D, R) / 3;
                    sinT = sin(T);
                    cosT = cos(T);

                    %the larger positive root is    2*S*cos(T)                   */
                    %the smaller positive root is   -S*cos(T) + SQRT(3)*S*sin(T) */
                    %the negative root is           -S*cos(T) - SQRT(3)*S*sin(T) */

                    Rd = -S * cosT + sqrt(3.0) * S * sinT;	%use the smaller positive root
                end
		
                lambda = Rd / Ru;

                Xd = Xu * lambda;
                Yd = Yu * lambda;
            end
        end
        
        
        function imagePoint = WorldToImage( obj, worldPoint )
            Xw = worldPoint(1);
            Yw = worldPoint(2);
            Zw = worldPoint(3);
            
            %convert from world coordinates to camera coordinates
            xc = obj.mR11 * Xw + obj.mR12 * Yw + obj.mR13 * Zw + obj.mTx;
            yc = obj.mR21 * Xw + obj.mR22 * Yw + obj.mR23 * Zw + obj.mTy;
            zc = obj.mR31 * Xw + obj.mR32 * Yw + obj.mR33 * Zw + obj.mTz;

            %convert from camera coordinates to undistorted sensor plane coordinates */
            Xu = obj.mFocal * xc / zc;
            Yu = obj.mFocal * yc / zc;
		
			%convert from undistorted to distorted sensor plane coordinates
            [ Xd, Yd ] = UndistortedToDistortedSensorCoord ( obj, Xu, Yu );
		
			%convert from distorted sensor plane coordinates to image coordinates */
            Xi = Xd * obj.mSx / obj.mDpx + obj.mCx;
            Yi = Yd / obj.mDpy + obj.mCy;
            
            
            imagePoint = [Xi;Yi];
        end
        
        s = xm2struct(obj,xmlFileName);
    end
    
    methods(Static)
       
        function val = pow( x, p )
           val = x^p; 
        end
    end
end