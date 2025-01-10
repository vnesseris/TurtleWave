import { LightningElement, wire, track } from 'lwc';
import uId from '@salesforce/user/Id';
import getUserExpedition from '@salesforce/apex/ExpeditionInformationController.getUserActiveExpedition';
import uploadFile from '@salesforce/apex/ExpeditionInformationController.uploadFile';
import completeExpedition from '@salesforce/apex/ExpeditionInformationController.completeExpedition';
import { NavigationMixin } from 'lightning/navigation';
import updateStatus from '@salesforce/apex/expeditionInformationController.updateStatusCompleted';
import updateActionFindings from '@salesforce/apex/expeditionInformationController.updateActionFindings';
import validateCompletion from '@salesforce/apex/expeditionInformationController.validateCompletion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExpeditionInformation extends LightningElement {

    uId = uId;
    @track expedition;
    @track expeditionStatus;
    recordId;
    fileData;
    apiName;
    @track expeditionCompleted = false;
    @track expeditionActions;

    @wire(getUserExpedition, {uId: '$uId'})
    getUserExpedition({data, error}){
        if(data){
            this.expedition = data;
            this.recordId = data.expeditionId;
            this.expeditionCompleted = data.expeditionStatus === 'Completed';
            this.expeditionActions = data.expeditionActions;
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
            this.fileData = null;
            let title = `${filename} uploaded successfully!!`;
            this.toast(title, 'success');
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

    toast(title, variant){
        const toastEvent = new ShowToastEvent({
            title, 
            variant
        })
        this.dispatchEvent(toastEvent)
    }

    uploadNote() {
        // Navigate to the New Note page
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__objectPage',
        //     attributes: {
        //         objectApiName: 'ContentNote',
        //         actionName: 'new'
        //     }
        // });

        // this[NavigationMixin.Navigate]({
        //     type: 'standard__quickAction',
        //     attributes: {
        //         apiName: 'Global.NewNote'
        //     },
        //     state: {
        //         objectApiName: 'Expedition__c',
        //         context: 'RECORD_DETAIL',
        //         recordId: this.recordId,
        //         backgroundContext: '/lightning/r/Expedition__c/' + this.recordId + '/view'
        //     }
        // })

        // this[NavigationMixin.Navigate]({
            
        //         type: "standard__quickAction",
        //         attributes: {
        //             apiName: 'Global.NewNote'
        //         },
        //         state: {
        //             objectApiName: 'Expedition__c',
        //             recordId: this.recordId
        //         }
            
        // })
    }

    completeExpedition(){
        this.markExpeditionCompleted();        
    }

    async markExpeditionCompleted(){
        try{
            let completionValidity = await validateCompletion({
                expeditionId: this.recordId
            });

            if(!completionValidity){
                this.toast('Expedition cannot be completed. There are actions pending', 'info');
            } else{
                completeExpedition({'recordId': this.recordId})
                .then((result) => {
                    this.toast('Expedition completed successfully', 'success');
                    this.expeditionCompleted = true;
                    this.expedition = null;
                })
                .catch((error) => {
                    this.toast(error, 'error');
                });
            }
        } catch(error){

        }
    }

    updateTaskStatus(event){
        const actionId = event.target.dataset.id;
        const btn = this.template.querySelector(`[data-id="${actionId}"]`);

        if(event.target.checked){
            updateStatus({'actionId': actionId, 'obj': 'Expedition_Action__c', 'fieldToUpdate': 'Action_Completed__c', 'value':true})
            .then((result) =>{
                this.toast('Expedition task completed', 'success');
                this.expeditionActions = this.expeditionActions.filter((elm) => elm.Id != actionId);
            })
            .catch((error) => {
                btn.checked = false;
                this.toast(error, 'error');
            });
        }
    }

    updateActionFindings(event){
        const actionId = event.target.dataset.id;
        const findingsInput = this.template.querySelector(`[data-id="${actionId}"][title="InputFindings"]`);

        if(findingsInput.value){
            updateActionFindings({'actionId': actionId, 'value': findingsInput.value})
            .then((result) => {
                findingsInput.value = '';
            })
        }
    }
}