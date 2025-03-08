
document.addEventListener('DOMContentLoaded', function() {
    // Get nav items
    var navCv = document.getElementById('nav-cv');
    var navProjects = document.getElementById('nav-projects');
  
    // Get content sections inside .func that should be toggled
    var edu = document.querySelector('.edu');
    var work = document.querySelector('.work');
    var skillsProg = document.querySelector('.skills-prog');
    var interests = document.querySelectorAll('.interests');
    // Get the projects section
    var projectsSection = document.getElementById('projects-content');
  
    // Default state: resume content visible, projects hidden.
    edu.style.display = "block";
    work.style.display = "block";
    skillsProg.style.display = "block";
    interests.forEach(function(item) { item.style.display = "block"; });
    projectsSection.style.display = "none";
  
    // When clicking "Projects"
    navProjects.addEventListener('click', function(e) {
      e.preventDefault();
      // Hide education, work, skills, interests
      edu.style.display = "none";
      work.style.display = "none";
      skillsProg.style.display = "none";
      interests.forEach(function(item) { item.style.display = "none"; });
      // Show projects section
      projectsSection.style.display = "block";
    });
  
    // When clicking "CV"
    navCv.addEventListener('click', function(e) {
      e.preventDefault();
      // Show education, work, skills, interests
      edu.style.display = "block";
      work.style.display = "block";
      skillsProg.style.display = "block";
      interests.forEach(function(item) { item.style.display = "block"; });
      // Hide projects section
      projectsSection.style.display = "none";
    });
  });
  
  
  const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  
  function scrambleText(target) {
    let iteration = 0;
    clearInterval(target.scrambleInterval);
    
    target.scrambleInterval = setInterval(() => {
      target.innerText = target.innerText
        .split("")
        .map((letter, index) => {
          if (index < iteration) {
            return target.dataset.value[index];
          }
          return letters[Math.floor(Math.random() * 26)];
        })
        .join("");
        
      if (iteration >= target.dataset.value.length) { 
        clearInterval(target.scrambleInterval);
      }
      
      iteration += 1 / 3;
    }, 30);
  }
  
  document.addEventListener("DOMContentLoaded", () => {
    const projectsTitle = document.querySelector(".projects-title");
    
    // Run the scramble effect on page load
    scrambleText(projectsTitle);
    
    // When the "Projects" nav tab is clicked, re-run the effect
    const navProjects = document.getElementById("nav-projects");
    navProjects.addEventListener("click", () => {
      scrambleText(projectsTitle);
    });
    
    // Optionally, also re-run the effect on hover
    projectsTitle.addEventListener("mouseover", event => {
      scrambleText(event.target);
    });
  });
  