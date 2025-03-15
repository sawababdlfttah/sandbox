import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectsList from '@salesforce/apex/RecordManagerController.getObjectsList';
import getRecords from '@salesforce/apex/RecordManagerController.getRecords';
import deleteRecords from '@salesforce/apex/RecordManagerController.deleteRecords';

export default class RecordManager extends LightningElement {
    @track allObjectOptions = [];
    @track filteredObjectOptions = [];
    @track selectedObject;
    @track records = [];
    @track columns = [];
    @track selectedRecords = [];
    @track isLoading = false;
    @track noRecordsMessage = '';
    @track searchTerm = '';
    @track showObjectResults = false;
    @track recordSearchTerm = '';
    @track filteredRecords = [];



    connectedCallback() {
        this.loadObjects();
    }

    loadObjects() {
        this.isLoading = true;
        getObjectsList()
            .then(result => {
                this.allObjectOptions = result.map(function(obj) {
                    return { 
                        label: obj.label, 
                        value: obj.apiName,
                        // Stocke les termes de recherche en minuscules pour faciliter le filtrage
                        searchTerms: (obj.label + ' ' + obj.apiName).toLowerCase()
                    };
                });
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }

    handleSearchKeyUp(event) {
        const searchKey = event.target.value.toLowerCase();
        this.searchTerm = searchKey;
        
        // Si le champ de recherche est vide, ne pas afficher les résultats
        if (!searchKey) {
            this.filteredObjectOptions = [];
            this.showObjectResults = false;
            this.selectedObject = null; // Reset selected object
            this.records = []; // Clear records when search bar is empty
            this.columns = []; // Clear columns as well
            this.noRecordsMessage = '';
            return;
        }
        
        // Filtrer les objets qui correspondent au terme de recherche
        this.filteredObjectOptions = this.allObjectOptions
            .filter(option => option.searchTerms.includes(searchKey))
            .slice(0, 10); // Limiter à 10 résultats pour éviter une liste trop longue
        
        this.showObjectResults = this.filteredObjectOptions.length > 0;
    }

    handleObjectSelection(event) {
        const selectedValue = event.currentTarget.dataset.value;
        const selectedLabel = event.currentTarget.dataset.label;
        
        this.selectedObject = selectedValue;
        this.searchTerm = selectedLabel;
        this.showObjectResults = false;
        
        this.loadRecords();
    }

    handleSearchBlur() {
        // Utiliser setTimeout pour permettre le clic sur un élément avant de masquer les résultats
        setTimeout(() => {
            this.showObjectResults = false;
        }, 300);
    }

    handleSearchFocus() {
        // Réafficher les résultats si le terme de recherche n'est pas vide
        if (this.searchTerm && this.filteredObjectOptions.length > 0) {
            this.showObjectResults = true;
        }
    }

    loadRecords() {
        if (!this.selectedObject) return;
        
        this.isLoading = true;
        this.records = [];
        this.selectedRecords = [];
        this.noRecordsMessage = '';
        this.filteredRecords = []; // Initialize this as well

        getRecords({ objectApiName: this.selectedObject })
            .then(result => {
                console.log('Records retrieved:', JSON.stringify(result));
                
                if (result.records && result.records.length > 0) {
                    this.records = result.records;
                    this.columns = result.columns;
                    this.filteredRecords = result.records; // Set initial filtered records

                    if (this.columns.length === 0) {
                        this.noRecordsMessage = 'No accessible fields found for this object.';
                    }
                } else {
                    this.records = [];
                    this.columns = [];
                    this.noRecordsMessage = 'No records found for this object.';
                    this.filteredRecords = [];

                    this.showToast('Info', 'No records found for this object', 'info');
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }

    handleRowSelection(event) {
        console.log('Row selection event:', JSON.stringify(event.detail));
        this.selectedRecords = event.detail.selectedRows || [];
        console.log('Selected records:', this.selectedRecords.length);
    }

    handleDelete() {
        if (this.selectedRecords.length === 0) {
            this.showToast('Warning', 'Please select at least one record to delete', 'warning');
            return;
        }

        if (!confirm('Are you sure you want to delete ' + this.selectedRecords.length + ' record(s)?')) {
            return;
        }

        const recordIds = this.selectedRecords.map(function(record) {
            return record.Id;
        });
        
        console.log('Records to delete:', JSON.stringify(recordIds));
        this.isLoading = true;

        deleteRecords({ objectName: this.selectedObject, recordIds: recordIds })
            .then(() => {
                this.showToast('Success', this.selectedRecords.length + ' record(s) deleted successfully', 'success');
                this.loadRecords();
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }
    handleRecordSearch(event) {
      this.recordSearchTerm = event.target.value.toLowerCase();
  
      if (!this.recordSearchTerm) {
        this.filteredRecords = [...this.records]; // Reset to full list
          return;
      }
      this.filteredRecords = this.records.filter(record => {
        // Check all field values that are strings
        return Object.entries(record).some(([key, value]) => {
            // Skip Id and non-string values
            if (key === 'Id' || typeof value !== 'string') return false;
            return value.toLowerCase().includes(this.recordSearchTerm);
        });
      });
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

    handleError(error) {
        console.error('Error in component:', error);
        let errorMessage = 'Unknown error';
        if (error.body && error.body.message) {
            errorMessage = error.body.message;
        } else if (typeof error === 'string') {
            errorMessage = error;
        }
        this.showToast('Error', errorMessage, 'error');
    }

    get isDeleteDisabled() {
        return !this.selectedRecords || this.selectedRecords.length === 0;
    }
    
    get hasRecords() {
        return this.records && this.records.length > 0 && this.columns && this.columns.length > 0;
    }
}