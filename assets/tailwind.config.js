module.exports = {
	content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
	theme: {
		extend: {},
	},
	variants: {},
	plugins: [require("@tailwindcss/forms")],
}
