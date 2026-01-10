// Color Theme Configuration
// Customize your app colors here

export const theme = {
  colors: {
    // Primary Color (Main theme color) - Currently Teal
    primary: {
      DEFAULT: 'hsl(160, 84%, 39%)',  // #10b981 - Teal
      light: 'hsl(160, 84%, 50%)',
      dark: 'hsl(160, 84%, 30%)',
      foreground: 'hsl(0, 0%, 100%)'  // White text on primary
    },
    
    // Accent Color (Secondary highlights) - Currently Soft Coral
    accent: {
      DEFAULT: 'hsl(10, 80%, 96%)',   // Soft coral background
      foreground: 'hsl(10, 80%, 40%)', // Coral text
      hover: 'hsl(10, 80%, 92%)'
    },
    
    // Background colors
    background: 'hsl(40, 20%, 99%)',  // Warm white
    foreground: 'hsl(220, 20%, 20%)', // Dark text
    
    // Additional colors
    muted: {
      DEFAULT: 'hsl(220, 14%, 96%)',
      foreground: 'hsl(220, 10%, 45%)'
    },
    
    border: 'hsl(220, 13%, 91%)',
    ring: 'hsl(160, 84%, 39%)' // Focus ring color
  }
};

// To change colors:
// 1. Update the HSL values above
// 2. The app will automatically use your new colors
// 3. You can use a color picker to get HSL values
//    Example: Red = hsl(0, 100%, 50%)
//    Example: Blue = hsl(220, 100%, 50%)
//    Example: Purple = hsl(270, 100%, 50%)

export default theme;