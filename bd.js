/* Credit and Thanks:
Matrix - Particles.js;
SliderJS - Ettrics;
Design - Sara Mazal Web;
Fonts - Google Fonts
*/

window.onload = function () {
  Particles.init({
    selector: ".background"
  });
};
const particles = Particles.init({
  selector: ".background",
  color: ["#03dac6", "#ff0266", "#000000"],
  connectParticles: true,
  responsive: [
    {
      breakpoint: 768,
      options: {
        color: ["#faebd7", "#03dac6", "#ff0266"],
        maxParticles: 78,
        connectParticles: false
      }
    }
  ]
});

const canvas = document.getElementByclass('background');
const ctx = canvas.getContext('2d');

// Set canvas dimensions to match the window size
function resizeCanvas() {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
}

// Example background drawing (you can customize)
function drawBackground() {
  ctx.fillStyle = 'rgba(0, 150, 255, 0.5)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

// Resize the canvas and redraw when the window is resized
window.addEventListener('resize', () => {
  resizeCanvas();
  drawBackground();
});

// Initialize canvas size and drawing
resizeCanvas();
drawBackground();



