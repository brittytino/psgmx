import React from 'react';
import Image from 'next/image';

interface AppLogoProps {
  className?: string;
  width?: number;
  height?: number;
  priority?: boolean;
}

const AppLogo: React.FC<AppLogoProps> = ({ 
  className = "", 
  width = 180, 
  height = 60,
  priority = true
}) => {
  return (
    <div className={`flex items-center ${className}`}>
      <Image
        src="/login.webp"
        alt="PSGMX Logo"
        width={width}
        height={height}
        className="object-contain"
        priority={priority}
      />
    </div>
  );
};

export default AppLogo;
