import { LightningElement } from 'lwc';
export default class BinfHtml extends LightningElement {
    // myvalue=" saleforce bolt";
    ///// handleonchange (event){
    //    this.myvalue= event.target.value;
    ///}
    firstname = '';
    lastname = '';

    handleonchangefi(event) {
        const field = event.target.name;
        if (field === 'firstname') {
            this.firstname = event.target.value;
        } else if (field === 'lastname') {
            this.lastname = event.target.value;
        }
        console.log('Firstname:', this.firstname);
        console.log('Lastname:', this.lastname);
    }

    get uppercaseName() {
        return `${this.firstname} ${this.lastname}`.toUpperCase();
    }
    showme = false;
    handlechckbox(event) {
        this.showme = event.target.checked;

    }
}