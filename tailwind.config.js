/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/daily-client/**/*.{css,elm}",
  ],
  theme: {
    extend: {},
    fontFamily: {
      sans: ["Graphik", "sans-serif"],
      serif: ["Merriweather", "serif"],
    },
  },
  plugins: [],
};
