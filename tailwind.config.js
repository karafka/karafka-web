module.exports = {
  content: ["./lib/**/*.{html,js,erb,rb}"],
  theme: {
    extend: {},
  }
  // Note: Regex safelist patterns do NOT work with Tailwind v4 + @tailwindcss/postcss
  // Safelist is now managed via @source inline() in tailwind.css
  // Reference: https://tailwindcss.com/docs/detecting-classes-in-source-files#safelisting-specific-utilities
}
