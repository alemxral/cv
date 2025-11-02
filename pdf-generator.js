// PDF Generator for CV - EXACTLY TWO PAGES
// Page 1: CV section (entire resume)
// Page 2: Projects section
// Forces content to fit into 2 pages by calculating exact dimensions

async function generateResumePDF() {
  console.log('Starting PDF generation - forcing exactly 2 pages...');
  
  // Hide particles temporarily
  const particlesBg = document.getElementById('particles-background');
  const particlesFg = document.getElementById('particles-foreground');
  const navbar = document.querySelector('.navbar');
  
  const originalStyles = {
    particlesBg: particlesBg ? particlesBg.style.display : null,
    particlesFg: particlesFg ? particlesFg.style.display : null,
    navbar: navbar ? navbar.style.display : null,
    bodyBg: document.body.style.background
  };

  try {
    // Hide particles and navbar
    if (particlesBg) particlesBg.style.display = 'none';
    if (particlesFg) particlesFg.style.display = 'none';
    if (navbar) navbar.style.display = 'none';
    document.body.style.background = '#ffffff';

    // Get the main resume element (CV content - includes both .base and .func)
    const resumeElement = document.querySelector('.resume');
    const projectsElement = document.querySelector('.projects');
    
    if (!resumeElement) {
      alert('Could not find CV content');
      return;
    }

    // Create two separate containers - one per page
    const page1Container = document.createElement('div');
    page1Container.id = 'pdf-page-1';
    page1Container.style.background = '#e6e6e6';
    page1Container.style.padding = '20px';
    page1Container.style.boxSizing = 'border-box';
    
    // Clone the ENTIRE resume (includes both .base sidebar and .func content)
    const clonedResume = resumeElement.cloneNode(true);
    clonedResume.style.margin = '20px auto';
    clonedResume.style.boxShadow = '10px 10px #747D8C';
    clonedResume.style.display = 'flex'; // Ensure flex layout is preserved
    
    // Fix images in CV
    const imgs = clonedResume.querySelectorAll('img');
    imgs.forEach(img => {
      img.style.maxWidth = '100%';
      img.style.height = 'auto';
    });
    
    page1Container.appendChild(clonedResume);

    // Add page 1 to DOM temporarily to measure
    page1Container.style.position = 'fixed';
    page1Container.style.top = '0';
    page1Container.style.left = '0';
    page1Container.style.zIndex = '99999';
    page1Container.style.visibility = 'hidden';
    document.body.appendChild(page1Container);
    
    await new Promise(resolve => setTimeout(resolve, 200));
    
    const page1Width = page1Container.offsetWidth;
    const page1Height = page1Container.offsetHeight;
    console.log(`Page 1 dimensions: ${page1Width}px × ${page1Height}px`);
    
    page1Container.style.visibility = 'visible';

    // Generate PDF for page 1
    console.log('Generating page 1 (CV)...');
    const opt1 = {
      margin: 0,
      filename: 'temp_page1.pdf',
      image: { type: 'jpeg', quality: 0.95 },
      html2canvas: { 
        scale: 2,
        useCORS: true,
        logging: false,
        backgroundColor: '#e6e6e6',
        width: page1Width,
        height: page1Height,
        windowWidth: page1Width
      },
      jsPDF: { 
        unit: 'px',
        format: [page1Width, page1Height],
        orientation: page1Width > page1Height ? 'landscape' : 'portrait',
        compress: true
      }
    };

    const pdf1 = await html2pdf().set(opt1).from(page1Container).outputPdf('blob');
    document.body.removeChild(page1Container);
    console.log('Page 1 generated');

    // Now handle page 2 (projects)
    let pdf2 = null;
    if (projectsElement) {
      const page2Container = document.createElement('div');
      page2Container.id = 'pdf-page-2';
      page2Container.style.background = '#ffffff';
      page2Container.style.padding = '40px 20px';
      page2Container.style.boxSizing = 'border-box';
      page2Container.style.minWidth = page1Width + 'px'; // Match page 1 width
      
      const clonedProjects = projectsElement.cloneNode(true);
      clonedProjects.style.display = 'block';
      
      // Fix project images
      const projectImgs = clonedProjects.querySelectorAll('img');
      projectImgs.forEach(img => {
        img.style.maxWidth = '100%';
        img.style.height = 'auto';
      });
      
      page2Container.appendChild(clonedProjects);

      // Add to DOM to measure
      page2Container.style.position = 'fixed';
      page2Container.style.top = '0';
      page2Container.style.left = '0';
      page2Container.style.zIndex = '99999';
      page2Container.style.visibility = 'hidden';
      document.body.appendChild(page2Container);
      
      await new Promise(resolve => setTimeout(resolve, 200));
      
      const page2Width = page2Container.offsetWidth;
      const page2Height = page2Container.offsetHeight;
      console.log(`Page 2 dimensions: ${page2Width}px × ${page2Height}px`);
      
      page2Container.style.visibility = 'visible';

      // Generate PDF for page 2
      console.log('Generating page 2 (Projects)...');
      const opt2 = {
        margin: 0,
        filename: 'temp_page2.pdf',
        image: { type: 'jpeg', quality: 0.95 },
        html2canvas: { 
          scale: 2,
          useCORS: true,
          logging: false,
          backgroundColor: '#ffffff',
          width: page2Width,
          height: page2Height,
          windowWidth: page2Width
        },
        jsPDF: { 
          unit: 'px',
          format: [page2Width, page2Height],
          orientation: page2Width > page2Height ? 'landscape' : 'portrait',
          compress: true
        }
      };

      pdf2 = await html2pdf().set(opt2).from(page2Container).outputPdf('blob');
      document.body.removeChild(page2Container);
      console.log('Page 2 generated');
    }

    // Merge the two PDFs using pdf-lib
    console.log('Merging into final 2-page PDF...');
    
    // Load pdf-lib from CDN if not already loaded
    if (typeof PDFLib === 'undefined') {
      await loadScript('https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1/dist/pdf-lib.min.js');
    }
    
    const { PDFDocument } = PDFLib;
    
    // Create new PDF and add both pages
    const mergedPdf = await PDFDocument.create();
    
    // Add page 1
    const pdf1Doc = await PDFDocument.load(await pdf1.arrayBuffer());
    const [page1] = await mergedPdf.copyPages(pdf1Doc, [0]);
    mergedPdf.addPage(page1);
    
    // Add page 2 if exists
    if (pdf2) {
      const pdf2Doc = await PDFDocument.load(await pdf2.arrayBuffer());
      const [page2] = await mergedPdf.copyPages(pdf2Doc, [0]);
      mergedPdf.addPage(page2);
    }
    
    // Save final PDF
    const mergedPdfBytes = await mergedPdf.save();
    const blob = new Blob([mergedPdfBytes], { type: 'application/pdf' });
    const url = URL.createObjectURL(blob);
    
    // Download
    const a = document.createElement('a');
    a.href = url;
    a.download = 'Alejandro_Moral_Aranda_CV.pdf';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    console.log('PDF saved successfully - exactly 2 pages!');

  } catch (error) {
    console.error('Error generating PDF:', error);
    alert('Error generating PDF: ' + error.message);
  } finally {
    // Restore original styles
    if (particlesBg) particlesBg.style.display = originalStyles.particlesBg || '';
    if (particlesFg) particlesFg.style.display = originalStyles.particlesFg || '';
    if (navbar) navbar.style.display = originalStyles.navbar || '';
    document.body.style.background = originalStyles.bodyBg || '';
  }
}

// Helper to load external scripts
function loadScript(src) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = src;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
}

// Wire up the download button when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  const downloadBtn = document.querySelector('.download-btn');
  if (downloadBtn) {
    // Remove the download attribute so it doesn't try to download the PDF file
    downloadBtn.removeAttribute('download');
    downloadBtn.removeAttribute('href');
    
    downloadBtn.addEventListener('click', function(e) {
      e.preventDefault();
      console.log('Download button clicked');
      generateResumePDF();
    });
    
    console.log('PDF generator initialized');
  } else {
    console.warn('Download button not found');
  }
});
