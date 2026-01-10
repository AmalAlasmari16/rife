// Logo Component - Easy to update with your logo
// To add your logo:
// 1. Place your logo file in /app/frontend/public/ folder (e.g., logo.png, logo.svg)
// 2. Update the logoPath below to match your filename
// 3. That's it!

import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

export const Logo = ({ size = 'md', showText = true, className = '' }) => {
  const { t } = useTranslation();
  
  // UPDATE THIS PATH TO YOUR LOGO FILE
  // Examples: '/logo.png', '/logo.svg', '/rifq-logo.png'
  const logoPath = '/logo.png'; // Change this to your logo filename
  
  // Check if logo exists, otherwise show app name
  const [hasLogo, setHasLogo] = useState(false);
  
  useEffect(() => {
    // Check if logo file exists
    const img = new Image();
    img.onload = () => setHasLogo(true);
    img.onerror = () => setHasLogo(false);
    img.src = logoPath;
  }, [logoPath]);
  
  const sizes = {
    sm: 'h-8',
    md: 'h-10',
    lg: 'h-12',
    xl: 'h-16'
  };
  
  return (
    <div className={`flex items-center gap-3 ${className}`}>
      {hasLogo ? (
        <>
          <img 
            src={logoPath} 
            alt="رِفق Logo" 
            className={`${sizes[size]} w-auto object-contain`}
            data-testid="app-logo-image"
          />
          {showText && (
            <span className="text-2xl font-bold text-primary" style={{ fontFamily: 'Nunito, Cairo, Tajawal, sans-serif' }}>
              {t('appName')}
            </span>
          )}
        </>
      ) : (
        <span className="text-2xl font-bold text-primary" style={{ fontFamily: 'Nunito, Cairo, Tajawal, sans-serif' }}>
          {t('appName')}
        </span>
      )}
    </div>
  );
};

export default Logo;