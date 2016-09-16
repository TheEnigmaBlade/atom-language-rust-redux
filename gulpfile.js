"use strict";

const gulp = require("gulp");
const exec = require("child_process").exec;

gulp.task("test", () => {
	exec("apm test", function(err, stdout, stderr) {
		if(stdout) {
			console.log(stdout);
		}
		if(stderr) {
			console.error(stderr);
		}
	});
});

gulp.task("watch", () => {
	gulp.watch("spec/*", ["test"]);
	gulp.watch("grammars/*", ["test"]);
});
