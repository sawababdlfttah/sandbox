import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunitiesByRecordType from '@salesforce/apex/OpportunityController.getOpportunitiesByRecordType';
import getOpportunityRecordTypes from '@salesforce/apex/OpportunityController.getOpportunityRecordTypes';
import getOpportunityNameSuggestions from '@salesforce/apex/OpportunityController.getOpportunityNameSuggestions';

export default class OpportunityList extends LightningElement {
    @track opportunities;
    @track filteredOpportunities;
    @track error;
    columns = [
        { label: 'Opportunity Name', fieldName: 'Name', type: 'text' },
        { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date' },
        { label: 'Amount', fieldName: 'Amount', type: 'currency' }
    ];

    @track searchName = '';
    @track selectedRecordType = '';
    @track selectedDate;
    @track recordTypeOptions = [{ label: 'All Record Types', value: '' }];
    @track nameSuggestions = [];
    @track showNameSuggestions = false;
    @track debugInfo = '';

    @wire(getOpportunityRecordTypes)
    wiredRecordTypes({ error, data }) {
        if (data) {
            this.recordTypeOptions = [
                ...this.recordTypeOptions,
                ...data.map(rt => ({ label: rt.Name, value: rt.Name }))
            ];
            console.log('Record Types loaded:', this.recordTypeOptions);
            this.debugInfo += `Record Types loaded: ${this.recordTypeOptions.length}\n`;
        } else if (error) {
            console.error('Error fetching record types', error);
            this.debugInfo += `Error fetching record types: ${error}\n`;
        }
    }

    @wire(getOpportunitiesByRecordType, { 
        recordTypeName: '$selectedRecordType',
        selectedDate: '$selectedDate'
    })
    wiredOpportunities({ error, data }) {
        if (data) {
            this.opportunities = data.map(opp => ({
                ...opp,
                RecordTypeName: opp.RecordType.Name
            }));
            console.log('Opportunities loaded:', this.opportunities.length);
            console.log('Opportunities data:', JSON.stringify(this.opportunities));
            this.debugInfo += `Opportunities loaded: ${this.opportunities.length}\n`;
            this.filterOpportunities();
            this.error = undefined;
            if (this.opportunities.length === 0) {
                this.showToast('No Records', 'No opportunities found for the selected criteria.', 'warning');
            }
        } else if (error) {
            this.error = error;
            this.opportunities = undefined;
            this.filteredOpportunities = undefined;
            console.error('Error fetching opportunities', error);
            this.debugInfo += `Error fetching opportunities: ${error}\n`;
        }
    }

    handleRecordTypeChange(event) {
        this.selectedRecordType = event.detail.value;
        this.searchName = '';
        this.nameSuggestions = [];
        this.showNameSuggestions = false;
        console.log('Record Type changed to:', this.selectedRecordType);
        this.debugInfo += `Record Type changed to: ${this.selectedRecordType}\n`;
    }

    handleDateChange(event) {
        const selectedDate = new Date(event.target.value);
        this.selectedDate = selectedDate.toISOString().split('T')[0];
        console.log('Date changed to:', this.selectedDate);
        this.debugInfo += `Date changed to: ${this.selectedDate}\n`;
    }

    async handleNameSearch(event) {
        this.searchName = event.target.value;
        console.log('Name search changed to:', this.searchName);
        this.debugInfo += `Name search changed to: ${this.searchName}\n`;
        if (this.searchName.length > 1) {
            try {
                this.nameSuggestions = await getOpportunityNameSuggestions({ 
                    searchTerm: this.searchName, 
                    recordTypeName: this.selectedRecordType 
                });
                this.showNameSuggestions = this.nameSuggestions.length > 0;
                console.log('Name suggestions fetched:', this.nameSuggestions.length);
                this.debugInfo += `Name suggestions fetched: ${this.nameSuggestions.length}\n`;
            } catch (error) {
                console.error('Error fetching name suggestions', error);
                this.nameSuggestions = [];
                this.showNameSuggestions = false;
                this.debugInfo += `Error fetching name suggestions: ${error}\n`;
            }
        } else {
            this.nameSuggestions = [];
            this.showNameSuggestions = false;
        }
    }

    handleNameSelection(event) {
        this.searchName = event.currentTarget.dataset.value;
        this.showNameSuggestions = false;
        console.log('Name selected:', this.searchName);
        this.debugInfo += `Name selected: ${this.searchName}\n`;
    }

    handleSearch() {
        if (!this.selectedDate || !this.selectedRecordType) {
            this.showToast('Missing Selection', 'Please select both Record Type and Date to perform the search.', 'error');
        } else {
            this.filterOpportunities();
            console.log('Search button clicked');
            this.debugInfo += `Search button clicked\n`;
        }
    }

    filterOpportunities() {
        if (this.opportunities) {
            this.filteredOpportunities = this.opportunities.filter(opp => 
                opp.Name.toLowerCase().includes(this.searchName.toLowerCase())
            );
            console.log('Opportunities filtered:', this.filteredOpportunities.length);
            this.debugInfo += `Opportunities filtered: ${this.filteredOpportunities.length}\n`;
        } else {
            this.filteredOpportunities = [];
            console.log('No opportunities to filter');
            this.debugInfo += `No opportunities to filter\n`;
        }

        if (this.filteredOpportunities.length === 0) {
            this.showToast('No Records', 'No opportunities found for the selected criteria.', 'warning');
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    get totalOpportunities() {
        return this.filteredOpportunities ? this.filteredOpportunities.length : 0;
    }

    get totalAmount() {
        return this.filteredOpportunities ? 
            this.filteredOpportunities.reduce((sum, opp) => sum + (opp.Amount || 0), 0) : 0;
    }
}