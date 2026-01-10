# رِفق Branding Customization Guide

This guide shows you how to add your logo and customize colors in your app.

## 📷 Adding Your Logo

### Step 1: Prepare Your Logo
- **Recommended format**: PNG with transparent background or SVG
- **Recommended size**: 200x200 pixels (or higher for retina displays)
- **File name examples**: `logo.png`, `rifq-logo.svg`, `brand.png`

### Step 2: Upload Your Logo
1. Place your logo file in the `/app/frontend/public/` folder
2. You can use any of these methods:
   - Upload via file manager
   - Use command: `cp your-logo.png /app/frontend/public/logo.png`
   - Through the Emergent platform interface

### Step 3: Update Logo Path
Open `/app/frontend/src/components/Logo.js` and change line 11:

```javascript
const logoPath = '/logo.png'; // Change 'logo.png' to your filename
```

Examples:
- If your file is `rifq-logo.svg`: `const logoPath = '/rifq-logo.svg';`
- If your file is `brand.png`: `const logoPath = '/brand.png';`

### Step 4: Restart Frontend
```bash
sudo supervisorctl restart frontend
```

That's it! Your logo will now appear:
- ✅ Top navigation bar (with app name)
- ✅ Login page (large, centered)
- ✅ Automatically scales for different screen sizes

---

## 🎨 Customizing Colors

### Current Colors:
- **Primary (Teal)**: `hsl(160, 84%, 39%)` - #10b981
- **Accent (Coral)**: `hsl(10, 80%, 96%)`
- **Background**: Warm white

### To Change Colors:

Open `/app/frontend/src/theme.js` and modify the HSL values:

```javascript
primary: {
  DEFAULT: 'hsl(160, 84%, 39%)',  // Change this line
}
```

### Color Examples:

**Blue Theme:**
```javascript
primary: {
  DEFAULT: 'hsl(220, 100%, 50%)',  // Bright blue
}
```

**Purple Theme:**
```javascript
primary: {
  DEFAULT: 'hsl(270, 80%, 50%)',  // Purple
}
```

**Green Theme:**
```javascript
primary: {
  DEFAULT: 'hsl(142, 71%, 45%)',  // Green
}
```

**Orange Theme:**
```javascript
primary: {
  DEFAULT: 'hsl(25, 95%, 53%)',  // Orange
}
```

### How to Find HSL Colors:
1. Use a color picker tool (Google "color picker")
2. Choose your color
3. Get the HSL values
4. Format: `hsl(hue, saturation%, lightness%)`

### Apply Changes:
```bash
sudo supervisorctl restart frontend
```

---

## 📁 File Locations

- **Logo Component**: `/app/frontend/src/components/Logo.js`
- **Theme/Colors**: `/app/frontend/src/theme.js`
- **Upload Logo Here**: `/app/frontend/public/`
- **Tailwind Config**: `/app/frontend/tailwind.config.js` (advanced)

---

## 💡 Tips

1. **Logo not showing?**
   - Check the file name matches exactly (case-sensitive)
   - Ensure logo is in `/app/frontend/public/` folder
   - Restart frontend service

2. **Want different logo for Arabic?**
   - Edit Logo.js to detect language and switch logos

3. **Need help?**
   - Just ask me in this chat after deployment!

---

## ✅ Quick Checklist

- [ ] Logo file prepared (PNG/SVG)
- [ ] Logo uploaded to `/app/frontend/public/`
- [ ] Updated logoPath in Logo.js
- [ ] Restarted frontend
- [ ] Tested on login page and dashboard
- [ ] Verified colors match brand (optional)
