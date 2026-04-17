module.exports = {
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      colors: {
        primary: '#009191',
        'primary-light': '#e0f7f7',
        'primary-dark': '#006d6d',
        // Add dark theme background and text colors
        'dark-bg': '#181f20',
        'dark-card': '#232b2c',
        'dark-border': '#232b2c',
        'dark-text': '#e5e7eb',
        'dark-primary': '#00b3b3',
      },
    },
  },
  variants: {
    extend: {
      backgroundColor: ['dark'],
      borderColor: ['dark'],
      textColor: ['dark'],
      placeholderColor: ['dark'],
      ringColor: ['dark'],
    },
  },
  plugins: [],
};