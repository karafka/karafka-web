// Component for displaying the timestamp explorer form and moving to a timestamp on submit

class TimestampSelector {
 constructor() {
   this.init();
 }

 init() {
   const form = document.getElementById('timestamp-form');
   if (!form) { return false; }

   // Focus input when dropdown button is clicked
   const dropdownButton = form.closest('.dropdown').querySelector('button');
   dropdownButton.addEventListener('click', () => {
     setTimeout(() => {
       form.querySelector('input').focus();
     }, 50);
   });

  const dropdown = form.closest('.dropdown');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const button = form.querySelector('button');
    dropdown.classList.add('dropdown-open'); // Keep dropdown open
    const target = form.dataset.target;
    const timestamp = form.querySelector('input').value;
    window.location.href = target + '/' + timestamp;
  });
 }
}
