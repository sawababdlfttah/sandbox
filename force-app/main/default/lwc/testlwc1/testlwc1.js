import { LightningElement, api, wire} from 'lwc';
import getSobject from '@salesforce/apex/OpportunityController.getSobject';

export default class Testlwc1 extends LightningElement {

    @api recordId;

    @wire(getSobject, { idOpp: '$recordId' })
    
 testdata({error, data}) {
        console.log('avant if -->si entre la méhode ou non ?  ');
         // console.log('Data:', data);
  //  console.log('Error:', error);
    if (error) {
        console.error('Error retrieving data:', error);
    } else if (data) {
        console.log('Data retrieved successfully:', data);
        this.tasks = data;
       console.log('Tasks:', this.tasks);
    }
        console.log('test testdata');
    }




   


}