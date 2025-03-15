import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountRecordTypes from '@salesforce/apex/AccountContactController.getAccountRecordTypes';
import getAccountsByRecordType from '@salesforce/apex/AccountContactController.getAccountsByRecordType';
import getContactsByAccount from '@salesforce/apex/AccountContactController.getContactsByAccount';
import updateContactPhone from '@salesforce/apex/AccountContactController.updateContactPhone';

console.log('Importing component dependencies');

const CONTACT_COLUMNS = [
    { label: 'First Name', fieldName: 'FirstName', type: 'text' },
    { label: 'Last Name', fieldName: 'LastName', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true }
];

console.log('Contact columns configuration:', CONTACT_COLUMNS);

export default class AccountContactSelector extends LightningElement {
    @track recordTypeOptions = [];
    @track accountOptions = [];
    @track allContacts = [];
    @track displayedContacts = [];
    selectedRecordTypeId = '';
    selectedAccountId = '';
    columns = CONTACT_COLUMNS;
    draftValues = [];
    error;

    // Pagination variables
    pageNumber = 1;
    pageSize = 5;
    totalPages = 0;

    @track wiredRecordTypesResult;
    @track wiredAccountsResult;
    @track wiredContactsResult;
    @track showUpdateButton = false;

    constructor() {
        super();
        console.log('AccountContactSelector component initialized');
    }

    get showContactsTable() {
        console.log('Checking showContactsTable:', { selectedRecordTypeId: this.selectedRecordTypeId, selectedAccountId: this.selectedAccountId });
        return this.selectedRecordTypeId && this.selectedAccountId;
    }

    @wire(getAccountRecordTypes)
    wiredRecordTypes(result) {
        console.log('Wire getAccountRecordTypes called:', result);
        this.wiredRecordTypesResult = result;
        const { error, data } = result;
        if (data) {
            console.log('Record types loaded:', data);
            this.recordTypeOptions = data.map(rt => ({ label: rt.name, value: rt.id }));
            console.log('Processed record type options:', this.recordTypeOptions);
        } else if (error) {
            console.error('Error loading record types:', error);
            this.error = 'Error loading record types: ' + error.body.message;
        }
    }

    @wire(getAccountsByRecordType, { recordTypeId: '$selectedRecordTypeId' })
    wiredAccounts(result) {
        console.log('Wire getAccountsByRecordType called:', { recordTypeId: this.selectedRecordTypeId, result });
        this.wiredAccountsResult = result;
        const { error, data } = result;
        
        if (data) {
            console.log('Accounts loaded:', data);
            this.accountOptions = data.map(acc => ({ label: acc.Name, value: acc.Id }));
            console.log('Processed account options:', this.accountOptions);
            this.error = undefined;
        } else if (error) {
            console.error('Error loading accounts:', error);
            this.error = 'Error loading accounts: ' + error.body.message;
            this.accountOptions = [];
        }
    }

    @wire(getContactsByAccount, { accountId: '$selectedAccountId' })
    wiredContacts(result) {
        console.log('Wire getContactsByAccount called:', { accountId: this.selectedAccountId, result });
        this.wiredContactsResult = result;
        const { error, data } = result;
        if (data) {
            console.log('Contacts loaded:', data);
            this.allContacts = data;
            this.totalPages = Math.ceil(this.allContacts.length / this.pageSize);
            this.pageNumber = 1;
            console.log('Pagination calculated:', { totalPages: this.totalPages, pageNumber: this.pageNumber });
            this.updateDisplayedContacts();
            this.error = undefined;
        } else if (error) {
            console.error('Error loading contacts:', error);
            this.error = 'Error loading contacts: ' + error.body.message;
            this.allContacts = [];
            this.displayedContacts = [];
        }
        return refreshApex(this.wiredContactsResult);
    }

    handleRecordTypeChange(event) {
        console.log('Record type changed:', event.detail.value);
        this.selectedRecordTypeId = event.detail.value;
        this.selectedAccountId = '';
        this.allContacts = [];
        this.displayedContacts = [];
        console.log('State after record type change:', {
            selectedRecordTypeId: this.selectedRecordTypeId,
            selectedAccountId: this.selectedAccountId,
            contactsLength: this.allContacts.length
        });
    }

    handleAccountChange(event) {
        console.log('Account changed:', event.detail.value);
        this.selectedAccountId = event.detail.value;
        return refreshApex(this.wiredContactsResult);
    }

    updateDisplayedContacts() {
        console.log('Updating displayed contacts');
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = this.pageNumber * this.pageSize;
        console.log('Slice parameters:', { start, end, totalContacts: this.allContacts.length });
        this.displayedContacts = this.allContacts.slice(start, end);
        console.log('Updated displayed contacts:', this.displayedContacts);
        return refreshApex(this.wiredContactsResult);
    }

    handlePrevious() {
        console.log('Previous page clicked');
        if (this.pageNumber > 1) {
            this.pageNumber--;
            console.log('New page number:', this.pageNumber);
            this.updateDisplayedContacts();
        }
    }

    handleNext() {
        console.log('Next page clicked');
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            console.log('New page number:', this.pageNumber);
            this.updateDisplayedContacts();
        }
    }

    get disablePrevious() {
        const disabled = this.pageNumber <= 1;
        console.log('Previous button disabled:', disabled);
        return disabled;
    }

    get disableNext() {
        const disabled = this.pageNumber >= this.totalPages;
        console.log('Next button disabled:', disabled);
        return disabled;
    }

    get showPagination() {
        const show = this.selectedAccountId && this.displayedContacts.length > 0;
        console.log('Show pagination:', show);
        return show;
    }

    handleSave(event) {
        console.log('Save event triggered');
        const draftValues = event.detail.draftValues;
        console.log('Draft values:', draftValues);
        this.draftValues = draftValues;
        this.showUpdateButton = true;
    }

    handleUpdate() {
        console.log('Update button clicked');
        const updates = this.draftValues.map(draft => {
            return { Id: draft.Id, Phone: draft.Phone };
        });
        console.log('Contact updates to be sent:', updates);

        updateContactPhone({ contactUpdates: updates })
            .then(() => {
                console.log('Contacts updated successfully');
                this.draftValues = [];
                this.showUpdateButton = false;
                return refreshApex(this.wiredContactsResult);
            })
            .catch(error => {
                console.error('Error updating contacts:', error);
                this.error = 'Error updating contacts: ' + error.body.message;
            });
    }
}