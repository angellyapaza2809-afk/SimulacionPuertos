/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        hull: {
          950: '#0B1B2B', // casco / navy profundo
          900: '#102338',
          800: '#16324A',
          700: '#1E4260',
          600: '#2C5A80',
        },
        signal: {
          500: '#E8592A', // naranja de contenedor / señalización portuaria
          600: '#CC471E',
          400: '#F17C4D',
        },
        buoy: {
          400: '#F2C14E', // amarillo de boya, uso muy restringido (alertas)
        },
        mist: {
          50: '#F5F7F8',
          100: '#E9EDEF',
          200: '#D3DBDF',
        },
      },
      fontFamily: {
        display: ['"Space Grotesk"', 'system-ui', 'sans-serif'],
        body: ['"Inter"', 'system-ui', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
};
