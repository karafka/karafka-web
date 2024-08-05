const gulp = require('gulp');
const concat = require('gulp-concat');
const uglify = require('gulp-uglify');
const through2 = require('through2');
const path = require('path');
const cleanCSS = require('gulp-clean-css');
const sourcemaps = require('gulp-sourcemaps');

// Check if we are in development mode
const isDev = process.env.KARAFKA_RELEASE !== 'true';

// Define JavaScript source files
const jsFiles = [
  'lib/karafka/web/ui/public/javascripts/libs/**/*.js',
  'lib/karafka/web/ui/public/javascripts/charts/**/*.js',
  'lib/karafka/web/ui/public/javascripts/components/**/*.js',
  'lib/karafka/web/ui/public/javascripts/application.js'
];

// Define CSS source files
const cssFiles = [
  'lib/karafka/web/ui/public/stylesheets/libs/datepicker.min.css',
  'lib/karafka/web/ui/public/stylesheets/libs/tailwind.min.css',
  'lib/karafka/web/ui/public/stylesheets/application.css'
];

// Custom transform stream to add file location comments for JavaScript
function addFileLocation() {
  return through2.obj(function (file, enc, cb) {
    if (file.isBuffer()) {
      const fileLocationComment = `/*! Source: ${path.relative(__dirname, file.path)} */\n\n`;
      const contents = Buffer.concat([Buffer.from(fileLocationComment), file.contents]);
      file.contents = contents;
    }
    cb(null, file);
  });
}

// JavaScript task
gulp.task('scripts', function() {
  return gulp.src(jsFiles)
    .pipe(isDev ? sourcemaps.init() : through2.obj()) // Initialize sourcemaps in dev
    .pipe(addFileLocation()) // Add file location comments
    .pipe(concat('application.min.js'))
    .pipe(uglify({
      output: {
        comments: function(node, comment) {
          const text = comment.value;
          const type = comment.type;
          if (type == "comment2") {
            // Preserve comments starting with `/*!` or `/**`
            return /@preserve|@license|@cc_on|^\!/.test(text);
          }
          return false;
        }
      }
    }))
    .pipe(isDev ? sourcemaps.write('.') : through2.obj()) // Write sourcemaps in dev
    .pipe(gulp.dest('lib/karafka/web/ui/public/javascripts'));
});

// CSS task
gulp.task('styles', function() {
  return gulp.src(cssFiles)
    .pipe(isDev ? sourcemaps.init() : through2.obj()) // Initialize sourcemaps in dev
    .pipe(concat('application.min.css'))
    .pipe(cleanCSS({ level: 2 })) // Minify CSS
    .pipe(isDev ? sourcemaps.write('.') : through2.obj()) // Write sourcemaps in dev
    .pipe(gulp.dest('lib/karafka/web/ui/public/stylesheets'));
});

// Define default task to run both scripts and styles tasks
gulp.task('default', gulp.series('scripts', 'styles'));
