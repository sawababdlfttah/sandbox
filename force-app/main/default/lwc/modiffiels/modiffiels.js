// First, import the custom labels
import { LightningElement, track, api, wire } from 'lwc';
import createJobApplication from '@salesforce/apex/JobApplicationController.createJobApplication';
import setLink from '@salesforce/apex/JobApplicationController.setLink';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import JOB_LABEL from '@salesforce/label/c.job';
import DESC_JOB_LABEL from '@salesforce/label/c.desc_job';

export default class Modiffiels extends LightningElement {
    @track lastName = '';
    @track firstName = '';
    @track email = '';
    @track phone = '';
    @track coverLetter = '';
    @track fileId;
    @track fileURL;
    @track jobOfferId;

    labels = {
        jobTitle: JOB_LABEL,
        jobDescription: DESC_JOB_LABEL
    };

    get cardTitle() {
        return `Postulez pour un emploi : ${this.labels.jobTitle}`;
    }

    handleInputChange(event) {
        const fieldName = event.target.name;
        this[fieldName] = event.target.value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
/*
    handleFileUpload(event) {
        const uploadedFiles = event.detail.files;
        if (!uploadedFiles || uploadedFiles.length === 0) {
            return;
        }

        this.fileId = uploadedFiles[0].documentId;
        const customUrl = 'https://emsi-2d-dev-ed.develop.lightning.force.com/lightning/r/ContentDocument';
        this.fileURL = `${customUrl}/${this.fileId}/view`;

        this.showToast('Succès', 'Fichier téléchargé avec succès. Veuillez soumettre votre candidature.', 'success');
    }
*/
    async submitApplication() {
      /*
        if (!this.fileId) {
            this.showToast('Erreur', 'Veuillez télécharger votre CV avant de soumettre la candidature', 'error');
            return;
        }
*/
        try {
            const result = await createJobApplication({
                lastName: this.lastName,
                firstName: this.firstName,
                email: this.email,
                phone: this.phone,
                coverLetter: this.coverLetter,
                jobOfferId: this.jobOfferId
            });

            this.recordId = result.Id;
/*
            await setLink({
                recordId: this.recordId,
                fileURL: this.fileURL,
                contentDocumentId: this.fileId
            });
            */

            this.showToast('Succès', 'Candidature soumise avec succès!', 'success');

            this.lastName = '';
            this.firstName = '';
            this.email = '';
            this.phone = '';
            this.coverLetter = '';
          //  this.fileId = null;
           // this.fileURL = null;
        } catch (error) {
            console.error('Erreur lors de la soumission de la candidature:', error);
            const message = error.body ? error.body.message : 'Erreur inconnue. Veuillez réessayer.';
            this.showToast('Erreur', message, 'error');
        }
    }
}