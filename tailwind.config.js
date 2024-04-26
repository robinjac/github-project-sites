/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "src/daily-site/**/*.{css,elm,js,ts,html}",
    "./index.html",
    "./dist/**/*.{css,js,html}"
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
