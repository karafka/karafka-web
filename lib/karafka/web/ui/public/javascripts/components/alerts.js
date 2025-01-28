class AlertsManager {
 constructor() {
   this.setupCloseButtons();
 }

 setupCloseButtons() {
   document.querySelectorAll('.alert .close-alert').forEach(button => {
     button.addEventListener('click', () => {
       const alert = button.closest('.alert');
       if (alert) {
         this.closeAlert(alert);
       }
     });
   });
 }

 closeAlert(alert) {
   alert.style.opacity = '1';
   alert.style.transition = 'opacity 0.3s ease-out';
   alert.style.opacity = '0';

   setTimeout(() => {
     const colSpanWrapper = alert.closest('.col-span-12');

     if (colSpanWrapper) {
       const wrapperContent = colSpanWrapper.cloneNode(true);
       wrapperContent.querySelector('.alert').remove();

       if (!wrapperContent.innerHTML.trim()) {
         colSpanWrapper.remove();
       } else {
         alert.remove();
       }
     } else {
       alert.remove();
     }
   }, 300);
 }
}
