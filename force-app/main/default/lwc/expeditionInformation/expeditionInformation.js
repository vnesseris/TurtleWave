import { LightningElement, wire, track } from 'lwc';
import uId from '@salesforce/user/Id';
import getUserExpedition from '@salesforce/apex/ExpeditionInformationController.getUserActiveExpedition';
import uploadFile from '@salesforce/apex/ExpeditionInformationController.uploadFile';
import completeExpedition from '@salesforce/apex/ExpeditionInformationController.completeExpedition';
import { NavigationMixin } from 'lightning/navigation';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    {label: 'Title', fieldName: 'Title__c', editable: false},
    {label: 'Description', fieldName: 'Description__c', editable: false},
    {label: 'Findings Input', fieldName: 'Findings_Input__c', editable:true, type: 'text'},
    {label: 'Update', type: 'button', typeAttributes: {
        variant: 'neutral',
        label: 'Update',
        name: 'update_action'
    }}
]

export default class ExpeditionInformation extends LightningElement {

    uId = uId;
    @track expedition;
    @track expeditionStatus;
    columns = columns;
    recordId;
    fileData;
    apiName;
    
    get pagereference() {
        return {
            "type": "standard__quickAction",
            "attributes": {
                "apiName": 'Global.NewNote'
            },
            "state": {
                "objectApiName": 'Expedition__c',
                "context": "RECORD_DETAIL",
                "recordId": this.recordId,
                "actionName":'Global.NewNote',
                "backgroundContext": "/lightning/r/Expedition__c/" + this.recordId + "/view"
            }
        }
    }


    @wire(getUserExpedition, {uId: '$uId'})
    getUserExpedition({data, error}){
        if(data){
            this.expedition = data;
            this.recordId = data.expeditionId;
            this.expeditionStatus = data.expeditionStatus;
        } else if(error){
            console.log(JSON.stringify(error));
        }
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        var reader = new FileReader();

        this.uploadFileAsync(file, reader);
    }

    async uploadFileAsync(file, reader){
        const res = await this.loadFile(file, reader);

        const {base64, filename, recordId} = this.fileData;
        uploadFile({ base64, filename, recordId }).then(result=>{
            this.fileData = null
            let title = `${filename} uploaded successfully!!`
            this.toast(title)
        })
    }

    async loadFile(file, reader){
        return new Promise ((resolve) => {
        reader.onload = () => {

            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.recordId
            }
            resolve();
        }

        reader.readAsDataURL(file);        
       } 
    );
    }

    toast(title){
        const toastEvent = new ShowToastEvent({
            title, 
            variant:"success"
        })
        this.dispatchEvent(toastEvent)
    }

    uploadNote() {
        console.log('vas should be at least here');
        this.apiName = 'Global.NewNote';
        console.log('vas in here ' + JSON.stringify(this.pagereference));
        this[NavigationMixin.Navigate](this.pagereference, true);
    }

    completeExpedition(){
        if(this.expeditionStatus === 'Completed'){
            this.toast('Expedition already completed');
            return;
        }

        completeExpedition({'recordId': this.recordId})
        .then((result) => {
            this.toast('Expedition completed successfully')
        })
        .catch((error) => {
            this.toast(error);
        });
    }
}