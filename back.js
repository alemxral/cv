const canvas = document.getElementById('backgroundCanvas');
const ctx = canvas.getContext('2d');
const img = new Image();
img.src = 'data:image/png;base64,SGVsbG8hIE15IG5hbWUgaXMgU2FyYSBNYXphbC4gV2VsY29tZSB0byBteSBDb2RlUGVuIQ=='; // Your base64 image

let x = 0;
let y = 0;

img.onload = function() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    animate();
};

function animate() {
    ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear the canvas
    ctx.drawImage(img, x, y); // Draw the image at the current position
    x += 1; // Move the image to the right
    if (x > canvas.width) {
        x = -img.width; // Reset the position when it goes off the screen
    }
    requestAnimationFrame(animate); // Request the next animation frame
}

// Resize the canvas when the window is resized
window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
});
