/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // Custom brand accent: teal -> green
        brand: {
          DEFAULT: '#0EA5A0',
          from: '#0EA5A0',
          to: '#22C55E',
          50: '#ecfdf9',
          100: '#d0faf0',
          200: '#a3f3e1',
          300: '#6de6d0',
          400: '#38d1ba',
          500: '#0EA5A0',
          600: '#0c8481',
          700: '#0f6968',
          800: '#115453',
          900: '#123f3f',
        },
      },
      backgroundImage: {
        'brand-gradient': 'linear-gradient(135deg, #0EA5A0 0%, #22C55E 100%)',
      },
      ringColor: {
        brand: '#0EA5A0',
      },
    },
  },
  plugins: [],
}
