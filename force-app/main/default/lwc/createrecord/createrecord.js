import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import WEBSITE_FIELD from "@salesforce/schema/Account.Website";


export default class AccountCreator extends NavigationMixin(LightningElement) {
  accountObject = ACCOUNT_OBJECT;
  nameField = NAME_FIELD;
  websiteField = WEBSITE_FIELD;

  handleAccountCreated(event) {
    // récuperer recordid just created 
    const recordId = event.detail.id;

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Account created successfully",
        variant: "success"
      })
    );
    // Navigation un fois record created naviger vers page details de record
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: 'Account',
            actionName: 'view'
        }
    });
  }

}