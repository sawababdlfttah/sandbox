import { LightningElement, api } from 'lwc';
import setLink from '@salesforce/apex/JoindreProduitConroller.setLink';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JoindreProduit extends LightningElement {
    @api recordId;
    
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        const fileId = uploadedFiles[0].documentId;

        const customUrl = 'https://sawab-dev-ed.develop.lightning.force.com/lightning/r/ContentDocument'; // Adjust based on your org's custom label
        const fileURL = `${customUrl}/${fileId}/view`;
        
        setLink({ recordId: this.recordId, fileURL: fileURL })
            .then(result => {
                const toastEvent = new ShowToastEvent({
                    title: '',
                    message: 'Votre fichier a bien été sauvegardé.',
                    variant: 'success'
                });
                this.dispatchEvent(toastEvent);

                this.closeQuickAction();
            })
            .catch(error => {
                const toastEvent = new ShowToastEvent({
                    title: '',
                    message: 'Votre fichier n\'a pas pu être sauvegardé. Veuillez réessayer.',
                    variant: 'error'
                });
                this.dispatchEvent(toastEvent);
            });
    }

    closeQuickAction() {
        const closeQuickActionEvent = new CustomEvent('close');
        this.dispatchEvent(closeQuickActionEvent);
    }
}