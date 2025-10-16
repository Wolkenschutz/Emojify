module.exports = {
	types: [
		{ types: [ "Feature" ], label: "New Features" },
		{ types: [ "Fix" ], label: "Bugfixes" },
		{ types: [ "Improvement" ], label: "Improvements" },
		{ types: [ "Revert" ], label: "Reverts" },
		{ types: [ "Other", "other" ], label: "Other Changes" },
		{ types: [ "Skip" ], label: "Skip" }
	],
	
	excludeTypes: [ "Skip" ],

	renderTypeSection: function (label, commits) {
		let text = `\n## ${label}\n`;

		commits.forEach(commit => {
			text += `- ${commit.subject}\n`;
			if (commit.body) {
				text += `${commit.body}\n`;
			}
		});

		return text;
	},

	renderChangelog: function (release, changes) {
		const now = new Date();
		let text = `# ${release}\n${changes}\n\n`;
		return text;
	}
};
