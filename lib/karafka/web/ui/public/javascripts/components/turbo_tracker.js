let turboIsOperating = false;

// Listen for Turbo events to manage the state
document.addEventListener('turbo:visit', function() {
  turboIsOperating = true;
});

document.addEventListener('turbo:before-fetch-request', function() {
  turboIsOperating = true;
});

document.addEventListener('turbo:before-fetch-response', function() {
  turboIsOperating = true;
});

document.addEventListener('turbo:load', function() {
  turboIsOperating = false;
});

document.addEventListener('turbo:frame-load', function() {
  turboIsOperating = false;
});

document.addEventListener('turbo:frame-render', function() {
  turboIsOperating = false;
});

function isTurboOperating() {
  return turboIsOperating;
}
