module.exports = {
  content: ["./lib/**/*.{html,js,erb,rb}"],
  theme: {
    extend: {},
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: ["corporate", "dark"]
  },
  safelist: [
    {
      pattern: /((badge|bg|alert)-(success|warning|error|primary|secondary))|(status-row-*)/,
      variants: ['lg', 'hover', 'focus', 'lg:hover']
    }
  ]
}
