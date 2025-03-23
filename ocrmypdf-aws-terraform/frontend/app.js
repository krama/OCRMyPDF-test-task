document.addEventListener('DOMContentLoaded', function() {
 const form = document.getElementById('upload-form');
 const statusContainer = document.getElementById('status-container');
 const apiEndpoint = 'CHANGE_ME'; // Change this value to API_GATEWAY_ENDPOINT 
 
 // Initialization filelist
 let filesList = {};
 
 // Load file statuses
 function loadFileStatuses() {
     fetch('status/status.json')
         .then(response => response.json())
         .then(data => {
             filesList = data.files || {};
             updateStatusDisplay();
             
             // Update statuses every 5 seconds
             setTimeout(loadFileStatuses, 5000);
         })
         .catch(error => {
             console.error('Error loading statuses:', error);
             // Retry after 10 seconds
             setTimeout(loadFileStatuses, 10000);
         });
 }
 
 // Update status display
 function updateStatusDisplay() {
     if (Object.keys(filesList).length === 0) {
         statusContainer.innerHTML = '<p class="no-files">No files uploaded yet</p>';
         return;
     }
     
     let html = '<ul class="files-list">';
     
     // Sort files by updated_at in descending order
     const sortedFiles = Object.entries(filesList)
         .sort((a, b) => (b[1].updated_at || 0) - (a[1].updated_at || 0));
     
     for (const [fileId, fileData] of sortedFiles) {
         const status = fileData.status;
         const timestamp = fileData.updated_at ? 
             new Date(fileData.updated_at * 1000).toLocaleString() : 'Unknown';
         
         html += `<li class="file-item status-${status}">
             <div class="file-info">
                 <span class="file-id">${fileId}</span>
                 <span class="file-status">${status.toUpperCase()}</span>
                 <span class="file-time">${timestamp}</span>
             </div>`;
         
         if (status === 'completed' && fileData.output_url) {
             html += `<a href="${fileData.output_url}" class="download-btn" target="_blank">Download Processed PDF</a>`;
         }
         
         html += `</li>`;
     }
     
     html += '</ul>';
     statusContainer.innerHTML = html;
 }
 
 // Processing sent form
 form.addEventListener('submit', function(e) {
     e.preventDefault();
     
     const fileInput = document.getElementById('pdf-file');
     const deskew = document.getElementById('deskew').checked;
     const language = "eng";
     const submitBtn = document.getElementById('submit-btn');
     
     // Check if a file is existing
     if (!fileInput.files[0]) {
         alert('Please select a PDF file');
         return;
     }
     
     // Checking file type
     if (fileInput.files[0].type !== 'application/pdf') {
         alert('Please select a valid PDF file');
         return;
     }
     
     // Creating FormData for file upload
     const formData = new FormData();
     formData.append('file', fileInput.files[0]);
     formData.append('deskew', deskew);
     formData.append('language', language);
     
     // Blocking the button during upload
     submitBtn.disabled = true;
     submitBtn.textContent = 'Uploading...';
     
     // Sending the file
     fetch(apiEndpoint, {
         method: 'POST',
         body: formData
     })
     .then(response => response.json())
     .then(data => {
         // Adding new file to the list
         if (data.file_id) {
             filesList[data.file_id] = {
                 status: 'queued',
                 updated_at: Math.floor(Date.now() / 1000)
             };
             updateStatusDisplay();
         }
         
         // Reset the form
         form.reset();
         submitBtn.disabled = false;
         submitBtn.textContent = 'Upload and Process';
         
         alert('PDF uploaded successfully and queued for processing');
     })
     .catch(error => {
         console.error('Error uploading file:', error);
         submitBtn.disabled = false;
         submitBtn.textContent = 'Upload and Process';
         alert('Error uploading file. Please try again.');
     });
 });
 
 // Loading file statuses
 loadFileStatuses();
});